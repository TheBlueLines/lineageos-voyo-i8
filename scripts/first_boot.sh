#!/bin/sh
# From TWRP: sanity-check the flash, format /data, boot LineageOS, then watch.
export MSYS_NO_PATHCONV=1
adb shell 'mkdir -p /tmp/s /tmp/v; mount -o ro -t ext4 /dev/block/mmcblk0p30 /tmp/s && grep -E "ro.lineage.version=|ro.build.version.release=" /tmp/s/system/build.prop; mount -o ro -t ext4 /dev/block/mmcblk0p29 /tmp/v && ls /tmp/v/lib | wc -l; umount /tmp/s /tmp/v'
adb shell 'umount /data 2>/dev/null; twrp format data 2>&1 | tail -3'
adb shell 'blkid /dev/block/mmcblk0p32 2>/dev/null | cut -c1-90'
adb shell reboot
for i in $(seq 1 24); do
  sleep 10
  S=$(adb devices | sed -n 2p | tr -d '\r')
  echo "$((i*10))s: ${S:-no device}"
  case "$S" in *device*|*recovery*) break;; esac
done
adb shell 'getprop ro.twrp.version; getprop ro.lineage.version; uname -r; getprop sys.boot_completed; getprop init.svc.zygote; getprop init.svc.surfaceflinger' 2>&1
