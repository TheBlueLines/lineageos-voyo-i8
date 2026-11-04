cd ~/los-kernel
zcat "/mnt/c/Users/David/Voyo i8/LineageOS/device-info/config.gz" > /tmp/stock.config
K='MTK_RAM_CONSOLE|PSTORE|MTK_AEE|MTK_PRINTK|PRINTK|LOG_BUF|MTK_SCHED|MTK_CPU_|ARM64_(PA|VA)|DEFAULT_MMAP|MTK_MEM|MTK_FIQ|FIQ_|MTK_WATCHDOG|MTK_WD|MTK_ACAO|MTK_HIBERNATION|MACH_MT|ARCH_MT|MTK_CHIP|MTK_CLKMGR|MTK_LEGACY|MTK_CIRQ|MTK_IRQ|MTK_GIC|GIC|ARM_GIC|CPU_IDLE|MTK_ACAO|ARM_MT|MT6797|MTK_HMP|SCHED_HMP|NR_CPUS|PGTABLE|ARM64_4K|BOOT|MTK_SYS_CIRQ|MTK_DRAMC|MTK_UART|SERIAL_MT|MTK_SERIAL'
grep -E "^CONFIG_($K)[A-Z0-9_]*=" /tmp/stock.config | sort > /tmp/a
grep -E "^CONFIG_($K)[A-Z0-9_]*=" m95/out/.config | sort > /tmp/b
diff /tmp/a /tmp/b | grep -E '^[<>]' | cut -c1-90 | head -50
grep -n 'ram_console\|RAM_CONSOLE' m95/drivers/misc/mediatek/ram_console/Makefile | head
sed -n '/of_device_id\|compatible/p' m95/drivers/misc/mediatek/ram_console/mtk_ram_console.c | head; grep -n 'ram_console_early_init\|early_initcall\|console_initcall\|pure_initcall\|ram_console_late\|module_init\|ram_console_init' m95/drivers/misc/mediatek/ram_console/mtk_ram_console.c | head
