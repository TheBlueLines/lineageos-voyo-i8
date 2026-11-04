#!/bin/bash
cd ~/los-kernel/gemini8/kernel-3.18
grep -rn "DISP_IOCTL_GET_DISPLAY_CAPS\|disp_caps_info\|DISP_IOCTL_" drivers/misc/mediatek/video/include/disp_session.h | head -60
grep -rln "mtk_disp_mgr_ioctl" drivers/misc/mediatek/video | head
