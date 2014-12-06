#import "Backdrop.h"
#import "CKCB7BlurView.h"
#import "Common.h"
#import "../PS.h"
#import <CoreGraphics/CoreGraphics.h>

static CKCB7BlurView *blurBar = nil;
static CKCB7BlurView *blurBar2 = nil;
static _UIBackdropView *backdropBar = nil;
static _UIBackdropView *backdropBar2 = nil;

static BOOL useBackdrop;

static BOOL blur;
static BOOL blurTop;
static BOOL blurBottom;
static BOOL handleEffectTB, handlePanoTB, handleVideoTB;
static BOOL handleEffectBB, handlePanoBB, handleVideoBB;

static CGFloat blurAmount;
static CGFloat HuetopBar, SattopBar, BritopBar;
static CGFloat HuebottomBar, SatbottomBar, BribottomBar;

static NSString *quality = CKBlurViewQualityDefault;

static void loadPrefs()
{
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
	#define BoolOpt(option) \
		option = dict[[NSString stringWithUTF8String:#option]] ? [dict[[NSString stringWithUTF8String:#option]] boolValue] : YES;
	#define FloatOpt(option) \
		option = dict[[NSString stringWithUTF8String:#option]] ? [dict[[NSString stringWithUTF8String:#option]] floatValue] : 0.35f;
	BoolOpt(blur)
	BoolOpt(blurTop)
	BoolOpt(blurBottom)
	useBackdrop = dict[@"useBackdrop"] ? [dict[@"useBackdrop"] boolValue] : NO;
	BoolOpt(handleEffectTB)
	BoolOpt(handleEffectBB)
	BoolOpt(handleVideoTB)
	BoolOpt(handleVideoBB)
	BoolOpt(handlePanoTB)
	BoolOpt(handlePanoBB)
	FloatOpt(HuetopBar)
	FloatOpt(SattopBar)
	FloatOpt(BritopBar)
	FloatOpt(HuebottomBar)
	FloatOpt(SatbottomBar)
	FloatOpt(BribottomBar)
	int value = dict[QualityKey] != nil ? [dict[QualityKey] intValue] : 0;
	quality = value == 1 ? CKBlurViewQualityLow : CKBlurViewQualityDefault;
	blurAmount = dict[@"blurAmount"] ? [dict[@"blurAmount"] floatValue] : 20.0f;
}

static void setBlurBarColor(id bar, BOOL top)
{
	UIColor *blurTint = nil;
	if (top)
		blurTint = [UIColor colorWithHue:HuetopBar saturation:SattopBar brightness:BritopBar alpha:1];
	else
		blurTint = [UIColor colorWithHue:HuebottomBar saturation:SatbottomBar brightness:BribottomBar alpha:1];
	if ([NSStringFromClass([bar class]) isEqualToString:@"_UIBackdropView"]) {
		[((_UIBackdropView *)bar).inputSettings setColorTint:blurTint];
		[((_UIBackdropView *)bar).outputSettings setColorTint:blurTint];
	} else {
		const CGFloat *rgb = CGColorGetComponents(blurTint.CGColor);
    	CAFilter *tintFilter = [CAFilter filterWithName:@"colorAdd"];
		[tintFilter setValue:@[@(rgb[0]), @(rgb[1]), @(rgb[2]), @(CGColorGetAlpha(blurTint.CGColor))] forKey:@"inputColor"];
		[(CKCB7BlurView *)bar setTintColorFilter:tintFilter];
	}
}

static _UIBackdropViewSettings *backdropBlurSettings()
{
	_UIBackdropViewSettings *settings = [_UIBackdropViewSettings settingsForStyle:0];
	[settings setUsesColorTintView:YES];
	[settings setColorTintAlpha:0.5f];
	[settings setRequiresColorStatistics:YES];
	[settings setBlurRadius:blurAmount];
	[settings setBlurQuality:quality];
	return settings;
}

static void layoutBlurBar(CGRect frame)
{
	if (blurTop) {
		blurBar.frame = frame;
		blurBar.blurCroppingRect = frame;
	}
}

static void createBlurBarWithFrame(CGRect frame)
{
	blurBar = [[CKCB7BlurView alloc] initWithFrame:frame];
	blurBar.blurRadius = blurAmount;
	layoutBlurBar(frame);
	[blurBar setBlurQuality:quality];
	setBlurBarColor(blurBar, YES);
}

static void layoutBlurBar2(CGRect frame)
{
	if (blurBottom) {
		blurBar2.frame = frame;
		blurBar2.blurCroppingRect = frame;
	}
}

static void createBlurBar2WithFrame(CGRect frame)
{
	blurBar2 = [[CKCB7BlurView alloc] initWithFrame:frame];
	blurBar2.blurRadius = blurAmount;
	layoutBlurBar2(frame);
	[blurBar2 setBlurQuality:quality];
	setBlurBarColor(blurBar2, NO);
}

static void createBackdropBar()
{
	backdropBar = [[_UIBackdropView alloc] initWithFrame:CGRectZero autosizesToFitSuperview:YES settings:backdropBlurSettings()];
	backdropBar.inputSettings.blurRadius = blurAmount;
	backdropBar.outputSettings.blurRadius = blurAmount;
	setBlurBarColor(backdropBar, YES);
}

static void createBackdropBar2()
{
	backdropBar2 = [[_UIBackdropView alloc] initWithFrame:CGRectZero autosizesToFitSuperview:YES settings:backdropBlurSettings()];
	backdropBar2.inputSettings.blurRadius = blurAmount;
	backdropBar2.outputSettings.blurRadius = blurAmount;
	setBlurBarColor(backdropBar2, NO);
}

static void releaseBlurBars()
{
	if (blurBar != nil) {
		[blurBar removeFromSuperview];
		[blurBar release];
		blurBar = nil;
	}
	if (backdropBar != nil) {
		[backdropBar removeFromSuperview];
		[backdropBar release];
		backdropBar = nil;
	}
}

static void releaseBlurBars2()
{
	if (blurBar2 != nil) {
		[blurBar2 removeFromSuperview];
		[blurBar2 release];
		blurBar2 = nil;
	}
	if (backdropBar2 != nil) {
		[backdropBar2 removeFromSuperview];
		[backdropBar2 release];
		backdropBar2 = nil;
	}
}

static void showBar(BOOL show)
{
	BOOL hide = !show;
	if (handleVideoTB) {
		blurBar.hidden = hide;
		backdropBar.hidden = hide;
	}
	if (handleVideoBB) {
		blurBar2.hidden = hide;
		backdropBar2.hidden = hide;
	}
}

%group CKCB7BlurView

%hook CAMTopBar

- (void)layoutSubviews
{
	%orig;
	CGRect frame = [self alignmentRectForFrame:self.bounds];
	layoutBlurBar(frame);
}

%end

%hook CAMBottomBar

- (void)_layoutForVerticalOrientation
{
	%orig;
	Class CameraController = isiOS8 ? objc_getClass("CAMCaptureController") : objc_getClass("PLCameraController");
	if (([[CameraController sharedInstance].effectsRenderer isShowingGrid] && handleEffectBB) || ([[CameraController sharedInstance] isCapturingVideo] && handleVideoBB))
		return;
	layoutBlurBar2(self.bounds);
}

- (void)_layoutForHorizontalOrientation
{
	%orig;
	Class CameraController = isiOS8 ? objc_getClass("CAMCaptureController") : objc_getClass("PLCameraController");
	if (([[CameraController sharedInstance].effectsRenderer isShowingGrid] && handleEffectBB) || ([[CameraController sharedInstance] isCapturingVideo] && handleVideoBB))
		return;
	UIView *backgroundView = isiOS8Up ? MSHookIvar<UIView *>(self, "_backgroundView") : self;
	layoutBlurBar2(backgroundView.bounds);
}

%end

%end

%group Common

%hook CAMTopBar

- (void)_commonCAMTopBarInitialization
{
	%orig;
	if (!blurTop)
		return;
	UIView *backgroundView = MSHookIvar<UIView *>(self, "__backgroundView");
	if (useBackdrop) {
		createBackdropBar();
		[backgroundView addSubview:backdropBar];
	} else {
		createBlurBarWithFrame(CGRectZero);
		[backgroundView addSubview:blurBar];
	}
}

- (void)dealloc
{
	releaseBlurBars();
	%orig;
}

%end

%hook CAMBottomBar

- (void)_commonCAMBottomBarInitialization
{
	%orig;
	if (!blurBottom)
		return;
	UIView *backgroundView = isiOS8Up ? MSHookIvar<UIView *>(self, "_backgroundView") : self;
	if (useBackdrop) {
		createBackdropBar2();
		[backgroundView addSubview:backdropBar2];
    } else {
    	createBlurBar2WithFrame(CGRectZero);
		[backgroundView addSubview:blurBar2];
    }
}

- (void)dealloc
{
	releaseBlurBars2();
	%orig;
}

%end

%end

%group preiOS8

%hook PLCameraView

- (void)_showControlsForCapturingVideoAnimated:(BOOL)capturingVideoAnimated
{
	showBar(NO);
	%orig;
}

- (void)_hideControlsForCapturingVideoAnimated:(BOOL)capturingVideoAnimated
{
	%orig;
	showBar(YES);
}

- (void)cameraController:(id)controller didStartTransitionToShowEffectsGrid:(BOOL)showEffectsGrid animated:(BOOL)animated
{
	%orig;
	showBar(!showEffectsGrid);
}

- (void)_showControlsForCapturingPanoramaAnimated:(BOOL)capturingPanoramaAnimated
{
	showBar(NO);
	%orig;
}

- (void)_hideControlsForCapturingPanoramaAnimated:(BOOL)capturingPanoramaAnimated
{
	showBar(YES);
	%orig;
}

%end

%end

%group iOS8

%hook CAMBottomBar

- (void)_setupHorizontalShutterButtonConstraints
{
	%orig;
	if (self.modeDial == nil) {
		NSArray *constraints = [self cam_constraintsForKey:@"CAMShutterButton"];
		[self cam_removeAllConstraintsForKey:@"CAMShutterButton"];
		NSMutableArray *newConstraints = [NSMutableArray array];
		[newConstraints addObjectsFromArray:constraints];
		CAMShutterButton *shutterButton = [self.shutterButton retain];
		UIView *spacer = [[self _shutterButtomBottomLayoutSpacer] retain];
		NSMutableArray *deleteConstraints = [NSMutableArray array];
		for (NSLayoutConstraint *layout in newConstraints) {
			if (layout.firstItem == shutterButton && layout.firstAttribute == NSLayoutAttributeBottom)
				[deleteConstraints addObject:layout];
		}
		if (deleteConstraints.count > 0) {
			for (NSLayoutConstraint *layout in deleteConstraints) {
				[newConstraints removeObject:layout];
			}
		}
		[self retain];
		NSLayoutConstraint *centerY = [[NSLayoutConstraint constraintWithItem:shutterButton attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1.0f constant:-4.5f] retain];
		[newConstraints addObject:centerY];
		[self cam_addConstraints:newConstraints forKey:@"CAMShutterButton"];
		[self release];
		[centerY release];
		[spacer release];
		[shutterButton release];
	}
}

%end

%hook CAMCameraView

- (void)_showControlsForCapturingVideoAnimated:(BOOL)capturingVideoAnimated
{
	showBar(NO);
	%orig;
}

- (void)_hideControlsForCapturingVideoAnimated:(BOOL)capturingVideoAnimated
{
	%orig;
	showBar(YES);
}

- (void)cameraController:(id)controller didStartTransitionToShowEffectsGrid:(BOOL)showEffectsGrid animated:(BOOL)animated
{
	%orig;
	showBar(!showEffectsGrid);
}

- (void)_showControlsForCapturingPanoramaAnimated:(BOOL)capturingPanoramaAnimated
{
	showBar(NO);
	%orig;
}

- (void)_hideControlsForCapturingPanoramaAnimated:(BOOL)capturingPanoramaAnimated
{
	showBar(YES);
	%orig;
}

- (void)_showControlsForCapturingTimelapseAnimated:(BOOL)capturingTimelapseAnimated
{
	showBar(NO);
	%orig;
}

- (void)_hideControlsForCapturingTimelapseAnimated:(BOOL)capturingTimelapseAnimated
{
	showBar(YES);
	%orig;
}

%end

%end

BOOL shouldInjectUIKit()
{
	BOOL inject = NO;
	NSArray *args = [[NSClassFromString(@"NSProcessInfo") processInfo] arguments];
	NSUInteger count = [args count];
	if (count != 0) {
		NSString *executablePath = [args objectAtIndex:0];
		if (executablePath) {
			NSString *processName = [executablePath lastPathComponent];
			BOOL isApplication = [executablePath rangeOfString:@"/Application"].location != NSNotFound;
			BOOL isSpringBoard = [processName isEqualToString:@"SpringBoard"];
			BOOL isMail = [processName isEqualToString:@"MobileMail"];
			BOOL isPref = [processName isEqualToString:@"Preferences"];
			BOOL notOkay = isMail || isPref;
			inject = (isApplication || isSpringBoard) && !notOkay;
		}
	}
	return inject;
}

static void PostNotification(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	system("killall Camera");
	loadPrefs();
}

%ctor
{
	if (!shouldInjectUIKit())
		return;
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PostNotification, PreferencesChangedNotification, NULL, CFNotificationSuspensionBehaviorCoalesce);
	loadPrefs();
	if (blur) {
		dlopen("/System/Library/PrivateFrameworks/PhotoLibrary.framework/PhotoLibrary", RTLD_LAZY);
		dlopen("/System/Library/PrivateFrameworks/CameraKit.framework/CameraKit", RTLD_LAZY);
		if (isiOS8) {
			%init(iOS8);
		}
		else if (isiOS7) {
			%init(preiOS8);
		}
		%init(Common);
		if (!useBackdrop) {
			%init(CKCB7BlurView);
		}
	}
	[pool drain];
}
