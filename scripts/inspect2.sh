cd ~/los-kernel/m95
cat drivers/misc/mediatek/power/mt6797/Makefile | grep -nE 'obj|ifeq|endif|else' | head -30
grep -rn 'MTK_BQ25896_SUPPORT\|MTK_BQ2589X_SUPPORT\|MTK_BQ25890\|MTK_BQ24261' --include=Kconfig --include=Makefile --include=*.h --include=*.c drivers include 2>/dev/null | cut -c1-110 | head -16
echo ---; grep -nE '^CONFIG_(.*MEIZU.*|MZ_.*|.*MX6.*|.*GOODIX.*|.*FTS.*|.*FP.*|.*BQ.*|.*FUSB.*|.*HALL.*|.*TFA.*|.*AK.*|.*APDS.*|.*CM36.*|.*LSM6.*|.*MTK_IRTX.*|.*ST_.*|MTK_VIBRATOR|.*MEM_PROTECT.*|CUSTOM_KERNEL_[A-Z]*|MTK_SENSOR.*|TOUCHSCREEN.*|BUILD_ARM64.*)=' arch/arm64/configs/m95_defconfig | cut -c1-90
echo ---; sed -n 55,90p arch/arm64/Makefile
