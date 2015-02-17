#import <substrate.h>
#import <objc/runtime.h>
#import "Backdrop.h"
#import "CKCB7BlurView.h"
#import "Common.h"
#import "../PS.h"
#import <CoreGraphics/CoreGraphics.h>

@interface PLCameraView (CB7)
- (BOOL)cb7_shouldHideBlurryTopBarForMode:(NSInteger)mode;
@end

@interface CAMCameraView (CB7)
- (BOOL)cb7_shouldHideBlurryTopBarForMode:(NSInteger)mode;
@end

static CKCB7BlurView *blurBar = nil;
static CKCB7BlurView *blurBar2 = nil;
static _UIBackdropView *backdropBar = nil;
static _UIBackdropView *backdropBar2 = nil;

static BOOL useBackdrop;

static BOOL blur;
static BOOL blurTop;
static BOOL blurBottom;
static BOOL readable;
static BOOL handleEffectTB, handlePanoTB, handleVideoTB;
static BOOL handleEffectBB, handlePanoBB, handleVideoBB;

static CGFloat blurAmount;
static CGFloat HuetopBar, SattopBar, BritopBar;
static CGFloat HuebottomBar, SatbottomBar, BribottomBar;

static NSString *quality;

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
	readable = dict[@"readable"] ? [dict[@"readable"] boolValue] : NO;
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
	int value = dict[QualityKey] ? [dict[QualityKey] intValue] : 0;
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
		((_UIBackdropView *)bar).inputSettings.colorTint = blurTint;
		((_UIBackdropView *)bar).outputSettings.colorTint = blurTint;
	} else {
		const CGFloat *rgb = CGColorGetComponents(blurTint.CGColor);
    	CAFilter *tintFilter = [CAFilter filterWithName:@"colorAdd"];
		[tintFilter setValue:@[@(rgb[0]), @(rgb[1]), @(rgb[2]), @(CGColorGetAlpha(blurTint.CGColor))] forKey:@"inputColor"];
		((CKCB7BlurView *)bar).tintColorFilter = tintFilter;
	}
}

static _UIBackdropViewSettings *backdropBlurSettings()
{
	_UIBackdropViewSettings *settings = [_UIBackdropViewSettings settingsForStyle:0];
	settings.usesColorTintView = YES;
	settings.colorTintAlpha = 0.5f;
	settings.requiresColorStatistics = YES;
	settings.blurRadius = blurAmount;
	settings.blurQuality = quality;
	return settings;
}

static void layoutBlurBar(CGRect frame)
{
	if (blurTop) {
		blurBar.frame = frame;
		blurBar.blurCroppingRect = frame;
	}
}

static void createBlurBar(CAMTopBar *topBar)
{
	UIView *backgroundView;
	object_getInstanceVariable(topBar, "__backgroundView", (void **)&backgroundView);
	blurBar = [[CKCB7BlurView alloc] initWithFrame:CGRectZero];
	blurBar.blurRadius = blurAmount;
	layoutBlurBar(CGRectZero);
	blurBar.blurQuality = quality;
	setBlurBarColor(blurBar, YES);
	if (backgroundView != nil)
		[backgroundView addSubview:blurBar];
	else
		[topBar addSubview:blurBar];
	[topBar layoutSubviews];
}

static void layoutBlurBar2(CGRect frame)
{
	if (blurBottom) {
		blurBar2.frame = frame;
		blurBar2.blurCroppingRect = frame;
	}
}

static void createBlurBar2(CAMBottomBar *bottomBar)
{
	UIView *backgroundView;
	object_getInstanceVariable(bottomBar, "_backgroundView", (void **)&backgroundView);
	blurBar2 = [[CKCB7BlurView alloc] initWithFrame:CGRectZero];
	blurBar2.blurRadius = blurAmount;
	layoutBlurBar2(CGRectZero);
	blurBar2.blurQuality = quality;
	setBlurBarColor(blurBar2, NO);
	if (backgroundView != nil)
		[backgroundView addSubview:blurBar2];
	else
		[bottomBar addSubview:blurBar2];
	[bottomBar layoutSubviews];
}

static void createBackdropBar(CAMTopBar *topBar)
{
	UIView *backgroundView;
	object_getInstanceVariable(topBar, "__backgroundView", (void **)&backgroundView);
	backdropBar = [[_UIBackdropView alloc] initWithFrame:CGRectZero autosizesToFitSuperview:YES settings:backdropBlurSettings()];
	backdropBar.inputSettings.blurRadius = blurAmount;
	backdropBar.outputSettings.blurRadius = blurAmount;
	setBlurBarColor(backdropBar, YES);
	if (backgroundView != nil)
		[backgroundView addSubview:backdropBar];
	else
		[topBar addSubview:backdropBar];
}

static void createBackdropBar2(CAMBottomBar *bottomBar)
{
	UIView *backgroundView;
	object_getInstanceVariable(bottomBar, "_backgroundView", (void **)&backgroundView);
	backdropBar2 = [[_UIBackdropView alloc] initWithFrame:CGRectZero autosizesToFitSuperview:YES settings:backdropBlurSettings()];
	backdropBar2.inputSettings.blurRadius = blurAmount;
	backdropBar2.outputSettings.blurRadius = blurAmount;
	setBlurBarColor(backdropBar2, NO);
	if (backgroundView != nil)
		[backgroundView addSubview:backdropBar2];
	else
		[bottomBar addSubview:backdropBar2];
}

static void createBlurryTopBar(CAMTopBar *topBar)
{
	if (blurTop) {
		if (useBackdrop)
			createBackdropBar(topBar);
		else
			createBlurBar(topBar);
	}
}

static void createBlurryBottomBar(CAMBottomBar *bottomBar)
{
	if (blurBottom) {
		if (useBackdrop)
			createBackdropBar2(bottomBar);
    	else
    		createBlurBar2(bottomBar);
    }
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

static void showTopBar(BOOL show)
{
	BOOL hide = !show;
	blurBar.hidden = hide;
	backdropBar.hidden = hide;
}

static void showBottomBar(BOOL show)
{
	BOOL hide = !show;
	blurBar2.hidden = hide;
	backdropBar2.hidden = hide;
}

static void showBar(BOOL show)
{
	if (handleVideoTB || handlePanoTB)
		showTopBar(show);
	if (handleVideoBB || handlePanoBB)
		showBottomBar(show);
}

static _UILegibilityView *_imageLegibilityView;

static void configureShadowLegibility(UIView *view)
{
	if (!readable) return;
	if (view) {
		view.layer.shadowColor = [UIColor blackColor].CGColor;
		view.layer.shadowRadius = 3.0f;
		view.layer.shadowOpacity = 1.0f;
		view.layer.shadowOffset = CGSizeZero;
		view.layer.masksToBounds = NO;
	}
}

static void configureImageLegibility(UIImageView *imageView)
{
	if (!readable) return;
	if (imageView) {
		if (!CGRectEqualToRect(CGRectZero, imageView.frame)) {
			UIView *imageLegibilityView = objc_getAssociatedObject(imageView, &_imageLegibilityView);
			if (imageLegibilityView != nil) {
				[imageLegibilityView removeFromSuperview];
				[imageLegibilityView release];
				imageLegibilityView = nil;
				objc_setAssociatedObject(imageView, &_imageLegibilityView, imageLegibilityView, OBJC_ASSOCIATION_ASSIGN);
			}
			_UILegibilitySettingsProvider *provider = [[_UILegibilitySettingsProvider alloc] init];
			[provider pl_primeForUseWithCameraOverlays];
			_UILegibilitySettings *settings = [[provider settings] retain];
			UIImage *image = [imageView.image retain];
			imageLegibilityView = [[_UILegibilityView alloc] initWithSettings:settings strength:2.5f image:image shadowImage:nil options:_UILegibilityViewOptionUsesColorFilters];
			[image release];
			[settings release];
			[provider release];
			imageLegibilityView.frame = imageView.bounds;
			[imageView addSubview:imageLegibilityView];
			objc_setAssociatedObject(imageView, &_imageLegibilityView, imageLegibilityView, OBJC_ASSOCIATION_ASSIGN);
		}
	}
}

static void configureLabelLegibilityOfHDRButton(UIView <cameraViewDelegate> *self)
{
	if (!readable) return;
	CAMHDRButton *hdrButton = MSHookIvar<CAMHDRButton *>(self, "__HDRButton");
	if (hdrButton) {
		if ([hdrButton isKindOfClass:objc_getClass("CAMTriStateButton")]) {
			CAMButtonLabel *autoLabel = MSHookIvar<CAMButtonLabel *>(hdrButton, "__autoLabel");
			CAMButtonLabel *landscapeLabel = MSHookIvar<CAMButtonLabel *>(hdrButton, "__landscapeFeatureLabel");
			CAMButtonLabel *offLabel = MSHookIvar<CAMButtonLabel *>(hdrButton, "__offLabel");
			CAMButtonLabel *onLabel = MSHookIvar<CAMButtonLabel *>(hdrButton, "__onLabel");
			configureShadowLegibility(autoLabel);
			configureShadowLegibility(landscapeLabel);
			configureShadowLegibility(offLabel);
			configureShadowLegibility(onLabel);
			/*[autoLabel setUseLegibilityView:YES];
			[landscapeLabel setUseLegibilityView:YES];
			[offLabel setUseLegibilityView:YES];
			[onLabel setUseLegibilityView:YES];*/
		} else {
			for (CAMButtonLabel *label in hdrButton.subviews) {
				if ([label isKindOfClass:objc_getClass("CAMButtonLabel")])
					[label setUseLegibilityView:YES];
			}
		}
	}
}

static void configureLegibilityOfTimerButton(UIView <cameraViewDelegate> *self)
{
	if (!readable) return;
	CAMTimerButton *timerButton = MSHookIvar<CAMTimerButton *>(self, "__timerButton");
	if (timerButton) {
		configureImageLegibility(MSHookIvar<UIImageView *>(timerButton, "__glyphView"));
		for (CAMButtonLabel *label in timerButton.subviews) {
			if ([label isKindOfClass:objc_getClass("CAMButtonLabel")])
				[label setUseLegibilityView:YES];
		}
	}
}

static void configureLegibilityOfFlipButton(UIView <cameraViewDelegate> *self)
{
	if (!readable) return;
	CAMFlipButton *flipButton = MSHookIvar<CAMFlipButton *>(self, "__flipButton");
	if (flipButton) {
		//configureImageLegibility(MSHookIvar<UIImageView *>(flipButton, "_imageView"));
		configureShadowLegibility(flipButton);
	}
}

static void configureLegibilityOfFilterButton(UIView <cameraViewDelegate> *self)
{
	if (!readable) return;
	CAMFilterButton *filterButton = MSHookIvar<CAMFilterButton *>(self, "__filterButton");
	if (filterButton) {
		//configureImageLegibility(MSHookIvar<UIImageView *>(filterButton, "_imageView"));
		configureShadowLegibility(filterButton);
	}
}

static void configureLegibilityOfShutterButton(UIView <cameraViewDelegate> *self)
{
	if (!readable) return;
	CAMShutterButton *shutterButton = MSHookIvar<CAMShutterButton *>(self, "__shutterButton");
	if (shutterButton) {
		//configureImageLegibility(MSHookIvar<UIImageView *>(shutterButton, "_imageView"));
		configureShadowLegibility(shutterButton);
	}
}

static void configureLegibilityOfFlashButton(UIView <cameraViewDelegate> *self)
{
	if (!readable) return;
	CAMFlashButton *flashButton = MSHookIvar<CAMFlashButton *>(self, "__flashButton");
	if (flashButton) {
		UIImageView *imageView = nil;
		if ([flashButton respondsToSelector:@selector(_flashIconView)])
			imageView = flashButton._flashIconView;
		else if ([flashButton respondsToSelector:@selector(_iconView)])
			imageView = flashButton._iconView;
		else
			imageView = MSHookIvar<UIImageView *>(flashButton, "__glyphView");
		if ([flashButton isKindOfClass:objc_getClass("CAMTriStateButton")]) {
			CAMButtonLabel *autoLabel = MSHookIvar<CAMButtonLabel *>(flashButton, "__autoLabel");
			CAMButtonLabel *landscapeLabel = MSHookIvar<CAMButtonLabel *>(flashButton, "__landscapeFeatureLabel");
			CAMButtonLabel *offLabel = MSHookIvar<CAMButtonLabel *>(flashButton, "__offLabel");
			CAMButtonLabel *onLabel = MSHookIvar<CAMButtonLabel *>(flashButton, "__onLabel");
			configureShadowLegibility(autoLabel);
			configureShadowLegibility(landscapeLabel);
			configureShadowLegibility(offLabel);
			configureShadowLegibility(onLabel);
			configureShadowLegibility(imageView);
		} else {
			configureImageLegibility(imageView);
			for (CAMButtonLabel *label in flashButton.subviews) {
				if ([label isKindOfClass:objc_getClass("CAMButtonLabel")])
					label.useLegibilityView = YES;
			}
		}
	}
}

%group CKCB7BlurView

%hook CAMTopBar

- (void)layoutSubviews
{
	%orig;
	UIView *backgroundView;
	object_getInstanceVariable(self, "__backgroundView", (void **)&backgroundView);
	layoutBlurBar(backgroundView != nil ? backgroundView.bounds : self.bounds);
}

%end

%hook CAMBottomBar

- (void)_layoutForVerticalOrientation
{
	%orig;
	UIView *backgroundView;
	object_getInstanceVariable(self, "_backgroundView", (void **)&backgroundView);
	layoutBlurBar2(backgroundView != nil ? backgroundView.bounds : self.bounds);
}

- (void)_layoutForHorizontalOrientation
{
	%orig;
	UIView *backgroundView;
	object_getInstanceVariable(self, "_backgroundView", (void **)&backgroundView);
	layoutBlurBar2(backgroundView != nil ? backgroundView.bounds : self.bounds);
}

%end

%end

%group Common

static void CAMModeDialConfigure(CAMModeDial *self)
{
	if (!readable) return;
	NSArray *items = [self _items];
	for (CAMModeDialItem *item in items) {
		if ([item isKindOfClass:objc_getClass("CAMModeDialItem")]) {
			for (UILabel *label in item.subviews) {
				if ([label isKindOfClass:[UILabel class]]) {
					configureShadowLegibility(label);
				}
			}
		}
	}
}

%hook CAMModeDial

- (void)setSelectedIndex:(NSUInteger)index animated:(BOOL)animated
{
	%orig;
	CAMModeDialConfigure(self);
}

- (void)reloadData
{
	%orig;
	CAMModeDialConfigure(self);
}

%end

%hook CAMElapsedTimeView

- (void)_commonCAMElapsedTimeViewInitialization
{
	%orig;
	configureShadowLegibility(MSHookIvar<UILabel *>(self, "__timeLabel"));
}

%end

%hook CAMTopBar

- (void)_commonCAMTopBarInitialization
{
	%orig;
	createBlurryTopBar(self);
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
	createBlurryBottomBar(self);
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

- (BOOL)_shouldHideFlipButtonForMode:(NSInteger)mode
{
	BOOL orig = %orig;
	if (!orig)
		configureLegibilityOfFlipButton(self);
	return orig;
}

- (void)_createHDRButtonIfNecessary
{
	%orig;
	configureLabelLegibilityOfHDRButton(self);
}

- (void)_createFlashButtonIfNecessary
{
	%orig;
	configureLegibilityOfFlashButton(self);
}

- (void)_createFilterButtonIfNecessary
{
	%orig;
	configureLegibilityOfFilterButton(self);
}

- (void)_createShutterButtonIfNecessary
{
	%orig;
	configureLegibilityOfShutterButton(self);
}

%new
- (BOOL)cb7_shouldHideBlurryTopBarForMode:(NSInteger)mode
{
	if (handlePanoTB) {
		if ([self _isCapturing] || self._topBar.backgroundStyle == 1)
			return YES;
	}
	return [self _shouldHideTopBarForMode:mode];
}

- (void)_hideControlsForChangeToMode:(NSInteger)mode animated:(BOOL)animated
{
	%orig;
	showTopBar(![self cb7_shouldHideBlurryTopBarForMode:mode]);
}

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

- (void)startPanorama
{
	showBar(NO);
	showTopBar(![self cb7_shouldHideBlurryTopBarForMode:3]);
	%orig;
}

- (void)stopPanorama
{
	if (![self cb7_shouldHideBlurryTopBarForMode:3])
		showBar(YES);
	%orig;
}

%end

%end

%group iOS8

%hook CAMCameraView

- (BOOL)_shouldHideFlipButtonForMode:(NSInteger)mode
{
	BOOL orig = %orig;
	if (!orig)
		configureLegibilityOfFlipButton(self);
	return orig;
}

- (void)_createHDRButtonIfNecessary
{
	%orig;
	configureLabelLegibilityOfHDRButton(self);
}

- (void)_createFlashButtonIfNecessary
{
	%orig;
	configureLegibilityOfFlashButton(self);
}

- (void)_createTimerButtonIfNecessary
{
	%orig;
	configureLegibilityOfTimerButton(self);
}

- (void)_createFilterButtonIfNecessary
{
	%orig;
	configureLegibilityOfFilterButton(self);
}

- (void)_createShutterButtonIfNecessary
{
	%orig;
	configureLegibilityOfShutterButton(self);
}

%new
- (BOOL)cb7_shouldHideBlurryTopBarForMode:(NSInteger)mode
{
	if (handlePanoTB) {
		if ([self _isCapturing] || self._topBar.backgroundStyle == 1)
			return YES;
	}
	return [self _shouldHideTopBarForMode:mode];
}

- (void)_hideControlsForChangeToMode:(NSInteger)mode animated:(BOOL)animated
{
	%orig;
	showTopBar(![self cb7_shouldHideBlurryTopBarForMode:mode]);
}

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
	showBar(![self _shouldHideTopBarForMode:self.cameraMode]);
	%orig;
}

- (void)_showControlsForCapturingTimelapseAnimated:(BOOL)capturingTimelapseAnimated
{
	showBar(NO);
	%orig;
}

- (void)_hideControlsForCapturingTimelapseAnimated:(BOOL)capturingTimelapseAnimated
{
	if (![self cb7_shouldHideBlurryTopBarForMode:3])
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
		NSString *executablePath = args[0];
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
