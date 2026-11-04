cd ~/los-kernel/m95; grep -E '^(# )?CONFIG_(RD_[A-Z0-9]+|DEBUG_KMEMLEAK|DEBUG_INFO|KALLSYMS_ALL|SLUB_DEBUG|LOCKDEP|PROVE_LOCKING|FTRACE|MTK_AEE_FEATURE|MTK_MET|DEBUG_SPINLOCK|DEBUG_MUTEXES|PSTORE|PSTORE_CONSOLE|MTK_RAM_CONSOLE)( |=)' out/.config
ls ~/twrp/out/host/linux-x86/bin 2>/dev/null | grep -E 'mkbootimg|unpack' ; find ~/twrp -name 'mkbootimg*' -type f 2>/dev/null | head -5
which xz cpio lz4
