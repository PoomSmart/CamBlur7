#import <UIKit/UIKit.h>
#import <Preferences/Preferences.h>

__attribute__((visibility("hidden")))
@interface CB7PreferenceController : PSListController
- (id)specifiers;
@end

@implementation CB7PreferenceController

- (void)donate:(id)param
{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=GBQGZL8EFMM86"]];
}

- (id)specifiers {
	if (_specifiers == nil) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"CamBlur7" target:self] retain];
  }
	return _specifiers;
}

@end
