#!/bin/bash
# Drop Kbuild entries for headers the tree doesn't have, until headers_install
# passes. Applies to the working kernel, then mirrors it into ~/los.
cd ~/los-kernel/gemini8/kernel-3.18
for i in $(seq 1 40); do
  out=$(make ARCH=arm64 O=/tmp/hdr HOSTCFLAGS=-fcommon headers_install 2>&1) && { echo "headers_install OK after $i passes"; break; }
  miss=$(echo "$out" | grep -oE 'Missing UAPI file [^ ]+' | head -1 | sed 's/Missing UAPI file //; s/\.$//')
  [ -n "$miss" ] || { echo "$out" | tail -8; exit 1; }
  rel=${miss#$PWD/}; h=$(basename "$rel"); d=$(dirname "$rel")
  echo "drop $rel"
  for k in "$d/Kbuild" "${d/uapi\//}/Kbuild"; do [ -f "$k" ] && sed -i "/[[:space:]]$h\$/d" "$k"; done
done
git add -A; git -c user.name=voyo-port -c user.email=port@localhost commit -q -m "uapi: Drop Kbuild entries for missing headers" || true
bash '/mnt/f/Voyo i8/LineageOS/scripts/sync_kernel_src.sh'
