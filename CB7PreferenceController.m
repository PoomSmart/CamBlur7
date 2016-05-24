#import <UIKit/UIKit.h>
#import <Preferences/Preferences.h>
#import <Preferences/PSListController.h>
#import <Social/Social.h>
#import "NKOColorPickerView.h"
#import <dlfcn.h>
#import "Common.h"
#import "../PS.h"

NSString *updateCellColorNotification = @"com.PS.CamBlur7.prefs.colorUpdate";
NSString *IdentifierKey = @"CB7ColorCellIdentifier";

__attribute__((visibility("hidden")))
@interface CB7PreferenceController : PSListController
@end

@interface CB7ColorPickerViewController : UIViewController
@property (retain) UIColor *color;
@property (retain) NSString *identifier;
@end

@interface PSSwitchTableCell : PSControlTableCell
@end

@interface CB7ColorCell : PSTableCell
@end

static NSDictionary *prefDict()
{
	return [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
}

static int integerValueForKey(NSString *key, int defaultValue)
{
	NSDictionary *pref = prefDict();
	return pref[key] ? [pref[key] intValue] : defaultValue;
}

static void writeIntegerValueForKey(int value, NSString *key)
{
	NSMutableDictionary *dict = [prefDict() mutableCopy] ?: [NSMutableDictionary dictionary];
	[dict setObject:@(value) forKey:key];
	BOOL write = [dict writeToFile:PREF_PATH atomically:NO];
	if (write)
		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), PreferencesChangedNotification, NULL, NULL, YES);
}

static UIColor *savedCustomColor(NSString *identifier)
{
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
	NSString *hueKey = [@"Hue" stringByAppendingString:identifier];
	NSString *satKey = [@"Sat" stringByAppendingString:identifier];
	NSString *briKey = [@"Bri" stringByAppendingString:identifier];
	if (dict[hueKey] == nil || dict[satKey] == nil|| dict[briKey] == nil)
		return [UIColor blackColor];
	CGFloat hue, sat, bri;
	#if CGFLOAT_IS_DOUBLE
	hue = [dict[hueKey] doubleValue];
	sat = [dict[satKey] doubleValue];
	bri = [dict[briKey] doubleValue];
	#else
	hue = [dict[hueKey] floatValue];
	sat = [dict[satKey] floatValue];
	bri = [dict[briKey] floatValue];
	#endif
	UIColor *color = [UIColor colorWithHue:hue saturation:sat brightness:bri alpha:1];
	return color;
}

@implementation CB7ColorCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(id)identifier specifier:(PSSpecifier *)specifier
{
	if (self == [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier specifier:specifier]) {
		NSString *identifier = [specifier identifier];
		[self updateColorCellForIdentifier:identifier];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateColorCell:) name:updateCellColorNotification object:nil];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
	return self;
}

- (UIView *)colorCellForIdentifier:(NSString *)identifier
{
	UIView *circle = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 28.0, 28.0)];
	circle.layer.cornerRadius = 14.0f;
	circle.backgroundColor = savedCustomColor(identifier);
	return circle;
}

- (void)updateColorCell:(NSNotification *)notification
{
	NSString *identifier = notification.userInfo[IdentifierKey];
	if (identifier == [self.specifier identifier])
		[self updateColorCellForIdentifier:identifier];
}

- (void)updateColorCellForIdentifier:(NSString *)identifier
{
	[self setAccessoryView:[[self colorCellForIdentifier:identifier] retain]];
	[[self titleTextLabel] setTextColor:savedCustomColor(identifier)];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

@end

@interface PSXSwitchTableCell : PSSwitchTableCell
@end
 
@implementation PSXSwitchTableCell
 
- (id)initWithStyle:(NSInteger)style reuseIdentifier:(id)identifier specifier:(id)spec
{
	self = [super initWithStyle:style reuseIdentifier:identifier specifier:spec];
	if (self)
		((UISwitch *)[self control]).onTintColor = [UIColor systemBlueColor];
	return self;
}
 
@end

@interface BlurQualityCell : PSTableCell
@end

@implementation BlurQualityCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(id)identifier specifier:(PSSpecifier *)specifier
{
	if (self == [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier specifier:specifier]) {
		UISegmentedControl *modes = [[[UISegmentedControl alloc] initWithItems:@[@"Default", @"Low"]] autorelease];
		[modes addTarget:self action:@selector(modeAction:) forControlEvents:UIControlEventValueChanged];
		modes.selectedSegmentIndex = integerValueForKey(QualityKey, 0);
		[self setAccessoryView:modes];
	}
	return self;
}

- (void)modeAction:(UISegmentedControl *)segment
{
	writeIntegerValueForKey(segment.selectedSegmentIndex, QualityKey);
}

- (SEL)action
{
	return nil;
}

- (id)target
{
	return nil;
}

- (SEL)cellAction
{
	return nil;
}

- (id)cellTarget
{
	return nil;
}

- (void)dealloc
{
	[super dealloc];
}

@end

@implementation CB7ColorPickerViewController

- (void)colorDidChange:(UIColor *)color identifier:(NSString *)identifier
{
	self.color = color;
	self.identifier = identifier;
}

- (UIColor *)savedCustomColor:(NSString *)identifier
{
	return savedCustomColor(identifier);
}

- (id)initWithIdentifier:(NSString *)identifier
{
	if (self == [super init]) {
		NKOColorPickerView *colorPickerView = [[[NKOColorPickerView alloc] initWithFrame:CGRectMake(0.0, 0.0, 300.0, 340.0) color:[[self savedCustomColor:identifier] retain] identifier:identifier delegate:self] autorelease];
		colorPickerView.backgroundColor = [UIColor blackColor];
		self.view = colorPickerView;
		self.navigationItem.title = @"Select Color";
		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:0 target:self action:@selector(dismissPicker)] autorelease];
	}
	return self;
}

- (void)dismissPicker
{
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	[dict addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:PREF_PATH]];
    CGFloat hue, sat, bri;
    NSString *identifier = self.identifier;
    BOOL getColor = [self.color getHue:&hue saturation:&sat brightness:&bri alpha:nil];
    if (getColor) {
    	NSString *hueKey = [@"Hue" stringByAppendingString:identifier];
		NSString *satKey = [@"Sat" stringByAppendingString:identifier];
		NSString *briKey = [@"Bri" stringByAppendingString:identifier];
		[dict setObject:@(hue) forKey:hueKey];
		[dict setObject:@(sat) forKey:satKey];
		[dict setObject:@(bri) forKey:briKey];
		BOOL write = [dict writeToFile:PREF_PATH atomically:NO];
		if (write) {
			CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), PreferencesChangedNotification, NULL, NULL, YES);
			[[NSNotificationCenter defaultCenter] postNotificationName:updateCellColorNotification object:nil userInfo:@{IdentifierKey:identifier}];
		}
	}
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
	if (twitter != nil)
		[[self navigationController] presentViewController:twitter animated:YES completion:nil];
	[twitter release];
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

- (id)readPreferenceValue:(PSSpecifier *)specifier
{
	NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
	if (!settings[specifier.properties[@"key"]])
		return specifier.properties[@"default"];
	return settings[specifier.properties[@"key"]];
}
 
- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier
{
	NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
	[defaults addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:PREF_PATH]];
	[defaults setObject:value forKey:specifier.properties[@"key"]];
	[defaults writeToFile:PREF_PATH atomically:YES];
	CFStringRef post = (CFStringRef)specifier.properties[@"PostNotification"];
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), post, NULL, NULL, YES);
}

- (NSArray *)specifiers
{
	if (_specifiers == nil) {
		NSMutableArray *specs = [NSMutableArray arrayWithArray:[self loadSpecifiersFromPlistName:@"CamBlur7" target:self]];
		if (IPAD) {
			if (dlopen("/Library/MobileSubstrate/DynamicLibraries/FrontFlash.dylib", RTLD_LAZY) != NULL) {
				for (NSUInteger i = 0; i < specs.count; i++) {
					PSSpecifier *spec = specs[i];
					NSString *Id = [spec identifier];
					if ([Id hasPrefix:@"topBar"])
						[specs removeObjectAtIndex:i];
				}
			}
		}
		_specifiers = [specs copy];
	}
	return _specifiers;
}

@end