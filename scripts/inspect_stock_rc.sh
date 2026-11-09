#!/bin/bash
# Summarise the stock init setup that the device tree has to reproduce.
T='/mnt/f/Voyo i8/TWRP'
R=$HOME/stockfs/ramdisk
mkdir -p "$R"
[ -f "$R/init.rc" ] || (cd "$R" && zcat "$T/stock-unpacked/boot/ramdisk" | cpio -id --no-absolute-filenames 2>/dev/null)
cd "$R"; ls
cd ~/stockfs/vendor
echo "== vendor/etc/init"; ls etc/init | tr '\n' ' '; echo
echo "== fstab"; grep -v '^#' etc/fstab.mt6797 | cut -c1-130
echo "== ramdisk mt6797 rc: services"
grep -hE '^service ' "$R"/init.mt6797*.rc "$R"/*.rc 2>/dev/null | sort -u | cut -c1-90 | head -70
echo "== vendor rc services"
grep -hE '^service ' etc/init/*.rc | sort -u | cut -c1-90 | wc -l
echo "== usb"; ls "$R" | grep -i usb; grep -n 'functionfs\|ffs\|android_usb\|configfs' "$R"/init.*usb*.rc | head -14 | cut -c1-90
echo "== build.prop"; grep -vE '^#|^$' build.prop | grep -E 'vndk|treble|gralloc|hwui|egl|sf\.|mediatek.platform|first_api|shipping' | head -20
echo "== manifest hals"; grep -E '<name>' manifest.xml | sed 's/ *<name>//;s/<.*//' | sort -u | tr '\n' ' '; echo
echo "== hw modules"; ls lib64/hw | grep -v impl | tr '\n' ' '; echo; ls lib/egl lib64/egl 2>/dev/null | tr '\n' ' '; echo
