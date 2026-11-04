#!/bin/bash
# Install the device tree and kernel into ~/los and generate the vendor tree.
set -e
A='/mnt/c/Users/David/Voyo i8/LineageOS'
L=$HOME/los
D=$L/device/voyo/x970_t10_97inc
mkdir -p "$D"
rsync -a --delete --exclude prebuilt --exclude manifest.xml --exclude rootdir/init.mt6797.rc --exclude rootdir/ueventd.mt6797.rc \
  "$A/device/voyo/x970_t10_97inc/" "$D/"
find "$D" -type f \( -name '*.mk' -o -name '*.rc' -o -name '*.prop' -o -name '*.in' -o -name '*.py' -o -name 'fstab*' \) -exec sed -i 's/\r$//' {} +
mkdir -p "$D/prebuilt"
cat ~/los-kernel/gemini8/kernel-3.18/out/arch/arm64/boot/Image.gz "$A/analysis/dtb0.dtb" > "$D/prebuilt/Image.gz-dtb"
python3 "$D/tools/gen_vendor.py" "$HOME/stockfs" "$L"
du -sh "$L/vendor/voyo/x970_t10_97inc"
