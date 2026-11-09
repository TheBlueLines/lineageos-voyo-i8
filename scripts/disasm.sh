#!/bin/bash
# disasm.sh <start-hex> <stop-hex> : disassemble a range of the stock kernel Image.
A=/mnt/f/Voyo\ i8/LineageOS
OD=$HOME/los-kernel/gcc49/bin/aarch64-linux-android-objdump
TEXT=ffffffc000080000
"$OD" -D -b binary -m aarch64 --adjust-vma=0x$TEXT --start-address=0x$1 --stop-address=0x$2 "$A/analysis/Image" | awk '/^ *[0-9a-f]+:/' | cut -c1-90
