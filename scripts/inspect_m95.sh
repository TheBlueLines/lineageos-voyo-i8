#!/bin/bash
cd ~/los-kernel/m95
H=$(find drivers/misc/mediatek -name lcm_drv.h | head -1); echo "hdr $H"
cat > /tmp/o.c <<C
#include <stdio.h>
#include <stddef.h>
typedef unsigned int u32; typedef unsigned short u16; typedef unsigned char u8; typedef int bool; typedef unsigned long size_t_;
#define __KERNEL__
#include "$PWD/$H"
#define P(f) printf("%4zu %s\n", offsetof(LCM_PARAMS,f), #f)
int main(){printf("sizeof %zu\n",sizeof(LCM_PARAMS));
P(type);P(ctrl);P(lcm_if);P(lcm_cmd_if);P(io_select_mode);P(width);P(height);P(physical_width);P(physical_height);P(physical_width_um);P(physical_height_um);P(dsi);
#define D(f) printf("%4zu dsi.%s\n", offsetof(LCM_PARAMS,dsi)+offsetof(LCM_DSI_PARAMS,f), #f)
D(mode);D(switch_mode);D(DSI_WMEM_CONTI);D(DSI_RMEM_CONTI);D(VC_NUM);D(LANE_NUM);D(data_format);D(intermediat_buffer_num);D(PS);D(word_count);D(packet_size);D(vertical_sync_active);D(vertical_backporch);D(vertical_frontporch);D(vertical_active_line);D(horizontal_sync_active);D(horizontal_backporch);D(horizontal_frontporch);D(horizontal_active_pixel);D(PLL_CLOCK);D(ssc_disable);D(ssc_range);D(cont_clock);D(clk_lp_per_line_enable);D(esd_check_enable);D(customization_esd_check_enable);
return 0;}
C
gcc -w -I. -o /tmp/o /tmp/o.c 2>&1 | head -20 && /tmp/o
echo; echo "--- touch makefile"; grep -n . drivers/input/touchscreen/mediatek/Makefile | head -30; grep -n 'TOUCHSCREEN_MTK' drivers/input/touchscreen/mediatek/Kconfig | head -20
echo "--- lcm Makefile"; sed -n 1,30p drivers/misc/mediatek/lcm/Makefile; grep -n -A4 'ft8716' drivers/misc/mediatek/lcm/mt65xx_lcm_list.c | head -24; wc -l drivers/misc/mediatek/lcm/ft8716_fhd_vdo_sharp/*.c
echo "--- dts"; ls arch/arm64/boot/dts | grep -iE 'mt6797|meizu|x970'; wc -l arch/arm64/boot/dts/meizu6797_6c_m_flat.dts; grep -n 'dtbs\|dtb-' arch/arm64/boot/dts/Makefile | head; grep -n -iE 'dtb|DTS' arch/arm64/Makefile | head
echo "--- trustonic refs"; grep -n 'TRUSTONIC\|MTK_TEE' arch/arm64/configs/m95_defconfig
