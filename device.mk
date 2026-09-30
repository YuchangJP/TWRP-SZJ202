#
# Common device configuration for the KYOCERA SZJ-JS202 (szj202).
#

LOCAL_PATH := device/kyocera/szj202

PRODUCT_PROPERTY_OVERRIDES += \
    ro.sf.lcd_density=160

# adbd must not wait for an authorised key; this is a recovery build.
# Must live here (not in BoardConfig.mk): build/make/core/main.mk rejects
# ADDITIONAL_DEFAULT_PROPERTIES being set before the product makefiles.
ADDITIONAL_DEFAULT_PROPERTIES += \
    ro.adb.secure=0

# Pick up recovery/root/ files from this device directory.
TARGET_RECOVERY_DEVICE_DIRS += $(LOCAL_PATH)
