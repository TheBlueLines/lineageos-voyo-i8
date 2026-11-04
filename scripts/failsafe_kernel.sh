#!/bin/bash
# Bring-up kernel: mark the RTC recovery flag at boot, so that a panic, a
# watchdog reset or any reboot lands in TWRP instead of looping.
set -e
A='/mnt/c/Users/David/Voyo i8/LineageOS'
cd ~/los-kernel/gemini8/kernel-3.18
F=drivers/misc/mediatek/rtc/voyo_failsafe.c
if [ ! -f "$F" ]; then
cat > $F <<'C'
/* Bring-up only: send every following boot to recovery. */
#include <linux/init.h>
#include <mt-plat/mtk_rtc.h>

static int __init voyo_failsafe_init(void)
{
	rtc_mark_recovery();
	return 0;
}
late_initcall(voyo_failsafe_init);
C
fi
grep -rn 'void rtc_mark_recovery' drivers/misc/mediatek include 2>/dev/null | head -3 | cut -c1-90
ls drivers/misc/mediatek/rtc/ | head; grep -n 'obj' drivers/misc/mediatek/rtc/Makefile | head
find drivers/misc/mediatek/include -name 'mtk_rtc*.h' -o -name 'mt_rtc*.h' | head
grep -q voyo_failsafe drivers/misc/mediatek/rtc/Makefile || echo 'obj-y += voyo_failsafe.o' >> drivers/misc/mediatek/rtc/Makefile
