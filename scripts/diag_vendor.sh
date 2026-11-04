#!/bin/sh
# From TWRP: add voyo_diag.sh to the flashed vendor partition. Usage: diag_vendor.sh
export MSYS_NO_PATHCONV=1
adb shell 'mkdir -p /tmp/v; mount -t ext4 -o rw /dev/block/mmcblk0p29 /tmp/v'
adb push "$(dirname "$0")/voyo_diag.sh" /tmp/v/bin/voyo_diag.sh
adb push "$(dirname "$0")/voyo_diag.rc" /tmp/rcadd
adb shell 'chmod 755 /tmp/v/bin/voyo_diag.sh; chown 0:2000 /tmp/v/bin/voyo_diag.sh
rc=$(grep -rl "VOYO i8 additions" /tmp/v/etc/init | head -1); echo "rc: $rc"
grep -q voyo_diag "$rc" || cat /tmp/rcadd >> "$rc"; tail -4 "$rc"; sync; umount /tmp/v; echo unmounted'
