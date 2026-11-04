#!/bin/bash
# Show the failing step of the last build without routine kernel make noise.
L=$HOME/los/build.log
n=$(grep -n '^FAILED' "$L" | head -1 | cut -d: -f1)
[ -n "$n" ] && sed -n "$n,$((n+${1:-400}))p" "$L" | grep -vE '^\[ *[0-9]+%|^ +(WRAP|HOSTCC|HOSTLD|SYSHDR|SYSTBL|INSTALL|CHECK|HDRINST|HOSTCXX) ' | cut -c1-${2:-230} | tail -n ${3:-24}
