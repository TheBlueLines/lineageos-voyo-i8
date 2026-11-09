cd ~/los-kernel/tb3/drivers/input/touchscreen/mediatek/GSL3670
grep -nE '^(static )?(void|int|u32|s32).*\(.*\)' gsl_ts_driver.c | iconv -f gbk -t utf8 -c | sed -n 1,48p | cut -c1-80
grep -n '0xe0\|0xbc\|0xe4\|0xfc\|0x80' gsl_ts_driver.c | iconv -f gbk -t utf8 -c | head -24 | cut -c1-80
cd ~/los-kernel; grep -n 'LCM_INTERFACE_' gemini8/kernel-3.18/drivers/misc/mediatek/lcm/inc/lcm_drv.h | head -8
grep -rn 'lcm_if\b' gemini8/kernel-3.18/drivers/misc/mediatek/lcm/ -h 2>/dev/null | sort | uniq -c | sort -rn | head -5
bash '/mnt/f/Voyo i8/LineageOS/scripts/disasm.sh' ffffffc0008c88a0 ffffffc0008c8ac8 | cut -f1,3- | sed 's/ffffffc000//g' | head -150
