#!/bin/bash
cd ~/los-kernel/gemini8/kernel-3.18
sed -n 415,445p drivers/misc/mediatek/video/include/disp_session.h
grep -n "GET_DISPLAY_CAPS\|_ioctl_get_display_caps\|case DISP_IOCTL" drivers/misc/mediatek/video/mt6797/videox/mtk_disp_mgr.c | head -50
