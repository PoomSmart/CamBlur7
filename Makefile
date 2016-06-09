GO_EASY_ON_ME = 1
ARCHS = armv7 arm64
DEBUG = 0
PACKAGE_VERSION = 1.6-1

include $(THEOS)/makefiles/common.mk

AGGREGATE_NAME = CamBlur7
SUBPROJECTS = CamBlur7iOS7 CamBlur7iOS8 CamBlur7iOS9

include $(THEOS_MAKE_PATH)/aggregate.mk

TWEAK_NAME = CamBlur7
CamBlur7_FILES = Tweak.xm

include $(THEOS_MAKE_PATH)/tweak.mk

BUNDLE_NAME = CamBlur7Settings
CamBlur7Settings_FILES = CB7PreferenceController.m NKOColorPickerView.m
CamBlur7Settings_INSTALL_PATH = /Library/PreferenceBundles
CamBlur7Settings_PRIVATE_FRAMEWORKS = Preferences
CamBlur7Settings_FRAMEWORKS = CoreGraphics Social UIKit
CamBlur7Settings_LIBRARIES = cephei cepheiprefs

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/CamBlur7.plist$(ECHO_END)
	$(ECHO_NOTHING)find $(THEOS_STAGING_DIR) -name .DS_Store | xargs rm -rf$(ECHO_END)
