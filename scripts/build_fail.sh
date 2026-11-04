#!/bin/bash
# Show why the last build failed.
L=$HOME/los/build.log
date
ls -la ~/los/out/target/product/x970_t10_97inc/*.img 2>/dev/null
grep -n '^FAILED' "$L" | head -8 | cut -c1-200
n=$(grep -n '^FAILED' "$L" | head -1 | cut -d: -f1)
[ -n "$n" ] && sed -n "$n,$((n+${1:-40}))p" "$L" | grep -vE '^\[ *[0-9]+%' | cut -c1-${2:-260} | tail -n 22
free -g | sed -n 2,3p
