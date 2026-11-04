#!/bin/bash
A='/mnt/c/Users/David/Voyo i8/LineageOS'
cd ~/los-kernel/m95
echo "== image headers (code0 code1 text_offset image_size)"
xxd -l 32 "$A/analysis/Image"
xxd -l 32 out/arch/arm64/boot/Image
echo "== reserved memory in stock tree"
sed -n '/pstore-reserved-memory/,/};/p;/ram_console-reserved-memory/,/};/p' "$A/analysis/live.dts" | cut -c1-80
grep -n 'ramoops\|pstore' "$A/analysis/live.dts" | head
echo "== ramoops layout"
grep -n 'PSTORE_\|platform_device\|record_size\|ftrace_size\|console_size\|pmsg_size\|mem_address\|mem_size' fs/pstore/ram.c | sed -n 1,50p | cut -c1-90
grep -rn 'ramoops\|CONFIG_PSTORE_MEM' --include=*.c --include=*.h arch/arm64 drivers/misc/mediatek 2>/dev/null | head -12 | cut -c1-110
sed -n '/struct persistent_ram_buffer/,/};/p;/define PERSISTENT_RAM_SIG/p' fs/pstore/ram_core.c
echo "== setup_arch"
grep -n 'paging_init\|parse_early_param\|arm64_memblock_init' arch/arm64/kernel/setup.c | head
