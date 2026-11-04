cd ~/los-kernel/tb3/drivers/input/touchscreen/mediatek/GSL3670
sed -n '492,560p;622,650p' gsl_ts_driver.c | iconv -f gbk -t utf8 -c | grep -vE '^\s*(//|$)' | cut -c1-70
cd ~/los-kernel/m95/drivers/input/touchscreen/mediatek
sed -n 553,580p mtk_tpd.c
grep -n 'tpd_gpio_output\|^void tpd_gpio' mtk_tpd.c | head -6
sed -n '/^static int tpd_irq_registration/,/^}/p' GT911/gt9xx_driver.c | head -40
grep -n 'tpd_load_status\|tpd_get_dts_info\|i2c_add_driver\|\.of_match_table\|of_match\|TPD_DEVICE\|tpd_driver_add\|late_initcall\|module_init\|local_init' GT911/gt9xx_driver.c | head -16
grep -n 'TPD_RES_X\|TPD_RES_Y\|tpd_resolution' mtk_tpd.c | head
