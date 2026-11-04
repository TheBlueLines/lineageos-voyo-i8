#!/bin/bash
A='/mnt/c/Users/David/Voyo i8/LineageOS'
cd ~/los-kernel
python3 - "$A/analysis/Image" m95/out/arch/arm64/boot/Image <<'PY'
import struct, sys
for p in sys.argv[1:]:
    h = open(p, 'rb').read(64)
    print(p[-30:], 'text_offset', hex(struct.unpack_from('<Q', h, 8)[0]), 'size', hex(struct.unpack_from('<Q', h, 16)[0]), 'code0', h[:4].hex())
PY
grep -E ' (_text|_stext)$' m95/out/System.map
cd gemini8/kernel-3.18 || exit 1
git -C .. log --oneline -3
ls; grep -E '^(VERSION|PATCHLEVEL|SUBLEVEL)' Makefile
ls arch/arm64/configs | grep -vE 'defconfig$' | head; ls arch/arm64/configs | grep -iE '6797|aeon|gemini|e[0-9]' | head -20
ls arch/arm64/boot/dts | grep -iE '6797|aeon|gemini' | head -20
ls drivers/misc/mediatek/gpu/gpu_mali/ 2>/dev/null; ls drivers/misc/mediatek/gpu/gpu_mali/mali_midgard 2>/dev/null
ls drivers/input/touchscreen/mediatek | head -30
ls drivers/misc/mediatek/lcm | wc -l
ls drivers/misc/mediatek/power/mt6797 | head -24
sed -n '/drvgen/p' arch/arm64/Makefile | head
ls scripts/drvgen 2>/dev/null | head; ls drivers/misc/mediatek/dws 2>/dev/null | head
