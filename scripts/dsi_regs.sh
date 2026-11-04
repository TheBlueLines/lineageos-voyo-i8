#!/bin/bash
# Print the DSI_REGS layout of the MT6797 display driver.
cd $HOME/los-kernel/gemini8/kernel-3.18/drivers/misc/mediatek/video/mt6797/dispsys
f=$(grep -ln "} DSI_REGS;" *.h | head -1)
echo "$f"
awk '/DSI_START_REG[ \t]+DSI_START;/{p=1} p{print} /} DSI_REGS;/{exit}' "$f" | grep -n "" | head -90
grep -n "DSI_REGS\b\|dsi_dump\|DSI_DumpRegisters" ../dispsys/ddp_dsi.c | head
