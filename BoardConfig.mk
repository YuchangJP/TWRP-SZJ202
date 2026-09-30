#
# Device tree for the KYOCERA SZJ-JS202 (JUSTSYSTEMS SZJ202), Qualcomm MSM8937.
#
# The stock kernel is reused so every OEM driver (touch, display, storage, RTC)
# behaves exactly as it does in the factory recovery. The device tree is not
# appended to the kernel: the bootloader applies the matching FDT from the
# separate dtbo partition, so recovery.img is kernel + TWRP ramdisk only.
#

DEVICE_PATH := device/kyocera/szj202
TARGET_DEVICE := szj202

# ------------------------------------------------------------------ Platform
BOARD_VENDOR := kyocera
TARGET_BOARD_PLATFORM := msm8937
TARGET_BOOTLOADER_BOARD_NAME := MSM8937

TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_VARIANT := cortex-a53

TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv7-a-neon
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 := armeabi
TARGET_2ND_CPU_VARIANT := cortex-a53

TARGET_CPU_SMP := true
TARGET_USES_64_BIT_BINDER := true
TARGET_SUPPORTS_64_BIT_APPS := true
TARGET_BOARD_SUFFIX := _64
BOARD_USES_QCOM_HARDWARE := true

# -------------------------------------------------------------------- Kernel
BOARD_KERNEL_IMAGE_NAME := Image.gz
TARGET_PREBUILT_KERNEL := $(DEVICE_PATH)/prebuilt/Image.gz

BOARD_KERNEL_BASE := 0x80000000
BOARD_KERNEL_PAGESIZE := 2048
BOARD_KERNEL_OFFSET := 0x00008000
BOARD_RAMDISK_OFFSET := 0x01000000
BOARD_KERNEL_TAGS_OFFSET := 0x00000100
BOARD_MKBOOTIMG_ARGS += --kernel_offset $(BOARD_KERNEL_OFFSET)
BOARD_MKBOOTIMG_ARGS += --ramdisk_offset $(BOARD_RAMDISK_OFFSET)
BOARD_MKBOOTIMG_ARGS += --tags_offset $(BOARD_KERNEL_TAGS_OFFSET)

# Byte-identical to the stock boot/recovery header cmdline, plus
# androidboot.selinux=permissive for bring-up: the configfs USB gadget is
# created from init before TWRP switches policy, and the stock recovery's
# policy is not ours.
BOARD_KERNEL_CMDLINE := console=ttyMSM0,115200,n8 androidboot.console=ttyMSM0 androidboot.hardware=qcom msm_rtb.filter=0x237 ehci-hcd.park=3 lpm_levels.sleep_disabled=1 androidboot.bootdevice=7824900.sdhci earlycon=msm_serial_dm,0x78B0000 firmware_class.path=/vendor/firmware_mnt/image androidboot.usbconfigfs=true loop.max_part=7 androidboot.selinux=permissive

# No dt image is packed; the bootloader reads /dtbo.
BOARD_KERNEL_SEPARATED_DT := false

# ---------------------------------------------------------------- Partitions
# Exact sizes from the device GPT (see docs/DEVICE.md).
BOARD_BOOTIMAGE_PARTITION_SIZE := 67108864
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 67108864
BOARD_SYSTEMIMAGE_PARTITION_SIZE := 2709520384
BOARD_VENDORIMAGE_PARTITION_SIZE := 671088640
BOARD_CACHEIMAGE_PARTITION_SIZE := 838860800
BOARD_USERDATAIMAGE_PARTITION_SIZE := 10783555584
BOARD_FLASH_BLOCK_SIZE := 131072

TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true
BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_CACHEIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_USERDATAIMAGE_FILE_SYSTEM_TYPE := ext4
TARGET_COPY_OUT_VENDOR := vendor

# ------------------------------------------------------------------- Recovery
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/recovery.fstab
TARGET_RECOVERY_PIXEL_FORMAT := "RGBX_8888"
TARGET_RECOVERY_DEVICE_DIRS += $(DEVICE_PATH)
TARGET_RECOVERY_QCOM_RTC_FIX := true
TARGET_OTA_ASSERT_DEVICE := szj202,SZJ202

# ----------------------------------------------------------------------- TWRP
# The panel is a native 800x1280 portrait DSI panel (kc boe ilitek wxga), so the
# drawing is rotated to get a 1280x800 landscape UI. `persist.twrp.rotation`
# overrides TW_ROTATION at runtime if 90 turns out to be the wrong direction.
TW_THEME := landscape_hdpi
TW_ROTATION := 90
# TWRP rotates the drawing but the touchscreen still reports panel-space
# coordinates, so the axes have to be swapped and one of them flipped. For
# gr_rotation == 90 the frame transform is (u, v) = (w - y - 1, x), i.e.
# x_ui = v and y_ui = (h - u), which is exactly SWAP_XY + FLIP_Y.
# If tapping lands mirrored, move the flip to RECOVERY_TOUCHSCREEN_FLIP_X
# (and if it is transposed as well, drop both flips).
RECOVERY_TOUCHSCREEN_SWAP_XY := true
RECOVERY_TOUCHSCREEN_FLIP_Y := true
TW_SCREEN_BLANK_ON_BOOT := true
TW_USE_TOOLBOX := true
# Do NOT set TW_EXCLUDE_DEFAULT_USB_INIT: TWRP's etc/init.recovery.usb.rc is
# what starts adbd on "sys.usb.config=adb". The configfs gadget itself is set
# up by this device's recovery/root/init.recovery.qcom.rc.
TW_EXCLUDE_TWRPAPP := true
TW_EXTRA_LANGUAGES := true
TW_DEFAULT_LANGUAGE := ja
# Crypto/FBE is on again. TWRP's KeyAuthentication::usesKeymaster() drops the
# '!' before secret.empty() compared with AOSP, so an empty authentication (the
# FBE device key) wrongly took the Keymaster path and deadlocked recovery, which
# has no Keymaster HAL. The build patches that back to the AOSP form, makes
# recovery create its own "e4crypt" keyring, and disables the wrapped-key retry
# so a failure cannot deadlock. See the workflow's patch step and
# docs/BUILD_STATUS.md.
TW_INCLUDE_CRYPTO := true
TW_USE_MODEL_HARDWARE_ID_FOR_DEVICE_ID := true
TW_DEVICE_VERSION := SZJ202-1
RECOVERY_SDCARD_ON_DATA := true
BOARD_HAS_NO_SELECT_BUTTON := true
