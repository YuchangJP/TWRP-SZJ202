#
# Product definition for TWRP on the KYOCERA SZJ-JS202 (szj202).
#

$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base.mk)
$(call inherit-product, device/kyocera/szj202/device.mk)

PRODUCT_NAME := omni_szj202
PRODUCT_DEVICE := szj202
PRODUCT_BRAND := JUSTSYSTEMS
PRODUCT_MANUFACTURER := KYOCERA
PRODUCT_MODEL := SZJ-JS202

TARGET_SCREEN_WIDTH := 800
TARGET_SCREEN_HEIGHT := 1280
