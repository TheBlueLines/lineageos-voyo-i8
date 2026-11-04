cd ~/los-kernel/tb3/drivers/input/touchscreen/mediatek/GSL3670
for f in clr_reg reset_chip startup_chip test_i2c init_chip check_mem_data; do sed -n "/^static .*\b$f(.*/,/^}/p" gsl_ts_driver.c | iconv -f gbk -t utf8 -c | grep -v '^\s*//' | head -48; done | cut -c1-90
cd ~/los-kernel
find gemini8 -path '*lcm/inc/lcm_drv.h' | head -2
G=$(find gemini8 -path '*lcm/inc/lcm_drv.h' | head -1); [ -n "$G" ] && { L=$(grep -n 'unsigned int PLL_CLOCK;' "$G" | tail -1 | cut -d: -f1); sed -n "$((L-1)),$((L+12))p" "$G"; grep -n 'data_format\|word_count' "$G" | head; }
sed -n 80,92p m95/drivers/misc/mediatek/lcm/inc/lcm_drv.h
sed -n '/LCM_DSI_MODE_CON/,+1p' m95/drivers/misc/mediatek/lcm/inc/lcm_drv.h | head -3
grep -n 'mt_set_gpio_mode\|mt_set_gpio\b\|GPIO_' m95/drivers/misc/mediatek/lcm/ft8716_fhd_vdo_sharp/*.c | head -8
grep -n 'vtouch\|regulator_get' m95/drivers/input/touchscreen/mediatek/*.c | head
