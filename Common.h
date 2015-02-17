#import "../PS.h"

CFStringRef const tweak = CFSTR("com.PS.CamBlur7");
CFStringRef const PreferencesChangedNotification = CFSTR("com.PS.CamBlur7.prefs");
NSString *const PREF_PATH = @"/var/mobile/Library/Preferences/com.PS.CamBlur7.plist";
NSString *const QualityKey = @"Quality";

@interface CAMTopBar (CamBlur7)
- (void)updateSize:(CGRect)frame;
@end
