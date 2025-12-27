# Enforce Rootless Scheme
THEOS_PACKAGE_SCHEME = rootless

INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = FreePIP

# Target the latest SDK available, with a minimum iOS version of 15.0
TARGET = iphone:clang:latest:15.0

# Rootless only supports 64-bit arm
ARCHS = arm64 arm64e

FreePIP_FILES = Tweak.x
FreePIP_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk