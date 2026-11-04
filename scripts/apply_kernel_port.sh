#!/bin/bash
# Apply the Voyo i8 port onto the Meizu MX6 kernel. Safe to rerun.
set -e
A='/mnt/c/Users/David/Voyo i8/LineageOS'
cd ~/los-kernel/m95
git rev-parse --verify voyo-i8 >/dev/null 2>&1 || git checkout -q -b voyo-i8

L=drivers/misc/mediatek/lcm/sharp_wqxganl_dsi_vdo_boe_97inc
mkdir -p $L
tr -d '\r' < "$A/kernel-port/lcm/sharp_wqxganl_dsi_vdo_boe_97inc.c" > $L/sharp_wqxganl_dsi_vdo_boe_97inc.c
echo 'obj-y += sharp_wqxganl_dsi_vdo_boe_97inc.o' > $L/Makefile

python3 - <<'PY'
p = 'drivers/misc/mediatek/lcm/mt65xx_lcm_list.c'
s = open(p, errors='surrogateescape').read()
if 'sharp_wqxganl' not in s:
    drv = '#if defined(SHARP_WQXGANL_DSI_VDO_BOE_97INC)\n\t&sharp_wqxganl_dsi_vdo_boe_97inc_lcm_drv,\n#endif\n'
    name = '#if defined(SHARP_WQXGANL_DSI_VDO_BOE_97INC)\n\t"sharp_wqxganl_dsi_vdo_boe_97inc",\n#endif\n'
    tag = '#if defined(FT8716_FHD_VDO_SHARP)\n'
    i = s.index(tag)
    s = s[:i] + drv + s[i:]
    j = s.index(tag, i + len(drv) + len(tag))
    s = s[:j] + name + s[j:]
    open(p, 'w', errors='surrogateescape').write(s)
PY
H=drivers/misc/mediatek/lcm/mt65xx_lcm_list.h
grep -q sharp_wqxganl $H || sed -i '/ft8716_fhd_vdo_sharp_lcm_drv/a extern LCM_DRIVER sharp_wqxganl_dsi_vdo_boe_97inc_lcm_drv;' $H

T=drivers/input/touchscreen/mediatek
mkdir -p $T/gsl3680
tr -d '\r' < "$A/kernel-port/touch/gsl3680_driver.c" > $T/gsl3680/gsl3680_driver.c
tr -d '\r' < "$A/kernel-port/touch/gsl3680_fw.h" > $T/gsl3680/gsl3680_fw.h
cat > $T/gsl3680/Makefile <<'M'
ccflags-y += -I$(srctree)/drivers/input/touchscreen/mediatek
ccflags-y += -I$(srctree)/drivers/misc/mediatek/include/mt-plat
obj-y += gsl3680_driver.o
M
grep -q GSL3680 $T/Makefile || sed -i '/TOUCHSCREEN_MTK_GT911/a obj-$(CONFIG_TOUCHSCREEN_MTK_GSL3680)	+=  gsl3680/' $T/Makefile
grep -q GSL3680 $T/Kconfig || sed -i '0,/^config TOUCHSCREEN_MTK_GT1151$/s//config TOUCHSCREEN_MTK_GSL3680\n\tbool "Silead GSL3680 for the VOYO i8"\n\tdepends on TOUCHSCREEN_MTK\n\thelp\n\t  Silead GSL3680 capacitive touch controller.\n\nconfig TOUCHSCREEN_MTK_GT1151/' $T/Kconfig

sed -i 's/^obj-$(CONFIG_MMC_MTK) += meizu_tlcrpmb.o/obj-$(CONFIG_TRUSTONIC_TEE_SUPPORT) += meizu_tlcrpmb.o/' drivers/mmc/host/mediatek/Makefile

for f in drivers/misc/mediatek/mu3d/drv/musb_gadget.c drivers/misc/mediatek/mu3d/drv/mt_usb.c; do
  grep -q 'mt_boot_common.h' $f || sed -i '1i #include <linux/types.h>\n#include <mt-plat/mt_boot_common.h>' $f
  grep -q '<linux/types.h>' $f || sed -i '1i #include <linux/types.h>' $f
done

B=drivers/misc/mediatek/power/mt6797
tr -d '' < "$A/kernel-port/test/voyo_battery_stubs.c" > $B/voyo_battery_stubs.c
grep -q voyo_battery_stubs $B/Makefile || echo 'obj-y += voyo_battery_stubs.o' >> $B/Makefile

# Bring-up: early log the stock kernel can read back. No serial port here.
tr -d '' < "$A/kernel-port/test/early_log.py" | python3 -

D=arch/arm64/configs/x970_t10_97inc_defconfig
cp arch/arm64/configs/m95_defconfig $D
off() { for o in "$@"; do sed -i "/^CONFIG_$o=/d" $D; echo "# CONFIG_$o is not set" >> $D; done; }
set_() { sed -i "/^CONFIG_${1%%=*}=/d;/^# CONFIG_${1%%=*} is not set/d" $D; echo "CONFIG_$1" >> $D; }
off MTK_BQ25896_SUPPORT MTK_KERNEL_POWER_OFF_CHARGING MTK_SMART_BATTERY TRUSTONIC_TEE_SUPPORT MZ_SMART_BATTERY BQ27532_BATTERY MTK_BQ2589X_SUPPORT SND_SOC_TFA98XX \
    USB_C_SWITCH_FUSB301A FINGERPRINT_GOODIX_TEE TOUCHSCREEN_FTS INPUT_ALSPS_APDS9922 \
    ST_LSM6DS3_IIO MTK_LCM_PHYSICAL_ROTATION_HW BUILD_ARM64_APPENDED_DTB_IMAGE
sed -i '/^CONFIG_TRUSTONIC_TEE_VERSION/d;/^CONFIG_BUILD_ARM64_APPENDED_DTB_IMAGE_NAMES/d;/^CONFIG_ST_LSM6DS3_IIO_LIMIT_FIFO/d' $D
set_ 'ARCH_MTK_PROJECT="x970_t10_97inc"'
set_ 'CUSTOM_KERNEL_LCM="sharp_wqxganl_dsi_vdo_boe_97inc"'
set_ 'MTK_LCM_PHYSICAL_ROTATION="0"'
set_ 'TOUCHSCREEN_MTK_GSL3680=y'
set_ 'RD_XZ=y'
# LK decompresses to a fixed window, so keep the Image near stock size.
off DEBUG_KMEMLEAK PROVE_LOCKING LOCKDEP DEBUG_LOCK_ALLOC DEBUG_SPINLOCK DEBUG_MUTEXES DEBUG_ATOMIC_SLEEP DEBUG_INFO LOCK_STAT
git add -A
git -c user.name=voyo-port -c user.email=port@localhost commit -q -m "Port to the VOYO i8 (x970_t10_97inc)" || true
git log --oneline -2
