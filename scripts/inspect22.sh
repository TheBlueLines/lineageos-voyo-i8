#!/bin/bash
cd ~/los-kernel/gemini8/kernel-3.18
H=drivers/misc/mediatek/video/include/disp_session.h
grep -n "RSZ_RES_LIST_NUM\|CONFIG_FOR_SOURCE_PQ" $H | head
awk '/^typedef struct disp_caps_t/,/} disp_caps_info;/' $H | grep -v "^\s*\*\|/\*" 
grep -n "CONFIG_FOR_SOURCE_PQ" out/.config
awk '/^typedef struct disp_session_input_config_t/,/} disp_session_input_config;/' $H
grep -n "disp_input_config\b\|^typedef struct disp_input_config_t" $H | head -3
awk '/^typedef struct disp_input_config_t/,/} disp_input_config;/' $H
sed -n 1404,1440p drivers/misc/mediatek/video/mt6797/videox/mtk_disp_mgr.c
