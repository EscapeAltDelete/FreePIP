TARGET = iphone:clang:latest:15.0
ARCHS = arm64 arm64e
THEOS_PACKAGE_SCHEME = rootless

# Optimization flags
DEBUG = 0
FINALPACKAGE = 1

# Inject into SpringBoard (Physics) and UIKit (Apps like YouTube/Safari for Limits)
FILTER_BUNDLES = com.apple.springboard com.apple.UIKit

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = FreePIP

FreePIP_FILES = Tweak.x
FreePIP_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk