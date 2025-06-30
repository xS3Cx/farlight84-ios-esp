ARCHS = arm64
DEBUG = 0
FINALPACKAGE = 1
FOR_RELEASE = 1
THEOS_PACKAGE_SCHEME = rootless
THEOS_DEVICE_IP = 192.168.0.104
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = DBDM-Cheat

$(TWEAK_NAME)_FRAMEWORKS =  UIKit Foundation Security QuartzCore CoreGraphics CoreText  AVFoundation Accelerate GLKit SystemConfiguration GameController

$(TWEAK_NAME)_CCFLAGS = -Wno-deprecated-declarations -Wno-unused-variable -Wno-unused-value -std=c++11 -fno-rtti -fno-exceptions -DNDEBUG
$(TWEAK_NAME)_CFLAGS = -Wno-deprecated-declarations -Wno-unused-variable -Wno-unused-value -fobjc-arc

$(TWEAK_NAME)_FILES = ImGuiDrawView.mm $(wildcard Esp/*.mm) $(wildcard Esp/*.m) $(wildcard IMGUI/*.cpp) $(wildcard IMGUI/*.mm) $(wildcard Cheat/*.xm)

include $(THEOS_MAKE_PATH)/tweak.mk


