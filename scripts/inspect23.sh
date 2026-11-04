#!/bin/bash
cd ~/los-kernel/gemini8/kernel-3.18
H=drivers/misc/mediatek/video/include/disp_session.h
M=drivers/misc/mediatek/video/mt6797/videox/mtk_disp_mgr.c
awk '/^struct disp_ccorr_config/,/^};/' $H
grep -n "_ioctl_get_display_caps\|_ioctl_set_input_buffer\|ccorr_config" $M drivers/misc/mediatek/video/mt6797/videox/*.c | head -20
grep -n "case DISP_IOCTL_SET_INPUT_BUFFER" -A3 $M | head
grep -n "^int _ioctl_set_input_buffer\|^static int _ioctl_set_input_buffer" -A25 $M | head -40
grep -rn "COMPAT_DISP_IOCTL_SET_INPUT_BUFFER\|COMPAT_DISP_IOCTL_GET_DISPLAY_CAPS" drivers/misc/mediatek/video/mt6797/videox/*.h | head
