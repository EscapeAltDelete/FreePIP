# Enforce Rootless Scheme for NathanLR/Dopamine
THEOS_PACKAGE_SCHEME = rootless

INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = FreePIP

# Use latest SDK, set minimum deployment to iOS 15.0
TARGET = iphone:clang:latest:15.0

# Rootless only supports 64-bit arm
ARCHS = arm64 arm64e

FreePIP_FILES = Tweak.x
FreePIP_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk