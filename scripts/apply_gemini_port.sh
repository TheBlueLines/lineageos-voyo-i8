#!/bin/bash
# Apply the Voyo i8 drivers and the stock kernel config to the Android 8 era
# MT6797X kernel of the Gemini PDA. Safe to rerun.
set -e
A='/mnt/f/Voyo i8/LineageOS'
cd ~/los-kernel/gemini8/kernel-3.18
git rev-parse --verify voyo-i8 >/dev/null 2>&1 || git checkout -q -b voyo-i8

L=drivers/misc/mediatek/lcm/sharp_wqxganl_dsi_vdo_boe_97inc
mkdir -p $L
tr -d '\r' < "$A/kernel-port/lcm/sharp_wqxganl_dsi_vdo_boe_97inc.c" > $L/sharp_wqxganl_dsi_vdo_boe_97inc.c
echo 'obj-y += sharp_wqxganl_dsi_vdo_boe_97inc.o' > $L/Makefile

python3 - <<'PY'
import re
p = 'drivers/misc/mediatek/lcm/mt65xx_lcm_list.c'
s = open(p, errors='surrogateescape').read()
if 'sharp_wqxganl' not in s:
    m = re.search(r'LCM_DRIVER \*lcm_driver_list\[\] = \{\n', s)
    assert m, 'driver list not found'
    drv = '#if defined(SHARP_WQXGANL_DSI_VDO_BOE_97INC)\n\t&sharp_wqxganl_dsi_vdo_boe_97inc_lcm_drv,\n#endif\n'
    s = s[:m.end()] + drv + s[m.end():]
    m = re.search(r'unsigned char lcm_name_list\[\]\[128\] = \{\n', s)
    if m:
        name = '#if defined(SHARP_WQXGANL_DSI_VDO_BOE_97INC)\n\t"sharp_wqxganl_dsi_vdo_boe_97inc",\n#endif\n'
        s = s[:m.end()] + name + s[m.end():]
    open(p, 'w', errors='surrogateescape').write(s)
p = 'drivers/misc/mediatek/lcm/mt65xx_lcm_list.h'
s = open(p, errors='surrogateescape').read()
if 'sharp_wqxganl' not in s:
    m = re.search(r'extern LCM_DRIVER [a-z0-9_]+;\n', s)
    assert m, 'declaration not found'
    s = s[:m.start()] + 'extern LCM_DRIVER sharp_wqxganl_dsi_vdo_boe_97inc_lcm_drv;\n' + s[m.start():]
    open(p, 'w', errors='surrogateescape').write(s)
PY

T=drivers/input/touchscreen/mediatek
mkdir -p $T/gsl3680
tr -d '\r' < "$A/kernel-port/touch/gsl3680_driver.c" > $T/gsl3680/gsl3680_driver.c
tr -d '\r' < "$A/kernel-port/touch/gsl3680_fw.h" > $T/gsl3680/gsl3680_fw.h
cat > $T/gsl3680/Makefile <<'M'
ccflags-y += -I$(srctree)/drivers/input/touchscreen/mediatek
ccflags-y += -I$(srctree)/drivers/misc/mediatek/include/mt-plat
obj-y += gsl3680_driver.o
M
grep -q GSL3680 $T/Makefile || echo 'obj-$(CONFIG_TOUCHSCREEN_MTK_GSL3680)	+=  gsl3680/' >> $T/Makefile
grep -q GSL3680 $T/Kconfig || sed -i '0,/^config TOUCHSCREEN_MTK_NT36xxx$/s//config TOUCHSCREEN_MTK_GSL3680\n\tbool "Silead GSL3680 for the VOYO i8"\n\tdepends on TOUCHSCREEN_MTK\n\thelp\n\t  Silead GSL3680 capacitive touch controller.\n\nconfig TOUCHSCREEN_MTK_GT1151/' $T/Kconfig

B=drivers/misc/mediatek/power/mt6797/bq25890.c
sed -i 's/^int chargin_hw_init_done_rt = 1;/kal_bool chargin_hw_init_done_rt = KAL_TRUE;/' $B
grep -q 'chargin_hw_init_done_rt = ' $B || echo 'kal_bool chargin_hw_init_done_rt = KAL_TRUE;' >> $B

D=arch/arm64/configs/x970_t10_97inc_defconfig
mkdir -p arch/arm64/configs
zcat "$A/device-info/config.gz" > $D
set_() { sed -i "/^CONFIG_${1%%=*}=/d;/^# CONFIG_${1%%=*} is not set/d" $D; echo "CONFIG_$1" >> $D; }
set_ 'TOUCHSCREEN_MTK_GSL3680=y'
set_ 'RD_XZ=y'
set_ 'MTK_PUMP_EXPRESS_PLUS_SUPPORT=y'
# Boot test: only the sensors this tree has source for.
S=""
for s in imx214_mipi_raw s5k3l8_mipi_raw; do [ -f drivers/misc/mediatek/imgsensor/src/mt6797/$s/Makefile ] && S="$S $s"; done
set_ "CUSTOM_KERNEL_IMGSENSOR=\"${S# }\""
sed -i '/^CONFIG_MTK_NFC=/d' $D; echo '# CONFIG_MTK_NFC is not set' >> $D
git add -A
git -c user.name=voyo-port -c user.email=port@localhost commit -q -m "Port to the VOYO i8 (x970_t10_97inc)" || true
git log --oneline -1
