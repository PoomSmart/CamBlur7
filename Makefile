GO_EASY_ON_ME = 1
SDKVERSION = 7.0
ARCHS = armv7 armv7s arm64

include theos/makefiles/common.mk
TWEAK_NAME = CamBlur7
CamBlur7_FILES = Tweak.xm CKBlurView.m
CamBlur7_FRAMEWORKS = UIKit CoreGraphics
CamBlur7_PRIVATE_FRAMEWORKS = QuartzCore

include $(THEOS_MAKE_PATH)/tweak.mk
	
BUNDLE_NAME = CamBlur7Settings
CamBlur7Settings_FILES = CB7PreferenceController.m
CamBlur7Settings_INSTALL_PATH = /Library/PreferenceBundles
CamBlur7Settings_PRIVATE_FRAMEWORKS = Preferences
CamBlur7Settings_FRAMEWORKS = UIKit

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/CamBlur7.plist$(ECHO_END)
	$(ECHO_NOTHING)find $(THEOS_STAGING_DIR) -name .DS_Store | xargs rm -rf$(ECHO_END)


