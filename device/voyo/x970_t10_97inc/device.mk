#
# SPDX-License-Identifier: Apache-2.0
#

LOCAL_PATH := device/voyo/x970_t10_97inc

PRODUCT_SOONG_NAMESPACES += \
    device/voyo/x970_t10_97inc

# Flattened APEXes: no loop and dm dependency on this kernel, and less to fit
# in the 2.5 GiB system partition.
OVERRIDE_TARGET_FLATTEN_APEX := true

PRODUCT_ENFORCE_VINTF_MANIFEST_OVERRIDE := true
PRODUCT_OTA_ENFORCE_VINTF_KERNEL_REQUIREMENTS := false
PRODUCT_USE_DYNAMIC_PARTITIONS := false

# Bring-up logger, started from init.mt6797.rc.
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/rootdir/bin/voyo_diag.sh:$(TARGET_COPY_OUT_VENDOR)/bin/voyo_diag.sh \
    $(LOCAL_PATH)/rootdir/voyo_gps.rc:$(TARGET_COPY_OUT_SYSTEM_EXT)/etc/init/voyo_gps.rc \
    $(LOCAL_PATH)/rootdir/voyo_modem.rc:$(TARGET_COPY_OUT_SYSTEM_EXT)/etc/init/voyo_modem.rc

# Stock blobs. Keep the device overrides above this line: the first
# PRODUCT_COPY_FILES entry for a path wins.
$(call inherit-product, vendor/voyo/x970_t10_97inc/x970_t10_97inc-vendor.mk)

PRODUCT_DEVICE := x970_t10_97inc

# Dalvik heap, as stock for a 4 GB tablet
PRODUCT_PROPERTY_OVERRIDES += \
    dalvik.vm.heapstartsize=8m \
    dalvik.vm.heapgrowthlimit=256m \
    dalvik.vm.heapsize=512m \
    dalvik.vm.heaptargetutilization=0.75 \
    dalvik.vm.heapminfree=512k \
    dalvik.vm.heapmaxfree=8m

# Resource overlays (built as RROs on /vendor/overlay)
DEVICE_PACKAGE_OVERLAYS += $(LOCAL_PATH)/overlay

PRODUCT_AAPT_CONFIG := normal large xlarge
PRODUCT_AAPT_PREF_CONFIG := xhdpi
PRODUCT_CHARACTERISTICS := tablet

# Ramdisk and init
PRODUCT_PACKAGES += \
    fstab.mt6797 \
    fstab.mt6797.ramdisk \
    ueventd.mt6797.rc \
    init.mt6797.rc \
    init.mt6797.usb.rc

# Shims for the Android 8 blobs.
PRODUCT_PACKAGES += \
    l8bc \
    l8bdl \
    l8bEGL \
    libminijail.vendor

# AOSP HALs that replace the Android 8 ones, loading the legacy modules.
# Mapper 2.0: 2.1 needs gralloc1 VALIDATE_BUFFER_SIZE, which the stock module lacks.
PRODUCT_PACKAGES += \
    android.hardware.graphics.composer@2.1-service \
    android.hardware.graphics.mapper@2.0-impl \
    android.hardware.health@2.1-impl \
    android.hardware.health@2.1-service \
    android.hardware.audio.service \
    android.hardware.audio@6.0-impl \
    android.hardware.audio.effect@6.0-impl \
    audio.r_submix.default \
    audio.usb.default

# Bring-up: root adb without authorization. Remove before any release.
PRODUCT_DEFAULT_PROPERTY_OVERRIDES += \
    ro.secure=0 \
    ro.debuggable=1 \
    ro.adb.secure=0
