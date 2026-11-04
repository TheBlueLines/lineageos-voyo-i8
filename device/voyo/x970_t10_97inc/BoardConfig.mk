#
# SPDX-License-Identifier: Apache-2.0
#

DEVICE_PATH := device/voyo/x970_t10_97inc

# Build
# The Android 8 blobs are plain files with unresolved DT_NEEDED entries.
BUILD_BROKEN_DUP_RULES := true
BUILD_BROKEN_MISSING_REQUIRED_MODULES := true
BUILD_BROKEN_ELF_PREBUILT_PRODUCT_COPY_FILES := true
BUILD_BROKEN_VENDOR_PROPERTY_NAMESPACE := true
BUILD_BROKEN_DUP_SYSPROP := true

# Architecture
# MT6797X: 2x Cortex-A72 + 8x Cortex-A53, ARMv8.0-A without LSE atomics.
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 :=
TARGET_CPU_VARIANT := generic

TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv8-a
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 := armeabi
TARGET_2ND_CPU_VARIANT := cortex-a53
TARGET_USES_64_BIT_BINDER := true

# Platform
TARGET_BOARD_PLATFORM := mt6797
TARGET_NO_BOOTLOADER := true
BOARD_VENDOR := voyo

# Kernel
# Built from kernel-port in the project folder, then the stock base DTB is
# appended. LK merges the board overlay from odmdtbo onto it.
TARGET_PREBUILT_KERNEL := $(DEVICE_PATH)/prebuilt/Image.gz-dtb
TARGET_FORCE_PREBUILT_KERNEL := true
# The source is only used for the generated kernel headers.
TARGET_KERNEL_SOURCE := kernel/voyo/x970_t10_97inc
TARGET_KERNEL_CONFIG := x970_t10_97inc_defconfig
TARGET_KERNEL_ARCH := arm64
TARGET_KERNEL_HEADER_ARCH := arm64
TARGET_KERNEL_VERSION := 3.18
TARGET_KERNEL_CLANG_COMPILE := false
BOARD_KERNEL_IMAGE_NAME := Image.gz-dtb
BOARD_KERNEL_BASE := 0x40078000
BOARD_KERNEL_OFFSET := 0x00008000
BOARD_RAMDISK_OFFSET := 0x04f88000
BOARD_KERNEL_TAGS_OFFSET := 0x03f88000
BOARD_SECOND_OFFSET := 0x00e88000
BOARD_KERNEL_PAGESIZE := 2048
BOARD_BOOT_HEADER_VERSION := 0
BOARD_MKBOOTIMG_ARGS := --kernel_offset $(BOARD_KERNEL_OFFSET) \
    --ramdisk_offset $(BOARD_RAMDISK_OFFSET) \
    --second_offset $(BOARD_SECOND_OFFSET) \
    --tags_offset $(BOARD_KERNEL_TAGS_OFFSET) \
    --header_version $(BOARD_BOOT_HEADER_VERSION)

# LK keeps only the first 99 characters of this, and adds
# androidboot.hardware=mt6797 itself.
BOARD_KERNEL_CMDLINE := bootopt=64S3,32N2,64N2
# SELinux is enforcing (no androidboot.selinux). For debugging, append
# androidboot.selinux=permissive here; the kernel has SELINUX_DEVELOP.
# The odmdtbo overlay carries an early-mount fstab that forces dm-verity on
# system and vendor. Point init at a directory that does not exist so it uses
# the ramdisk fstab.
BOARD_KERNEL_CMDLINE += androidboot.android_dt_dir=/x/

# Partitions: A-only, no dynamic partitions, sizes from the GPT.
BOARD_BOOTIMAGE_PARTITION_SIZE := 16777216
BOARD_SYSTEMIMAGE_PARTITION_SIZE := 2684354560
BOARD_VENDORIMAGE_PARTITION_SIZE := 687865856
BOARD_CACHEIMAGE_PARTITION_SIZE := 452984832
BOARD_FLASH_BLOCK_SIZE := 131072
AB_OTA_UPDATER := false

TARGET_COPY_OUT_VENDOR := vendor
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_CACHEIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_USERDATAIMAGE_FILE_SYSTEM_TYPE := ext4
TARGET_USERIMAGES_USE_EXT4 := true
BOARD_HAS_LARGE_FILESYSTEM := true

# TWRP stays in the recovery partition.
TARGET_NO_RECOVERY := true
BOARD_BUILD_SYSTEM_ROOT_IMAGE := false
BOARD_USES_RECOVERY_AS_BOOT := false

# Display
TARGET_SCREEN_WIDTH := 1536
TARGET_SCREEN_HEIGHT := 2048
TARGET_SCREEN_DENSITY := 320

# Treble
PRODUCT_FULL_TREBLE_OVERRIDE := true
BOARD_VNDK_VERSION := current

# VINTF
DEVICE_MANIFEST_FILE := $(DEVICE_PATH)/manifest.xml

# Properties
TARGET_SYSTEM_PROP += $(DEVICE_PATH)/system.prop
TARGET_VENDOR_PROP += $(DEVICE_PATH)/vendor.prop

# SELinux. sepolicy/stock is the stock Android 8 MediaTek vendor policy ported
# by tools/port_stock_sepolicy.py; sepolicy/vendor holds the hand-written
# additions. Some ported rules break Android 13 neverallows.
SELINUX_IGNORE_NEVERALLOWS := true
BOARD_VENDOR_SEPOLICY_DIRS += $(DEVICE_PATH)/sepolicy/stock $(DEVICE_PATH)/sepolicy/vendor

# Bluetooth
BOARD_HAVE_BLUETOOTH := true

# Graphics: the MTK vendor usage bit 26 must pass the gralloc0 adapter.
TARGET_ADDITIONAL_GRALLOC_10_USAGE_BITS ?= 0
TARGET_ADDITIONAL_GRALLOC_10_USAGE_BITS += | (1 << 26)

TARGET_OTA_ASSERT_DEVICE := x970_t10_97inc

# Vendor
include vendor/voyo/x970_t10_97inc/BoardConfigVendor.mk
