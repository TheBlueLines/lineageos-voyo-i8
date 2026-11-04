cd ~/los-kernel/tb3/drivers/input/touchscreen/mediatek/GSL3670
grep -nE '^[a-z].*\b(gsl_alg_id_main|gsl_DataInit|gsl_version_id|gsl_mask_tiaoping|gsl_ReportPressure|gsl_TouchNear|gsl_FunIICRead|gsl_GestureExtern|gsl_obtain_gesture)\b' *.c | head
ls -la; head -c 500 gsl_ReadArrayData.c | iconv -f gbk -t utf8 2>/dev/null | head -14
find ~/los-kernel/tb3 ~/los-kernel/m95 -name '*gsl*' -o -name '*GSL*' 2>/dev/null | grep -v '\.git' | head -20
git -C ~/los-kernel/tb3 log --oneline -1
grep -rn 'gsl_alg_id\|\.a$\|gsl.*\.o' Makefile ../Makefile 2>/dev/null | head
cd ~/los-kernel/m95/drivers/input/touchscreen/mediatek
sed -n '/struct tpd_driver_t/,/};/p' tpd.h; grep -n 'tpd_driver_add\|tpd_gpio_output\|tpd_gpio_as_int\|tpd_load_status\|get_tpd_info\|tpd_dts_data\|extern' tpd.h | head -30; wc -l GT911/*.c; ls GT911; grep -n 'tpd_gpio\|irq_of_parse\|of_find\|request_irq\|tpd->dev\|regulator' GT911/gt9xx_driver.c | head -24
