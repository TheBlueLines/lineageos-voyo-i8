#!/sbin/sh
# TWRP: undo voyo-i8-camera zip from the backups it saved on the SD card.
OUTFD=/proc/self/fd/$2
ui_print() { echo "ui_print $1" > "$OUTFD"; echo "ui_print" > "$OUTFD"; }
abort() { ui_print "ERROR: $1"; exit 1; }
BOOT=/dev/block/mmcblk0p23
VENDOR=/dev/block/mmcblk0p29
BK=/external_sd/LineageOS/camera-backup
T=/tmp/camrb
mount | grep -q " /external_sd " || mount /external_sd 2>/dev/null
[ -f $BK/boot.img ] || abort "no backup in $BK"
[ "$(dd if=$BK/boot.img bs=8 count=1 2>/dev/null)" = "ANDROID!" ] || abort "backup is not a boot image"
dd if=$BK/boot.img of=$BOOT bs=1048576 2>/dev/null || abort "boot write failed"
sync; ui_print "Restored boot"
if [ -f $BK/camerahalserver.rc ]; then
  umount /vendor 2>/dev/null
  mkdir -p $T/v && mount -t ext4 -o rw $VENDOR $T/v && {
    cat $BK/camerahalserver.rc > $T/v/etc/init/camerahalserver.rc
    sync; umount $T/v; ui_print "Restored camerahalserver.rc"; }
fi
rm -rf $T
ui_print "Done. Reboot to System."
exit 0
