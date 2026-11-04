#!/bin/bash
# Repack the built boot.img with the BOARD_KERNEL_CMDLINE from BoardConfig.mk,
# keeping kernel, ramdisk and offsets. Saves the old image as boot.img.prev.
set -e
L=$HOME/los
P=$L/out/target/product/x970_t10_97inc
B=$L/device/voyo/x970_t10_97inc/BoardConfig.mk
rsync -a '/mnt/c/Users/David/Voyo i8/LineageOS/device/voyo/x970_t10_97inc/BoardConfig.mk' "$B"
sed -i 's/\r$//' "$B"
CMD=$(grep -E '^BOARD_KERNEL_CMDLINE \+?:?=' "$B" | sed -E 's/^BOARD_KERNEL_CMDLINE \+?:?= *//' | tr '\n' ' ' | sed 's/ *$//')
# The build system appends buildvariant=<variant>.
CMD="$CMD buildvariant=userdebug"
T=$(mktemp -d)
# Start from the previous image if this already ran, so the header values
# (OS version, patch level) are always the build's own.
[ -f $P/boot.img.prev ] || cp $P/boot.img $P/boot.img.prev
INFO=$($L/out/host/linux-x86/bin/unpack_bootimg --boot_img $P/boot.img.prev --out $T)
OSV=$(echo "$INFO" | sed -n 's/^os version: //p')
OSP=$(echo "$INFO" | sed -n 's/^os patch level: //p')
$L/out/host/linux-x86/bin/mkbootimg --kernel $T/kernel --ramdisk $T/ramdisk \
  --base 0x40078000 --kernel_offset 0x00008000 --ramdisk_offset 0x04f88000 \
  --second_offset 0x00e88000 --tags_offset 0x03f88000 --pagesize 2048 \
  --header_version 0 --os_version "$OSV" --os_patch_level "$OSP" \
  --cmdline "$CMD" -o $P/boot.img
echo "cmdline (${#CMD} chars, LK keeps 99): $CMD"
$L/out/host/linux-x86/bin/unpack_bootimg --boot_img $P/boot.img --out $T/new | grep -iE 'command line|os version|os patch'
$L/out/host/linux-x86/bin/unpack_bootimg --boot_img $P/boot.img.prev --out $T/old | grep -iE 'command line|os version|os patch'
cmp $T/kernel $T/new/kernel && cmp $T/ramdisk $T/new/ramdisk && echo "kernel+ramdisk identical"
rm -rf $T
