#!/sbin/sh
# TWRP installer: VOYO i8 camera fix (kernel #25 with GC5005/GC2235 drivers,
# camerahalserver started at boot). Backs up the current boot partition and
# camerahalserver.rc to /external_sd/LineageOS/camera-backup/ first.
OUTFD=/proc/self/fd/$2
ZIP="$3"
ui_print() { echo "ui_print $1" > "$OUTFD"; echo "ui_print" > "$OUTFD"; }
abort() { ui_print "ERROR: $1"; ui_print "Nothing was changed after this point."; exit 1; }

BOOT=/dev/block/mmcblk0p23
VENDOR=/dev/block/mmcblk0p29
BK=/external_sd/LineageOS/camera-backup
T=/tmp/camfix

ui_print "VOYO i8 camera fix"
for l in /dev/block/platform/*/by-name/boot /dev/block/platform/*/*/by-name/boot /dev/block/by-name/boot; do
  [ -e "$l" ] && { [ "$(readlink -f "$l")" = "$BOOT" ] || abort "boot is $(readlink -f "$l"), expected $BOOT"; }
done
for l in /dev/block/platform/*/by-name/vendor /dev/block/platform/*/*/by-name/vendor /dev/block/by-name/vendor; do
  [ -e "$l" ] && { [ "$(readlink -f "$l")" = "$VENDOR" ] || abort "vendor is $(readlink -f "$l"), expected $VENDOR"; }
done
[ "$(dd if=$BOOT bs=8 count=1 2>/dev/null)" = "ANDROID!" ] || abort "$BOOT has no boot image header"
mount | grep -q " /external_sd " || mount /external_sd 2>/dev/null
[ -d /external_sd ] && touch /external_sd/.camfix_test 2>/dev/null || abort "SD card not writable (needed for the backup)"
rm -f /external_sd/.camfix_test

rm -rf $T; mkdir -p $T
unzip -o "$ZIP" boot.img boot.sha256 -d $T >/dev/null || abort "cannot extract boot.img"
[ "$(sha256sum $T/boot.img | cut -d' ' -f1)" = "$(cat $T/boot.sha256)" ] || abort "boot.img checksum mismatch"

# Backups (kept from the first run, so a second run doesn't overwrite them).
mkdir -p $BK
if [ ! -f $BK/boot.img ]; then
  dd if=$BOOT of=$BK/boot.img bs=1048576 2>/dev/null || abort "boot backup failed"
  ui_print "Saved current boot to $BK/boot.img"
fi

mkdir -p $T/v
umount /vendor 2>/dev/null
mount -t ext4 -o rw $VENDOR $T/v || abort "cannot mount vendor (unmount it in TWRP > Mount and retry)"
RC=$T/v/etc/init/camerahalserver.rc
[ -f "$RC" ] || { umount $T/v; abort "camerahalserver.rc not found"; }
[ -f $BK/camerahalserver.rc ] || cp -p "$RC" $BK/camerahalserver.rc
if grep -q '^[[:space:]]*disabled[[:space:]]*$' "$RC"; then
  grep -v '^[[:space:]]*disabled[[:space:]]*$' "$RC" > $T/rc.new
  cat $T/rc.new > "$RC"   # in place: keeps the inode and its SELinux label
  ui_print "camerahalserver: will start at boot"
else
  ui_print "camerahalserver: already enabled"
fi
ls -Z "$RC" 2>/dev/null | grep -q vendor_configs_file || chcon u:object_r:vendor_configs_file:s0 "$RC" 2>/dev/null
sync; umount $T/v

ui_print "Flashing boot (kernel #25)..."
dd if=$T/boot.img of=$BOOT bs=1048576 2>/dev/null || abort "boot write failed; restore $BK/boot.img"
sync
N=$(stat -c %s $T/boot.img)
[ "$(dd if=$BOOT bs=2048 count=$((N/2048)) 2>/dev/null | sha256sum | cut -d' ' -f1)" = "$(cat $T/boot.sha256)" ] \
  || abort "boot verify failed; flash $BK/boot.img as Boot image"
ui_print "Done. Reboot to System."
ui_print "Rollback: flash voyo-i8-camera-rollback.zip"
rm -rf $T
exit 0
