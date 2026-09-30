LOCAL_PATH := $(call my-dir)

ifeq ($(TARGET_DEVICE),szj202)
include $(call all-makefiles-under,$(LOCAL_PATH))
endif
