#!/bin/sh
# Read-only dump of the partitions missing from ../TWRP/stock-backup, verified by SHA-256.
out="$1"; mkdir -p "$out"; cd "$out" || exit 1
base=/dev/block/platform/mtk-msdc.0/11230000.msdc0/by-name
rc=0
dump() { # name devicepath
  n=$1; dev=$2
  if [ -s "$n.bin" ] && [ "$(sha256sum "$n.bin" | cut -d' ' -f1)" = "$(cut -d' ' -f1 "$n.sha256" 2>/dev/null)" ]; then echo "$n: already verified"; return; fi
  remote=$(adb shell "sha256sum $dev" | tr -d '\r' | cut -d' ' -f1)
  echo "$remote  $n.bin" > "$n.sha256"
  adb exec-out "dd if=$dev bs=1048576 2>/dev/null" > "$n.bin"
  local_hash=$(sha256sum "$n.bin" | cut -d' ' -f1)
  if [ "$remote" = "$local_hash" ]; then echo "$n: OK $(wc -c < "$n.bin") bytes"; else echo "$n: HASH MISMATCH"; rc=1; fi
}
for p in vendor system flashinfo cache; do dump "$p" "$base/$p"; done
dump preloader_boot0 /dev/block/mmcblk0boot0
dump preloader_boot1 /dev/block/mmcblk0boot1
exit $rc
