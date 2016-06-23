GO_EASY_ON_ME = 1
TARGET = iphone:latest
ARCHS = armv7 arm64

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = CamBlur7iOS8
CamBlur7iOS8_FILES = Tweak.xm ../CKCB7BlurView.m
CamBlur7iOS8_FRAMEWORKS = CoreGraphics UIKit
CamBlur7iOS8_PRIVATE_FRAMEWORKS = QuartzCore
CamBlur7iOS8_LIBRARIES = substrate
CamBlur7iOS8_INSTALL_PATH = /Library/Application Support/CamBlur7

include $(THEOS_MAKE_PATH)/library.mk
