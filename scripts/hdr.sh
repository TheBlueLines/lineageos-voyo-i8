cd ~/los-kernel/m95/drivers/misc/mediatek/lcm/inc
grep -n 'PLL_CLOCK;' lcm_drv.h; L=$(grep -n 'unsigned int PLL_CLOCK;' lcm_drv.h | sed -n 2p | cut -d: -f1); sed -n "$((L-1)),$((L+18))p" lcm_drv.h
grep -n 'format;\|LCM_DSI_FORMAT_RGB888\|LCM_PACKED_PS_24BIT_RGB888\|SYNC_EVENT_VDO_MODE\|LCM_THREE_LANE\|LCM_FOUR_LANE\|LCM_INTERFACE_DSI0\|LCM_INTERFACE_DSI1\|LCM_TYPE_DSI' lcm_drv.h | head
