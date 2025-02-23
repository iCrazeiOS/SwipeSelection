TARGET = iphone:clang:latest:7.0
ifeq ($(debug),0)
	ARCHS= armv7 armv7s arm64 arm64e
else
	ARCHS= arm64 arm64e
endif

TWEAK_NAME = SwipeSelection
SwipeSelection_CFLAGS = -fobjc-arc
SwipeSelection_FILES = Tweak.xm SSPanGestureRecognizer.m
SwipeSelection_FRAMEWORKS = UIKit

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
