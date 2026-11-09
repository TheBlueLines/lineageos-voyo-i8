#!/bin/bash
# Package the port kernel with the TWRP ramdisk for a boot test in `recovery`.
set -euo pipefail
A='/mnt/f/Voyo i8/LineageOS'
K=${KERNEL:-$HOME/los-kernel/gemini8/kernel-3.18/out/arch/arm64/boot/Image.gz}
P=~/twrp/out/target/product/x970_t10_97inc
MKBOOTIMG=~/twrp/out/host/linux-x86/bin/mkbootimg
W=$(mktemp -d)
trap 'rm -rf "$W"' EXIT

# LK merges the odmdtbo overlay onto this base tree, as it does for stock.
cat "$K" "$A/analysis/dtb0.dtb" > "$W/kernel"
zcat "$P/ramdisk-recovery.img" | xz -9e --check=crc32 --lzma2=dict=1MiB > "$W/ramdisk.xz"

OUT="$A/out/test-recovery.img"
mkdir -p "$A/out"
"$MKBOOTIMG" --kernel "$W/kernel" --ramdisk "$W/ramdisk.xz" \
  --cmdline "bootopt=64S3,32N2,64N2 buildvariant=eng androidboot.selinux=permissive" \
  --base 0x40078000 --pagesize 2048 --kernel_offset 0x00008000 --ramdisk_offset 0x04f88000 \
  --second_offset 0x00e88000 --tags_offset 0x03f88000 \
  --os_version 16.1.0 --os_patch_level 2099-12-31 --output "$OUT"

SIZE=$(stat -c %s "$OUT")
echo "kernel $(stat -c %s "$W/kernel")  ramdisk $(stat -c %s "$W/ramdisk.xz")  image $SIZE  free $((16777216 - SIZE))"
[ "$SIZE" -le 16777216 ] || { echo "ERROR: image is larger than the recovery partition"; exit 1; }
sha256sum "$OUT"
