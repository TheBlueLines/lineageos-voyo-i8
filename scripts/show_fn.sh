#!/bin/bash
# show_fn.sh <file relative to mt6797/dispsys or videox> <regex> [lines]: print a function.
cd $HOME/los-kernel/gemini8/kernel-3.18/drivers/misc/mediatek/video/mt6797
n=$(grep -n -E "$2" "$1" | head -1 | cut -d: -f1)
[ -n "$n" ] || { echo "not found"; exit 1; }
sed -n "${n},$((n + ${3:-60}))p" "$1"
