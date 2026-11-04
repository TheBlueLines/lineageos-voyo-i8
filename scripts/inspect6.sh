cd ~/los-kernel/m95
grep -n 'meizu_tlcrpmb\|tlcrpmb' drivers/mmc/host/mediatek/Makefile drivers/mmc/host/mediatek/*/Makefile 2>/dev/null | head
grep -n 'obj-' drivers/power/mediatek/Makefile | head -20
grep -nE '^CONFIG_.*(RPMB|MEIZU|MZ_)' arch/arm64/configs/x970_t10_97inc_defconfig | head -20
