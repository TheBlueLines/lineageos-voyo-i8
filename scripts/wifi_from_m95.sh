#!/bin/bash
# Take the built-in MT6797 connectivity stack (WMT/STP, BT char dev, gen3 Wi-Fi,
# GPS, ANT) from the Meizu MX6 kernel. The Gemini tree only ships the O-era
# "build-in adapter" and expects out-of-tree .ko modules that don't exist; the
# stock Voyo kernel has the stack built in, which is what the stock vendor's
# wmt_loader expects (/dev/wmtdetect, /dev/stpwmt, /dev/wmtWifi).
set -e
cd ~/los-kernel/gemini8/kernel-3.18
M=~/los-kernel/m95
C=drivers/misc/mediatek/connectivity
# keep the Gemini adapter around for reference, but don't build it
mkdir -p ../connadp-orig
cp -n $C/Makefile $C/common/*.[ch] ../connadp-orig/ 2>/dev/null || true
rm -rf $C/common $C/wlan $C/gps $C/ant
cp -r $M/$C/common $M/$C/wlan $M/$C/gps $M/$C/ant $C/
cp $M/$C/Makefile $C/Makefile
# Gemini's extra include paths (power/clkbuf/eccci headers moved in the O tree)
sed -i '/^ifneq (\$(KERNELRELEASE),)/a\
    subdir-ccflags-y += -I$(srctree)/drivers/misc/mediatek/base/power/include\
    subdir-ccflags-y += -I$(srctree)/drivers/misc/mediatek/base/power/include/clkbuf_v1\
    subdir-ccflags-y += -I$(srctree)/drivers/misc/mediatek/include/mt-plat/$(MTK_PLATFORM)/include\
    subdir-ccflags-y += -I$(srctree)/drivers/misc/mediatek/include/mt-plat\
    subdir-ccflags-y += -I$(srctree)/drivers/misc/mediatek/eccci/$(MTK_PLATFORM)\
    subdir-ccflags-y += -I$(srctree)/drivers/misc/mediatek/eccci/' $C/Makefile
cp $M/drivers/misc/mediatek/include/mt-plat/mtk_wcn_cmb_stub.h drivers/misc/mediatek/include/mt-plat/
# gen3 is written for -Wno-undef and without -Werror
sed -i '1i subdir-ccflags-y += -DARP_MONITER_ENABLE=0 -Wno-error' $C/wlan/Makefile
# m95's cfg80211 has the 4.2+ locally_generated argument; 3.18's doesn't
L=$C/wlan/gen3/os/linux
sed -i 'N;s/NULL, 0,\n\s*eStatus == WLAN_STATUS_MEDIA_DISCONNECT_LOCALLY, GFP_KERNEL/NULL, 0, GFP_KERNEL/;P;D' $L/gl_kal.c
sed -i 'N;s/u2RxIELen,\n\s*eStatus == WLAN_STATUS_MEDIA_DISCONNECT_LOCALLY, GFP_KERNEL/u2RxIELen, GFP_KERNEL/;P;D' $L/gl_p2p_kal.c
grep -n "LOCALLY, GFP_KERNEL" $L/gl_kal.c $L/gl_p2p_kal.c && { echo "cfg80211 patch failed"; exit 1; }
git status --short | head
# no FM driver in the Gemini tree (also out-of-tree in O); FM isn't needed
for f in arch/arm64/configs/x970_t10_97inc_defconfig "/mnt/c/Users/David/Voyo i8/LineageOS/kernel-port/x970_t10_97inc_defconfig"; do
  sed -i 's/^CONFIG_MTK_FMRADIO=y/# CONFIG_MTK_FMRADIO is not set/' "$f"
done
# the stock O vendor keeps WMT_SOC.cfg in /vendor/firmware (as the stock kernel expects)
sed -i 's|#define CUST_CFG_WMT_PREFIX "/vendor/etc/firmware/"|#define CUST_CFG_WMT_PREFIX "/vendor/firmware/"|' $C/common/conn_soc/core/include/wmt_conf.h
grep -q '"/vendor/firmware/"' $C/common/conn_soc/core/include/wmt_conf.h
# STP-PSM stays enabled (m95 default gPsEnable = 1). An earlier workaround set
# it to 0 because a "Wait for ACT" wakeup timeout was seen during bring-up, but
# with PSM off BTIF never leaves the ON state and refuses every system suspend,
# so the tablet never deep-sleeps. Kernel #21 (2026-11-04) runs with PSM on:
# Wi-Fi off/on, BT on/off and repeated suspend/resume all work.
grep -q '^static UINT32 gPsEnable = 1;' $C/common/conn_soc/core/wmt_lib.c
