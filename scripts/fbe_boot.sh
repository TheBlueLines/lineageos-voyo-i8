#!/bin/bash
# Rebuild boot.img with the current gemini8 kernel and the device fstab,
# without a full Soong build: syncs fstab.mt6797 into the LOS tree and the
# ramdisk/vendor staging dirs, repacks the ramdisk with mkbootfs and keeps the
# header values (cmdline, OS version, patch level) of the existing boot.img.
# Outputs: $P/boot.img (old one saved as boot.img.pre-fbe once) and
# $P/vendor/etc/fstab.mt6797, which must also reach the tablet's /vendor.
set -e
L=$HOME/los
A='/mnt/f/Voyo i8/LineageOS'
D=$L/device/voyo/x970_t10_97inc
P=$L/out/target/product/x970_t10_97inc
H=$L/out/host/linux-x86/bin
K=$HOME/los-kernel/gemini8/kernel-3.18/out/arch/arm64/boot/Image.gz

sed 's/\r$//' "$A/device/voyo/x970_t10_97inc/rootdir/fstab.mt6797" > $D/rootdir/fstab.mt6797
cp $D/rootdir/fstab.mt6797 $P/ramdisk/fstab.mt6797
cp $D/rootdir/fstab.mt6797 $P/vendor/etc/fstab.mt6797
cat $K "$A/analysis/dtb0.dtb" > $D/prebuilt/Image.gz-dtb
cp $D/prebuilt/Image.gz-dtb $P/kernel

T=$(mktemp -d)
[ -f $P/boot.img.pre-fbe ] || cp $P/boot.img $P/boot.img.pre-fbe
INFO=$($H/unpack_bootimg --boot_img $P/boot.img --out $T/old)
OSV=$(echo "$INFO" | sed -n 's/^os version: //p')
OSP=$(echo "$INFO" | sed -n 's/^os patch level: //p')
CMD=$(echo "$INFO" | sed -n 's/^command line args: //p')

$H/mkbootfs -d $P/system $P/ramdisk | $H/minigzip > $P/ramdisk.img
$H/mkbootimg --kernel $P/kernel --ramdisk $P/ramdisk.img \
  --base 0x40078000 --kernel_offset 0x00008000 --ramdisk_offset 0x04f88000 \
  --second_offset 0x00e88000 --tags_offset 0x03f88000 --pagesize 2048 \
  --header_version 0 --os_version "$OSV" --os_patch_level "$OSP" \
  --cmdline "$CMD" -o $P/boot.img

$H/unpack_bootimg --boot_img $P/boot.img --out $T/new | grep -E 'command line args|os (version|patch)|kernel_size|ramdisk size'
# Same file list in the old and new ramdisk; only the fstab may differ.
(cd $T/old && mkdir r && cd r && zcat ../ramdisk | cpio -id --quiet 2>/dev/null)
(cd $T/new && mkdir r && cd r && zcat ../ramdisk | cpio -id --quiet 2>/dev/null)
diff -r $T/old/r $T/new/r || true
ls -la $P/boot.img
rm -rf $T
