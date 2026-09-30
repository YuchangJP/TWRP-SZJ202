#
# Common device configuration for the KYOCERA SZJ-JS202 (szj202).
#

LOCAL_PATH := device/kyocera/szj202

PRODUCT_PROPERTY_OVERRIDES += \
    ro.sf.lcd_density=160

# adbd must not wait for an authorised key; this is a recovery build.
# Must be the product-scoped variable: build/make/core/main.mk hard-errors if
# ADDITIONAL_DEFAULT_PROPERTIES is already set when it reads the products.
PRODUCT_DEFAULT_PROPERTY_OVERRIDES += \
    ro.adb.secure=0

# Pick up recovery/root/ files from this device directory.
TARGET_RECOVERY_DEVICE_DIRS += $(LOCAL_PATH)
