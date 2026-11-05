#
# SPDX-License-Identifier: Apache-2.0
#

# zygote64_32: the Mali and media blobs ship both ABIs.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

$(call inherit-product, vendor/lineage/config/common_full_tablet.mk)

$(call inherit-product, device/voyo/x970_t10_97inc/device.mk)

# Shipped with Android 8.0. Must come after device.mk: the last inherit wins.
$(call inherit-product, $(SRC_TARGET_DIR)/product/product_launched_with_o.mk)

PRODUCT_DEVICE := x970_t10_97inc
PRODUCT_NAME := lineage_x970_t10_97inc
BOARD_VENDOR := voyo
PRODUCT_BRAND := VOYO
PRODUCT_MODEL := i8
PRODUCT_MANUFACTURER := VOYO
TARGET_VENDOR := voyo

PRODUCT_GMS_CLIENTID_BASE := android-voyo

PRODUCT_BUILD_PROP_OVERRIDES += \
    PRIVATE_BUILD_DESC="full_x970_t10_97inc-user 8.0.0 O00623 1543910289 release-keys"

BUILD_FINGERPRINT := "VOYO/full_x970_t10_97inc/x970_t10_97inc:8.0.0/O00623/1543910289:user/release-keys"
