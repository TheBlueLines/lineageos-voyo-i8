#!/bin/bash
# Stock boot image with the log-collecting init rule. Stock kernel, stock ramdisk otherwise.
set -euo pipefail
A='/mnt/f/Voyo i8/LineageOS'
T='/mnt/f/Voyo i8/TWRP'
W=$(mktemp -d); trap 'rm -rf "$W"' EXIT
python3 -I "$A/scripts/patch_boot_diag.py" "$T/stock-unpacked/boot/ramdisk" "$W/ramdisk.gz"
~/twrp/out/host/linux-x86/bin/mkbootimg --kernel "$T/stock-unpacked/boot/kernel" --ramdisk "$W/ramdisk.gz" \
  --cmdline "$1" --base 0x40078000 --pagesize 2048 --kernel_offset 0x00008000 --ramdisk_offset 0x04f88000 \
  --second_offset 0x00e88000 --tags_offset 0x03f88000 --os_version "$2" --os_patch_level "$3" \
  --output "$A/out/diag-boot.img"
ls -la "$A/out/diag-boot.img"; sha256sum "$A/out/diag-boot.img"
