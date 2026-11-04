/*
 * Silead GSL3680 touch controller on the VOYO i8, for the MediaTek tpd
 * framework. Follows the mainline silead driver: the raw coordinates are
 * reported as they are and tracking is left to the input stack, so the
 * closed gsl_alg_id library of the vendor driver is not needed.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 */

#include <linux/delay.h>
#include <linux/gpio.h>
#include <linux/i2c.h>
#include <linux/interrupt.h>
#include <linux/of_irq.h>
#include <linux/regulator/consumer.h>

#include "tpd.h"
#include "gsl3680_fw.h"

#define GSL_I2C_ADDR		0x40
#define GSL_REG_DATA		0x80
#define GSL_REG_STATUS		0xb0
#define GSL_REG_POWER		0xbc
#define GSL_REG_RESET		0xe0
#define GSL_REG_CLOCK		0xe4
#define GSL_REG_PAGE		0xf0
#define GSL_REG_ID		0xfc
#define GSL_CMD_RESET		0x88
#define GSL_CMD_START		0x00
#define GSL_CLOCK		0x04
#define GSL_STATUS_OK		0x5a5a5a5a

/*
 * Without the closed gsl_alg_id library the firmware reports raw sensor
 * coordinates, rotated against the portrait panel: raw X runs top to bottom
 * (0..~1650) and raw Y runs right to left (0..~900). Measured by tapping the
 * corners on the tablet.
 */
#define GSL_RAW_X_MAX		1650
#define GSL_RAW_Y_MAX		900
#define GSL_SCREEN_W		1536
#define GSL_SCREEN_H		2048

#define GSL_MAX_FINGERS		5
#define GSL_DATA_LEN		(4 + GSL_MAX_FINGERS * 4)
/* The MediaTek I2C FIFO holds 8 bytes without DMA. */
#define GSL_I2C_CHUNK		8
#define GSL_INIT_TRIES		3

static struct i2c_client *gsl_client;
static unsigned int gsl_irq;

static int gsl_read(u8 reg, u8 *buf, int len)
{
	struct i2c_msg msgs[2] = {
		{ .addr = gsl_client->addr, .len = 1 },
		{ .addr = gsl_client->addr, .flags = I2C_M_RD },
	};
	int ret, n;

	msgs[0].buf = &reg;
	while (len > 0) {
		n = min(len, GSL_I2C_CHUNK);
		msgs[1].buf = buf;
		msgs[1].len = n;
		ret = i2c_transfer(gsl_client->adapter, msgs, 2);
		if (ret != 2)
			return ret < 0 ? ret : -EIO;
		reg += n;
		buf += n;
		len -= n;
	}
	return 0;
}

static int gsl_write32(u8 reg, u32 val)
{
	u8 buf[5] = { reg, val, val >> 8, val >> 16, val >> 24 };
	int ret = i2c_master_send(gsl_client, buf, sizeof(buf));

	return ret == sizeof(buf) ? 0 : (ret < 0 ? ret : -EIO);
}

static u32 gsl_read32(u8 reg)
{
	u8 b[4] = { 0 };

	if (gsl_read(reg, b, sizeof(b)))
		return 0;
	return b[0] | b[1] << 8 | b[2] << 16 | (u32)b[3] << 24;
}

static void gsl_reset_pin(void)
{
	tpd_gpio_output(GTP_RST_PORT, 0);
	msleep(20);
	tpd_gpio_output(GTP_RST_PORT, 1);
	msleep(20);
}

/* Needed by some GSL9xx parts whose I/O runs at 1.8 V. */
static void gsl_io_control(void)
{
	int i;

	for (i = 0; i < 5; i++) {
		gsl_write32(GSL_REG_PAGE, 0x01fe0000);
		gsl_write32(0x78, 0x80000005);
		msleep(5);
	}
	msleep(50);
}

static void gsl_reset_core(bool io_control)
{
	gsl_write32(GSL_REG_RESET, GSL_CMD_RESET);
	msleep(20);
	gsl_write32(GSL_REG_CLOCK, GSL_CLOCK);
	msleep(5);
	gsl_write32(GSL_REG_POWER, 0);
	msleep(5);
	if (io_control)
		gsl_io_control();
}

static int gsl_load_fw(void)
{
	int i, ret;

	for (i = 0; i < ARRAY_SIZE(gsl3680_fw); i++) {
		ret = gsl_write32(gsl3680_fw[i].offset, gsl3680_fw[i].val);
		if (ret)
			return ret;
	}
	return 0;
}

static int gsl_chip_init(void)
{
	int try, ret;
	u32 status = 0;

	for (try = 0; try < GSL_INIT_TRIES; try++) {
		bool io_control = try > 0;

		gsl_reset_pin();
		gsl_write32(GSL_REG_RESET, GSL_CMD_RESET);
		msleep(20);
		gsl_write32(GSL_REG_DATA, 0x3);
		msleep(5);
		gsl_write32(GSL_REG_CLOCK, GSL_CLOCK);
		msleep(5);
		gsl_write32(GSL_REG_RESET, GSL_CMD_START);
		msleep(20);

		gsl_reset_core(io_control);
		ret = gsl_load_fw();
		if (ret)
			continue;
		gsl_write32(GSL_REG_RESET, GSL_CMD_START);
		msleep(20);
		gsl_reset_core(io_control);
		gsl_write32(GSL_REG_RESET, GSL_CMD_START);
		msleep(50);

		status = gsl_read32(GSL_REG_STATUS);
		if (status == GSL_STATUS_OK) {
			pr_info("gsl3680: firmware running (io_control=%d)\n", io_control);
			return 0;
		}
	}
	pr_err("gsl3680: firmware did not start, status %08x\n", status);
	return -ENODEV;
}

static irqreturn_t gsl_irq_thread(int irq, void *unused)
{
	u8 buf[GSL_DATA_LEN];
	int i, count;

	if (gsl_read(GSL_REG_DATA, buf, sizeof(buf)))
		return IRQ_HANDLED;

	count = min_t(int, buf[0], GSL_MAX_FINGERS);
	for (i = 0; i < count; i++) {
		u8 *p = buf + 4 + i * 4;
		int raw_y = (p[0] | p[1] << 8) & 0xfff;
		int raw_x = (p[2] | p[3] << 8) & 0xfff;
		int x, y;

		raw_x = min(raw_x, GSL_RAW_X_MAX);
		raw_y = min(raw_y, GSL_RAW_Y_MAX);
		x = (GSL_RAW_Y_MAX - raw_y) * (GSL_SCREEN_W - 1) / GSL_RAW_Y_MAX;
		y = raw_x * (GSL_SCREEN_H - 1) / GSL_RAW_X_MAX;

		input_report_key(tpd->dev, BTN_TOUCH, 1);
		input_report_abs(tpd->dev, ABS_MT_TOUCH_MAJOR, 1);
		input_report_abs(tpd->dev, ABS_MT_POSITION_X, x);
		input_report_abs(tpd->dev, ABS_MT_POSITION_Y, y);
		input_mt_sync(tpd->dev);
	}
	if (!count) {
		input_report_key(tpd->dev, BTN_TOUCH, 0);
		input_mt_sync(tpd->dev);
	}
	input_sync(tpd->dev);
	return IRQ_HANDLED;
}

static int gsl_setup_irq(void)
{
	struct device_node *node;
	u32 debounce[2] = { 0, 0 };

	node = of_find_compatible_node(NULL, NULL, "mediatek,mt6797-touch");
	if (!node)
		return -ENODEV;

	of_property_read_u32_array(node, "debounce", debounce, ARRAY_SIZE(debounce));
	gpio_set_debounce(debounce[0], debounce[1]);
	gsl_irq = irq_of_parse_and_map(node, 0);
	if (!gsl_irq)
		return -ENODEV;

	return request_threaded_irq(gsl_irq, NULL, gsl_irq_thread,
				    IRQF_TRIGGER_RISING | IRQF_ONESHOT, "gsl3680", NULL);
}

static int gsl_i2c_probe(struct i2c_client *client, const struct i2c_device_id *id)
{
	struct i2c_adapter *adapter;
	int ret;

	if (!IS_ERR_OR_NULL(tpd->reg)) {
		ret = regulator_enable(tpd->reg);
		if (ret)
			pr_err("gsl3680: regulator_enable failed: %d\n", ret);
	}
	msleep(100);
	tpd_gpio_output(GTP_RST_PORT, 1);
	msleep(100);
	tpd_gpio_as_int(GTP_INT_PORT);
	msleep(100);

	/* The device tree says 0x5d, the chip answers on 0x40. */
	client->addr = GSL_I2C_ADDR;
	gsl_client = client;
	gsl_reset_pin();
	pr_info("gsl3680: bus %d id %08x\n", client->adapter->nr, gsl_read32(GSL_REG_ID));
	if (gsl_read32(GSL_REG_ID) == 0) {
		adapter = i2c_get_adapter(0);
		if (adapter) {
			gsl_client = i2c_new_dummy(adapter, GSL_I2C_ADDR);
			i2c_put_adapter(adapter);
			pr_info("gsl3680: bus 0 id %08x\n", gsl_read32(GSL_REG_ID));
		}
	}

	ret = gsl_chip_init();
	if (ret)
		return ret;

	ret = gsl_setup_irq();
	if (ret)
		return ret;

	tpd_load_status = 1;
	return 0;
}

static int gsl_i2c_remove(struct i2c_client *client)
{
	return 0;
}

static const struct i2c_device_id gsl_ids[] = {
	{ "gsl3680", 0 },
	{ }
};

static const struct of_device_id gsl_of_ids[] = {
	{ .compatible = "mediatek,cap_touch" },
	{ }
};

static struct i2c_driver gsl_i2c_driver = {
	.probe = gsl_i2c_probe,
	.remove = gsl_i2c_remove,
	.id_table = gsl_ids,
	.driver = {
		.name = "gsl3680",
		.owner = THIS_MODULE,
		.of_match_table = gsl_of_ids,
	},
};

static int gsl_local_init(void)
{
	tpd->reg = regulator_get(tpd->tpd_dev, "vtouch");
	if (!IS_ERR(tpd->reg))
		regulator_set_voltage(tpd->reg, 2800000, 2800000);

	if (i2c_add_driver(&gsl_i2c_driver))
		return -1;
	if (tpd_load_status != 1) {
		i2c_del_driver(&gsl_i2c_driver);
		return -1;
	}
	tpd_type_cap = 1;
	return 0;
}

static void gsl_suspend(struct device *h)
{
	disable_irq(gsl_irq);
	tpd_gpio_output(GTP_RST_PORT, 0);
}

static void gsl_resume(struct device *h)
{
	gsl_reset_pin();
	gsl_write32(GSL_REG_RESET, GSL_CMD_RESET);
	msleep(20);
	gsl_write32(GSL_REG_RESET, GSL_CMD_START);
	msleep(50);
	if (gsl_read32(GSL_REG_STATUS) != GSL_STATUS_OK)
		gsl_chip_init();
	enable_irq(gsl_irq);
}

static struct tpd_driver_t gsl_tpd_driver = {
	.tpd_device_name = "gsl3680",
	.tpd_local_init = gsl_local_init,
	.suspend = gsl_suspend,
	.resume = gsl_resume,
};

static int __init gsl_driver_init(void)
{
	tpd_get_dts_info();
	return tpd_driver_add(&gsl_tpd_driver);
}

static void __exit gsl_driver_exit(void)
{
	tpd_driver_remove(&gsl_tpd_driver);
}

module_init(gsl_driver_init);
module_exit(gsl_driver_exit);
