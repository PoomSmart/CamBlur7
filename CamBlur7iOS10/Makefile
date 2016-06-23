GO_EASY_ON_ME = 1
TARGET = iphone:latest
ARCHS = armv7s arm64

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = CamBlur7iOS10
CamBlur7iOS10_FILES = Tweak.xm ../CKCB7BlurView.m
CamBlur7iOS10_FRAMEWORKS = CoreGraphics UIKit
CamBlur7iOS10_PRIVATE_FRAMEWORKS = QuartzCore
CamBlur7iOS10_LIBRARIES = substrate
CamBlur7iOS10_INSTALL_PATH = /Library/Application Support/CamBlur7

include $(THEOS_MAKE_PATH)/library.mk
