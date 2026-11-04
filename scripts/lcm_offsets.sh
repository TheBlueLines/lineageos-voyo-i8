#!/bin/bash
# lcm_offsets.sh: print LCM_PARAMS field offsets of the Gemini kernel header,
# to map stores in the stock lcm_get_params disassembly to field names.
set -e
K=$HOME/los-kernel/gemini8/kernel-3.18
T=$HOME/los-kernel/gcc49/bin/aarch64-linux-android-
H=$(find $K/drivers/misc/mediatek -name lcm_drv.h | head -1)
echo "header: $H"
W=$(mktemp -d)
cat > $W/o.c <<EOF
#include <stddef.h>
#include "lcm_drv.h"
#define Q(n,f) int n = offsetof(LCM_PARAMS, f);
Q(a00_type,type) Q(a01_lcm_if,lcm_if) Q(a02_lcm_cmd_if,lcm_cmd_if) Q(a03_width,width) Q(a04_height,height) Q(a05_dsi,dsi)
Q(b00_mode,dsi.mode) Q(b01_switch_mode,dsi.switch_mode) Q(b02_lane,dsi.LANE_NUM) Q(b03_fmt,dsi.data_format) Q(b04_PS,dsi.PS) Q(b05_wc,dsi.word_count) Q(b06_pkt,dsi.packet_size)
Q(c00_vsa,dsi.vertical_sync_active) Q(c01_vbp,dsi.vertical_backporch) Q(c02_vfp,dsi.vertical_frontporch) Q(c03_val,dsi.vertical_active_line)
Q(c04_hsa,dsi.horizontal_sync_active) Q(c05_hbp,dsi.horizontal_backporch) Q(c06_hfp,dsi.horizontal_frontporch) Q(c07_hap,dsi.horizontal_active_pixel)
Q(d00_pll,dsi.PLL_CLOCK) Q(d01_ssc,dsi.ssc_disable) Q(d02_cont,dsi.cont_clock) Q(d03_ufoe_en,dsi.ufoe_enable) Q(d04_ufoe_p,dsi.ufoe_params) Q(d05_lr,dsi.ufoe_params.lr_mode_en) Q(d06_cr,dsi.ufoe_params.compress_ratio) Q(d07_vlcd,dsi.ufoe_params.vlc_disable) Q(d08_dual,dsi.dual_dsi_type) Q(d09_esd,dsi.esd_check_enable) Q(d10_cust,dsi.customization_esd_check_enable) Q(d11_clklp,dsi.clk_lp_per_line_enable)
int z_size = sizeof(LCM_PARAMS);
EOF
${T}gcc -c -o $W/o.o -D__KERNEL__ -include $K/include/linux/kconfig.h -I $(dirname $H) -I $K/arch/arm64/include -I $K/out/arch/arm64/include/generated -I $K/include -I $K/out/include -I $K/arch/arm64/include/uapi -I $K/include/uapi -I $K/out/include/generated/uapi -I $K/drivers/misc/mediatek/include -I $K/drivers/misc/mediatek/include/mt-plat $W/o.c
${T}objcopy -O binary -j .data $W/o.o $W/d.bin
${T}nm -n $W/o.o | awk '$2=="D"{print $3}' > $W/names
od -An -td4 -w4 -v $W/d.bin | paste $W/names -
rm -rf $W
