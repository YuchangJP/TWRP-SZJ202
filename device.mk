#
# Common device configuration for the KYOCERA SZJ-JS202 (szj202).
#

LOCAL_PATH := device/kyocera/szj202

PRODUCT_PROPERTY_OVERRIDES += \
    ro.sf.lcd_density=160

# Pick up recovery/root/ files from this device directory.
TARGET_RECOVERY_DEVICE_DIRS += $(LOCAL_PATH)
