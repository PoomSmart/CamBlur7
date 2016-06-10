#import <UIKit/UIKit.h>
#import <Preferences/PSTableCell.h>
#import <Cephei/HBListController.h>
#import <Cephei/HBAppearanceSettings.h>
#import <Social/Social.h>
#import "NKOColorPickerView.h"
#import <dlfcn.h>
#import "Common.h"
#import "../PS.h"
#import "../PSPrefs.x"

DeclarePrefsTools()

NSString *updateCellColorNotification = @"com.PS.CamBlur7.prefs.colorUpdate";
NSString *IdentifierKey = @"CB7ColorCellIdentifier";

@interface CB7PreferenceController : HBListController
@end

@interface CB7ColorPickerViewController : UIViewController <NKOColorPickerViewDelegate>
@property (retain) UIColor *color;
@property (retain) NSString *identifier;
@end

@interface CB7ColorCell : PSTableCell
@end

static UIColor *savedCustomColor(NSString *identifier)
{
	NSString *hueKey = [@"Hue" stringByAppendingString:identifier];
	NSString *satKey = [@"Sat" stringByAppendingString:identifier];
	NSString *briKey = [@"Bri" stringByAppendingString:identifier];
	CGFloat hue, sat, bri;
	hue = floatForKey(hueKey, 1.0);
	sat = floatForKey(satKey, 1.0);
	bri = floatForKey(briKey, 1.0);
	UIColor *color = [UIColor colorWithHue:hue saturation:sat brightness:bri alpha:1];
	return color;
}

@implementation CB7ColorCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(id)identifier specifier:(PSSpecifier *)specifier
{
	if (self == [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier specifier:specifier]) {
		NSString *identifier = [specifier identifier];
		[self updateColorCellForIdentifier:identifier];
		[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(updateColorCell:) name:updateCellColorNotification object:nil];
	}
	return self;
}

- (UIView *)colorCellForIdentifier:(NSString *)identifier
{
	UIView *circle = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 28, 28)];
	circle.layer.cornerRadius = 14;
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
	self.accessoryView = [[self colorCellForIdentifier:identifier] retain];
	self.titleLabel.textColor = savedCustomColor(identifier);
}

- (void)dealloc
{
	[NSNotificationCenter.defaultCenter removeObserver:self];
	[super dealloc];
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
		modes.selectedSegmentIndex = intForKey(QualityKey, 0);
		self.accessoryView = modes;
	}
	return self;
}

- (void)modeAction:(UISegmentedControl *)segment
{
	setIntForKey(segment.selectedSegmentIndex, QualityKey);
	DoPostNotification();
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

HavePrefs()

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
		NKOColorPickerView *colorPickerView = [[[NKOColorPickerView alloc] initWithFrame:CGRectMake(0, 0, 300, 340) color:[[self savedCustomColor:identifier] retain] identifier:identifier delegate:self] autorelease];
		colorPickerView.backgroundColor = UIColor.blackColor;
		self.view = colorPickerView;
		self.navigationItem.title = @"Select Color";
		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:0 target:self action:@selector(dismissPicker)] autorelease];
	}
	return self;
}

- (void)dismissPicker
{
    CGFloat hue, sat, bri;
    NSString *identifier = self.identifier;
    BOOL getColor = [self.color getHue:&hue saturation:&sat brightness:&bri alpha:nil];
    if (getColor) {
    	NSString *hueKey = [@"Hue" stringByAppendingString:identifier];
		NSString *satKey = [@"Sat" stringByAppendingString:identifier];
		NSString *briKey = [@"Bri" stringByAppendingString:identifier];
		setFloatForKey(hue, hueKey);
		setFloatForKey(sat, satKey);
		setFloatForKey(bri, briKey);
		DoPostNotification();
		[NSNotificationCenter.defaultCenter postNotificationName:updateCellColorNotification object:nil userInfo:@{ IdentifierKey : identifier }];
		system("killall Camera");
	}
	[self.parentViewController dismissViewControllerAnimated:YES completion:nil];
}

@end

@implementation CB7PreferenceController

HavePrefs()

- (void)masterSwitch:(id)value specifier:(PSSpecifier *)spec
{
	[self setPreferenceValue:value specifier:spec];
	system("killall Camera");
}

- (void)loadView
{
	[super loadView];
	UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 110)];
	UILabel *tweakLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 16, 320, 50)];
	tweakLabel.text = @"CamBlur7";
	tweakLabel.textColor = UIColor.systemOrangeColor;
	tweakLabel.backgroundColor = UIColor.clearColor;
	tweakLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:50.0];
	tweakLabel.textAlignment = 1;
	tweakLabel.autoresizingMask = 0x12;
	[headerView addSubview:tweakLabel];
	[tweakLabel release];
	UILabel *des = [[UILabel alloc] initWithFrame:CGRectMake(0, 75, 320, 20)];
	des.text = @"Blurry cool camera interface";
	des.textColor = UIColor.orangeColor;
	des.alpha = 0.8;
	des.font = [UIFont systemFontOfSize:14.0];
	des.backgroundColor = UIColor.clearColor;
	des.textAlignment = 1;
	des.autoresizingMask = 0xa;
	[headerView addSubview:des];
	[des release];
	self.table.tableHeaderView = headerView;
	[headerView release];
}

- (id)init
{
	if (self == [super init]) {
		HBAppearanceSettings *appearanceSettings = [[HBAppearanceSettings alloc] init];
		appearanceSettings.tintColor = UIColor.systemOrangeColor;
		appearanceSettings.tableViewCellTextColor = UIColor.systemOrangeColor;
		self.hb_appearanceSettings = appearanceSettings;
		UIButton *heart = [[[UIButton alloc] initWithFrame:CGRectZero] autorelease];
		[heart setImage:[[UIImage imageNamed:@"Heart" inBundle:[NSBundle bundleWithPath:@"/Library/PreferenceBundles/CamBlur7Settings.bundle"]] _flatImageWithColor:UIColor.systemOrangeColor] forState:UIControlStateNormal];
		[heart sizeToFit];
		[heart addTarget:self action:@selector(love) forControlEvents:UIControlEventTouchUpInside];
		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:heart] autorelease];
	}
	return self;
}

- (void)love
{
	SLComposeViewController *twitter = [[SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter] retain];
	twitter.initialText = @"#CamBlur7 by @PoomSmart is really awesome!";
	[self.navigationController presentViewController:twitter animated:YES completion:nil];
	[twitter release];
}

- (void)showColorPicker:(id)param
{
	NSString *identifier = [param identifier];
	CB7ColorPickerViewController *picker = [[[CB7ColorPickerViewController alloc] initWithIdentifier:identifier] autorelease];
	UINavigationController *nav = [[[UINavigationController alloc] initWithRootViewController:picker] autorelease];
	nav.modalPresentationStyle = 2;
	[self.navigationController presentViewController:nav animated:YES completion:nil];
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
		_specifiers = specs.copy;
	}
	return _specifiers;
}

@end