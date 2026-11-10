#!/bin/bash
# Repack a boot.img with the current gemini8 kernel, keeping the ramdisk and
# every header value of a reference boot.img (default: the image the tablet
# runs). Usage: kernel_boot.sh <out.img> [ref.img]
set -e
A='/mnt/f/Voyo i8/LineageOS'
# LineageOS android_system_tools_mkbootimg, branch lineage-20.0.
H=$HOME/mkbootimg
K=$HOME/los-kernel/gemini8/kernel-3.18/out/arch/arm64/boot/Image.gz
OUT=$1; REF=${2:-$A/out/bpf/boot-k39.img}
T=$(mktemp -d)
INFO=$(python3 $H/unpack_bootimg.py --boot_img "$REF" --out $T/old)
OSV=$(echo "$INFO" | sed -n 's/^os version: //p')
OSP=$(echo "$INFO" | sed -n 's/^os patch level: //p')
CMD=$(echo "$INFO" | sed -n 's/^command line args: //p')
cat $K "$A/analysis/dtb0.dtb" > $T/kernel
python3 $H/mkbootimg.py --kernel $T/kernel --ramdisk $T/old/ramdisk \
  --base 0x40078000 --kernel_offset 0x00008000 --ramdisk_offset 0x04f88000 \
  --second_offset 0x00e88000 --tags_offset 0x03f88000 --pagesize 2048 \
  --header_version 0 --os_version "$OSV" --os_patch_level "$OSP" \
  --cmdline "$CMD" -o "$OUT"
python3 $H/unpack_bootimg.py --boot_img "$OUT" --out $T/new > $T/new.txt
# Everything but the kernel must be identical to the reference.
diff <(echo "$INFO" | grep -v -E '^kernel') <(grep -v -E '^kernel' $T/new.txt)
cmp $T/old/ramdisk $T/new/ramdisk
echo "$INFO" | grep -E 'command line|os version|os patch'
strings $T/new/kernel | grep -m1 'Linux version' || zcat -f $K | strings | grep -m1 'Linux version'
ls -la "$OUT"; rm -rf $T
