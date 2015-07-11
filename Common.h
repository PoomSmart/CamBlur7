#import "../PS.h"

CFStringRef tweak = CFSTR("com.PS.CamBlur7");
CFStringRef PreferencesChangedNotification = CFSTR("com.PS.CamBlur7.prefs");
NSString *PREF_PATH = @"/var/mobile/Library/Preferences/com.PS.CamBlur7.plist";
NSString *QualityKey = @"Quality";

@interface CAMTopBar (CamBlur7)
- (void)updateSize:(CGRect)frame;
@end
