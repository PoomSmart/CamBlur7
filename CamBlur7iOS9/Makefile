GO_EASY_ON_ME = 1
ARCHS = armv7 arm64

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = CamBlur7iOS9
CamBlur7iOS9_FILES = Tweak.xm ../CKCB7BlurView.m
CamBlur7iOS9_FRAMEWORKS = CoreGraphics UIKit
CamBlur7iOS9_PRIVATE_FRAMEWORKS = QuartzCore
CamBlur7iOS9_LIBRARIES = substrate
CamBlur7iOS9_INSTALL_PATH = /Library/Application Support/CamBlur7

include $(THEOS_MAKE_PATH)/library.mk
