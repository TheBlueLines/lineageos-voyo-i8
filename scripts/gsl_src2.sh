cd ~/los-kernel/tb3/drivers/input/touchscreen
ls -la gsl_point_id; file gsl_point_id; grep -n 'gsl_point_id' Makefile mediatek/Makefile mediatek/GSL3670/Makefile 2>/dev/null
~/los-kernel/gcc49/bin/aarch64-linux-android-nm gsl_point_id 2>&1 | grep -iE ' [TDBRU] ' | cut -c1-60 | head -24
~/los-kernel/gcc49/bin/aarch64-linux-android-size gsl_point_id 2>&1 | tail -2
~/los-kernel/gcc49/bin/aarch64-linux-android-objdump -h gsl_point_id 2>&1 | grep -E 'file format|\.text|\.data|\.bss|\.rodata' | cut -c1-60
for q in tpd_dts_data; do grep -rn "$q" ~/los-kernel/m95/drivers/input/touchscreen/mediatek/mtk_tpd.c | head -4; done
sed -n '/^void tpd_get_dts_info/,/^}/p' ~/los-kernel/m95/drivers/input/touchscreen/mediatek/mtk_tpd.c | head -60
sed -n '/^int tpd_get_gpio_info/,/^}/p' ~/los-kernel/m95/drivers/input/touchscreen/mediatek/mtk_tpd.c | head -70
grep -n 'of_match\|compatible' ~/los-kernel/m95/drivers/input/touchscreen/mediatek/mtk_tpd.c | head
