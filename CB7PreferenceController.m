#import <UIKit/UIKit.h>
#import <Preferences/Preferences.h>
#import <Social/Social.h>
#import "NKOColorPickerView.h"
#import <dlfcn.h>
#import "../PS.h"

@interface UIImage (Addition)
+ (UIImage *)imageNamed:(NSString *)name inBundle:(NSBundle *)bundle;
@end

#define PREF_PATH @"/var/mobile/Library/Preferences/com.PS.CamBlur7.plist"

__attribute__((visibility("hidden")))
@interface CB7PreferenceController : PSListController
@property (nonatomic, retain) PSSpecifier *blurTopSpec;
@property (nonatomic, retain) PSSpecifier *blurBottomSpec;
- (id)specifiers;
@end

@interface CB7ColorPickerViewController : UIViewController
@end

@implementation CB7ColorPickerViewController

NKOColorPickerDidChangeColorBlock colorDidChangeBlock = ^(UIColor *color, NSString *identifier){
    NSMutableDictionary *dict = [[NSMutableDictionary dictionaryWithContentsOfFile:PREF_PATH] mutableCopy] ?: [NSMutableDictionary dictionary];
    CGFloat hue, sat, bri;
    BOOL getColor = [color getHue:&hue saturation:&sat brightness:&bri alpha:nil];
    if (getColor) {
    	NSString *hueKey = [@"Hue" stringByAppendingString:identifier];
		NSString *satKey = [@"Sat" stringByAppendingString:identifier];
		NSString *briKey = [@"Bri" stringByAppendingString:identifier];
		[dict setObject:@(hue) forKey:hueKey];
		[dict setObject:@(sat) forKey:satKey];
		[dict setObject:@(bri) forKey:briKey];
		[dict writeToFile:PREF_PATH atomically:YES];
	}
};

- (UIColor *)savedCustomColor:(NSString *)identifier
{
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
	NSString *hueKey = [@"Hue" stringByAppendingString:identifier];
	NSString *satKey = [@"Sat" stringByAppendingString:identifier];
	NSString *briKey = [@"Bri" stringByAppendingString:identifier];
	if (dict[hueKey] == nil || dict[satKey] == nil|| dict[briKey] == nil)
		return [UIColor blackColor];
	CGFloat hue, sat, bri;
	hue = [dict[hueKey] floatValue];
	sat = [dict[satKey] floatValue];
	bri = [dict[briKey] floatValue];
	UIColor *color = [UIColor colorWithHue:hue saturation:sat brightness:bri alpha:1];
	return color;
}

- (id)initWithIdentifier:(NSString *)identifier
{
	if (self == [super init]) {
		NKOColorPickerView *colorPickerView = [[[NKOColorPickerView alloc] initWithFrame:CGRectMake(0, 0, 300, 340) color:[[self savedCustomColor:identifier] retain] identifier:identifier andDidChangeColorBlock:colorDidChangeBlock] autorelease];
		colorPickerView.backgroundColor = [UIColor blackColor];
		self.view = colorPickerView;
		self.navigationItem.title = @"Select Color";
		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:0 target:self action:@selector(dismissPicker)] autorelease];
	}
	return self;
}

- (void)dismissPicker
{
	[[self parentViewController] dismissViewControllerAnimated:YES completion:nil];
}

@end

@implementation CB7PreferenceController

- (id)init
{
	if (self == [super init]) {
		UIButton *heart = [[[UIButton alloc] initWithFrame:CGRectZero] autorelease];
		[heart setImage:[UIImage imageNamed:@"Heart" inBundle:[NSBundle bundleWithPath:@"/Library/PreferenceBundles/CamBlur7Settings.bundle"]] forState:UIControlStateNormal];
		[heart sizeToFit];
		[heart addTarget:self action:@selector(love) forControlEvents:UIControlEventTouchUpInside];
		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:heart] autorelease];
	}
	return self;
}

- (void)love
{
	SLComposeViewController *twitter = [[SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter] retain];
	[twitter setInitialText:@"#CamBlur7 by @PoomSmart is awesome!"];
	[[self navigationController] presentViewController:twitter animated:YES completion:nil];
}

- (void)showColorPicker:(id)param
{
	NSString *identifier = [param identifier];
	CB7ColorPickerViewController *picker = [[[CB7ColorPickerViewController alloc] initWithIdentifier:identifier] autorelease];
	UINavigationController *nav = [[[UINavigationController alloc] initWithRootViewController:picker] autorelease];
	nav.modalPresentationStyle = 2;
	[[self navigationController] presentViewController:nav animated:YES completion:nil];
}

- (void)donate:(id)param
{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:PS_DONATE_URL]];
}

- (void)twitter:(id)param
{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:PS_TWITTER_URL]];
}

- (id)specifiers {
	if (_specifiers == nil) {
		NSMutableArray *specs = [NSMutableArray arrayWithArray:[self loadSpecifiersFromPlistName:@"CamBlur7" target:self]];
		
		for (PSSpecifier *spec in specs) {
			NSString *Id = [[spec properties] objectForKey:@"id"];
			if ([Id isEqualToString:@"blurTop"])
				self.blurTopSpec = spec;
			else if ([Id isEqualToString:@"blurBottom"])
				self.blurBottomSpec = spec;
		}
		
		if (IPAD) {
			if (dlopen("/Library/MobileSubstrate/DynamicLibraries/FrontFlash.dylib", RTLD_LAZY | RTLD_NOLOAD) == NULL)
				[specs removeObject:self.blurTopSpec];
		}
		
		_specifiers = [specs copy];
	}
	return _specifiers;
}

@end
