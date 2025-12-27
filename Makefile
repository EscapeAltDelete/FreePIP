# Enforce Rootless Scheme for NathanLR
THEOS_PACKAGE_SCHEME = rootless

INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = FreePIP

# Use latest SDK, target iOS 15.0+ (Required for Rootless)
TARGET = iphone:clang:latest:15.0

# Rootless architectures
ARCHS = arm64 arm64e

FreePIP_FILES = Tweak.x
FreePIP_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk