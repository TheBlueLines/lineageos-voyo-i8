LOCAL_PATH := $(call my-dir)

ifeq ($(TARGET_DEVICE),x970_t10_97inc)
include $(call all-subdir-makefiles,$(LOCAL_PATH))
endif
