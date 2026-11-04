#!/bin/bash
W=$HOME/los-kernel; cd "$W"
zcat "/mnt/c/Users/David/Voyo i8/LineageOS/device-info/config.gz" | grep -E '^(CONFIG_[A-Z0-9_]+=|# CONFIG)' > stock.cfg
echo "stock opts: $(grep -c '^CONFIG' stock.cfg)"
ls gemini8/arch/arm64/configs/ | grep -iE 'gemini|aeon|x970|6797|k97|E-?[0-9]' | head; ls m95/arch/arm64/configs | grep -iE 'm95|mx6|6797' 
G=$(ls gemini8/arch/arm64/configs/*defconfig | grep -iE 'gemini|aeon6797' | head -1); echo "gemini cfg: $G"
grep -E 'VERSION =|PATCHLEVEL =|SUBLEVEL =' m95/Makefile | head -3; grep -E '^SUBLEVEL' gemini8/Makefile
keys='MTK_GPU_VERSION|TRUSTONIC|MTK_IN_HOUSE_TEE|MICROTRUST|TRUSTY|MTK_TEE|TEE_|ATF_|MTK_ATF|ARM64_.*ERRATUM|MTK_MEM|MTK_SEC|MTK_ECCCI|MTK_MD[0-9]_|MTK_MD_|MTK_C2K|MTK_ENABLE_MD|MTK_CCCI|MTK_SPM|CMA|MTK_DCS|MTK_CCU|MTK_SCP|MTK_TINYSYS|CUSTOM_KERNEL_SENSORHUB|MTK_SENSOR_HUB|MTK_SMART_BATTERY|MTK_BQ|ARCH_MTK_PROJECT|MTK_FPSGO|ZRAM|PSTORE|MTK_RAM_CONSOLE|MTK_AEE|MTK_EMMC|MTK_ION|MTK_EXTMEM|USB_CONFIGFS|USB_G_ANDROID|BLK_DEV_DM|MTK_LCM_PHYSICAL|ION_MTK|MTK_SVP|MTK_TRUSTED'
for f in stock.cfg m95/arch/arm64/configs/m95_defconfig "$G"; do echo "=== $f"; grep -E "^CONFIG_($keys)[A-Z0-9_]*=" "$f" | sort > /tmp/k.$(basename "$f"); wc -l < /tmp/k.$(basename "$f"); done
echo "##### stock vs m95"; diff /tmp/k.stock.cfg /tmp/k.m95_defconfig | grep -E '^[<>]' | head -70
echo "##### stock vs gemini"; diff /tmp/k.stock.cfg "/tmp/k.$(basename "$G")" | grep -E '^[<>]' | head -50
echo "##### stock Android13 needed"; grep -E '^CONFIG_(BPF_SYSCALL|CGROUP_BPF|MEMCG|F2FS_FS|KEYS|EXT4_ENCRYPTION|OVERLAY_FS|TMPFS_XATTR|NETFILTER_XT_MATCH_BPF|PSI|USERFAULTFD|FS_ENCRYPTION|ANDROID_BINDERFS)=' m95/arch/arm64/configs/m95_defconfig
echo "##### m95 mali"; ls m95/drivers/misc/mediatek/gpu/gpu_mali 2>/dev/null; ls m95/drivers/misc/mediatek/gpu/gpu_mali/mali_midgard 2>/dev/null; ls gemini8/drivers/misc/mediatek/gpu/gpu_mali/mali_midgard 2>/dev/null; ls gemini8/drivers/misc/mediatek/gpu/ged 2>/dev/null|head -3
echo "##### touch"; ls m95/drivers/input/touchscreen/mediatek/ ; ls gemini8/drivers/input/touchscreen/mediatek | head -30; ls tb3/drivers/input/touchscreen/mediatek/GSL3670; grep -rIl 'TOUCHSCREEN_MTK_GSL' tb3/drivers/input/touchscreen/mediatek/Kconfig; 
echo "##### lcm"; ls m95/drivers/misc/mediatek/lcm | head -40; ls m95/drivers/misc/mediatek/lcm | wc -l
echo "##### power"; ls m95/drivers/misc/mediatek/power/mt6797 ; ls gemini8/drivers/misc/mediatek/power/mt6797 | head -30
echo "##### wlan in stock"; ls m95/drivers/misc/mediatek/connectivity/wlan 2>/dev/null
