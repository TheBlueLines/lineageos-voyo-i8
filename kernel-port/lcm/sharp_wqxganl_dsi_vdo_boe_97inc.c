/*
 * VOYO i8 (x970_t10_97inc) 9.7" 1536x2048 dual-link DSI video panel.
 * The stock driver has no published source; this sequence and timing were
 * recovered from the stock kernel 3.18.60 image.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 */

#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/of.h>
#include <linux/pinctrl/consumer.h>
#include <linux/platform_device.h>
#include <linux/string.h>
#include <mt-plat/mt_gpio.h>

#include "lcm_drv.h"

#define FRAME_WIDTH	1536
#define FRAME_HEIGHT	2048
/* Stock drives this as a raw GPIO next to the panel power switch. */
#define GPIO_LCM_EN	65

#define REGFLAG_DELAY		0xfd
#define REGFLAG_END_OF_TABLE	0xfe

static LCM_UTIL_FUNCS lcm_util;

#define MDELAY(n)	(lcm_util.mdelay(n))
#define dsi_set_cmdq(pdata, queue_size, force_update) \
	lcm_util.dsi_set_cmdq(pdata, queue_size, force_update)
#define dsi_set_cmdq_V2(cmd, count, ppara, force_update) \
	lcm_util.dsi_set_cmdq_V2(cmd, count, ppara, force_update)

struct LCM_setting_table {
	unsigned int cmd;
	unsigned char count;
	unsigned char para_list[64];
};

static struct LCM_setting_table lcm_init_setting[] = {
	{ 0x11, 1, { 0x00 } },
	{ REGFLAG_DELAY, 120, { } },
	{ 0x29, 1, { 0x00 } },
	{ REGFLAG_DELAY, 20, { } },
	{ REGFLAG_END_OF_TABLE, 0, { } },
};

static struct pinctrl *lcm_pinctrl;
static struct pinctrl_state *lcm_power_high, *lcm_power_low;
static struct pinctrl_state *lcm_reset_high, *lcm_reset_low;

static void lcm_select(struct pinctrl_state *state)
{
	if (!IS_ERR_OR_NULL(lcm_pinctrl) && !IS_ERR_OR_NULL(state))
		pinctrl_select_state(lcm_pinctrl, state);
}

static void lcm_en_output(int level)
{
	mt_set_gpio_dir(GPIO_LCM_EN, GPIO_DIR_OUT);
	mt_set_gpio_mode(GPIO_LCM_EN, GPIO_MODE_00);
	mt_set_gpio_out(GPIO_LCM_EN, level);
}

static int lcm_pinctrl_probe(struct platform_device *pdev)
{
	lcm_pinctrl = devm_pinctrl_get(&pdev->dev);
	if (IS_ERR(lcm_pinctrl))
		return PTR_ERR(lcm_pinctrl);

	lcm_power_high = pinctrl_lookup_state(lcm_pinctrl, "state_lcm_power_output_high");
	lcm_power_low = pinctrl_lookup_state(lcm_pinctrl, "state_lcm_power_output_low");
	lcm_reset_high = pinctrl_lookup_state(lcm_pinctrl, "state_lcm_reset_output_high");
	lcm_reset_low = pinctrl_lookup_state(lcm_pinctrl, "state_lcm_reset_output_low");
	return 0;
}

static const struct of_device_id lcm_of_ids[] = {
	{ .compatible = "mediatek,lcm_pinctrl" },
	{ }
};

static struct platform_driver lcm_pinctrl_driver = {
	.probe = lcm_pinctrl_probe,
	.driver = {
		.name = "lcm_pinctrl",
		.owner = THIS_MODULE,
		.of_match_table = lcm_of_ids,
	},
};

static int __init lcm_pinctrl_init(void)
{
	return platform_driver_register(&lcm_pinctrl_driver);
}
postcore_initcall_sync(lcm_pinctrl_init);

static void push_table(struct LCM_setting_table *table)
{
	for (; table->cmd != REGFLAG_END_OF_TABLE; table++) {
		if (table->cmd == REGFLAG_DELAY)
			MDELAY(table->count);
		else
			dsi_set_cmdq_V2(table->cmd, table->count, table->para_list, 1);
	}
}

static void lcm_set_util_funcs(const LCM_UTIL_FUNCS *util)
{
	memcpy(&lcm_util, util, sizeof(LCM_UTIL_FUNCS));
}

static void lcm_get_params(LCM_PARAMS *params)
{
	memset(params, 0, sizeof(LCM_PARAMS));

	params->type = LCM_TYPE_DSI;
	params->lcm_if = LCM_INTERFACE_DSI_DUAL;
	params->lcm_cmd_if = LCM_INTERFACE_DSI_DUAL;
	params->width = FRAME_WIDTH;
	params->height = FRAME_HEIGHT;

	params->dsi.mode = SYNC_EVENT_VDO_MODE;
	params->dsi.LANE_NUM = LCM_FOUR_LANE;
	params->dsi.data_format.format = LCM_DSI_FORMAT_RGB888;
	params->dsi.PS = LCM_PACKED_PS_24BIT_RGB888;
	params->dsi.word_count = FRAME_WIDTH * 3;
	params->dsi.packet_size = 256;

	params->dsi.vertical_sync_active = 2;
	params->dsi.vertical_backporch = 12;
	params->dsi.vertical_frontporch = 14;
	params->dsi.vertical_active_line = FRAME_HEIGHT;

	params->dsi.horizontal_sync_active = 4;
	params->dsi.horizontal_backporch = 200;
	params->dsi.horizontal_frontporch = 200;
	params->dsi.horizontal_active_pixel = FRAME_WIDTH;

	params->dsi.PLL_CLOCK = 370;
	params->dsi.ssc_disable = 1;
	/*
	 * UFOE in left/right mode splits each line between the two DSI links.
	 * LK sets this at boot; without it the kernel resets UFOE to bypass on
	 * the first resume and only one half of the panel gets a picture.
	 * Stock stores 1 at LCM_PARAMS offsets 676, 692 and 704 (ssc_disable,
	 * ufoe_enable, ufoe_params.lr_mode_en); it leaves cont_clock at 0.
	 */
	params->dsi.ufoe_enable = 1;
	params->dsi.ufoe_params.lr_mode_en = 1;
}

static void lcm_init_power(void)
{
	lcm_en_output(1);
	lcm_select(lcm_power_high);
}

static void lcm_suspend_power(void)
{
	lcm_select(lcm_power_low);
	MDELAY(20);
}

static void lcm_resume_power(void)
{
	lcm_en_output(1);
	lcm_select(lcm_power_high);
	MDELAY(20);
}

static void lcm_init_lcm(void)
{
	lcm_en_output(1);
	lcm_select(lcm_reset_high);
	MDELAY(10);
	lcm_select(lcm_reset_low);
	MDELAY(25);
	lcm_select(lcm_reset_high);
	MDELAY(10);
	push_table(lcm_init_setting);
}

static void lcm_suspend(void)
{
	unsigned int data;

	lcm_en_output(0);

	data = 0x00280500;	/* display off */
	dsi_set_cmdq(&data, 1, 1);
	MDELAY(60);
	data = 0x00100500;	/* sleep in */
	dsi_set_cmdq(&data, 1, 1);
	MDELAY(210);
	lcm_select(lcm_reset_low);
}

static void lcm_resume(void)
{
	lcm_init_lcm();
	push_table(lcm_init_setting);
}

LCM_DRIVER sharp_wqxganl_dsi_vdo_boe_97inc_lcm_drv = {
	.name = "sharp_wqxganl_dsi_vdo_boe_97inc",
	.set_util_funcs = lcm_set_util_funcs,
	.get_params = lcm_get_params,
	.init = lcm_init_lcm,
	.suspend = lcm_suspend,
	.resume = lcm_resume,
	.init_power = lcm_init_power,
	.suspend_power = lcm_suspend_power,
	.resume_power = lcm_resume_power,
};
