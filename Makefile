ifdef SIMULATOR
	TARGET = simulator:clang:latest:8.0
else
	TARGET = iphone:clang:latest:7.0
	ifeq ($(debug),0)
		ARCHS= armv7 arm64 arm64e
	else
		ARCHS= arm64 arm64e
	endif
endif

TWEAK_NAME = SwipeSelection
SwipeSelection_CFLAGS = -fobjc-arc
SwipeSelection_FILES = Tweak.xm
SwipeSelection_FRAMEWORKS = UIKit Foundation CoreGraphics

ADDITIONAL_CFLAGS += -Wno-error=unused-variable -Wno-error=unused-function

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tweak.mk


after-install::
	install.exec "killall -9 SpringBoard"
