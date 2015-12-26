#import "../PS.h"
#import "Common.h"
#import "Tweak.h"
#import <objc/runtime.h>
#import <CoreGraphics/CoreGraphics.h>
#include <substrate.h>

static void loadPrefs()
{
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
	id val;
	#define BoolOpt(option) \
		val = dict[[NSString stringWithUTF8String:#option]]; \
		option = val ? [val boolValue] : YES;
	#if CGFLOAT_IS_DOUBLE
	#define FloatOpt(option) \
		val = dict[[NSString stringWithUTF8String:#option]]; \
		option = val ? [val doubleValue] : 0.35;
	#else
	#define FloatOpt(option) \
		val = dict[[NSString stringWithUTF8String:#option]]; \
		option = val ? [val floatValue] : 0.35;
	#endif
	BoolOpt(blur)
	BoolOpt(blurTop)
	BoolOpt(blurBottom)
	val = dict[@"useBackdrop"];
	useBackdrop = [val boolValue];
	val = dict[@"readable"];
	readable = [val boolValue];
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
	val = dict[QualityKey];
	int value = val ? [val intValue] : 0;
	quality = value == 1 ? CKBlurViewQualityLow : CKBlurViewQualityDefault;
	val = dict[@"blurAmount"];
	#if CGFLOAT_IS_DOUBLE
	blurAmount = val ? [val doubleValue] : 20.0;
	#else
	blurAmount = val ? [val floatValue] : 20.0;
	#endif
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
	settings.colorTintAlpha = 0.5;
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
	if (!isiOS83Up)
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

static void configureLabelLegibilityOfHDRButton(CAMHDRButton *hdrButton)
{
	if (!readable) return;
	//CAMHDRButton *hdrButton = MSHookIvar<CAMHDRButton *>(self, "__HDRButton");
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
				if ([label isKindOfClass:objc_getClass("CAMButtonLabel")]) {
					if ([label respondsToSelector:@selector(setWantsLegibilityShadow:)])
						label.wantsLegibilityShadow = YES;
					else if ([label respondsToSelector:@selector(setUseLegibilityView:)])
						label.useLegibilityView = YES;
				}
			}
		}
	}
}

static void configureLegibilityOfTimerButton(CAMTimerButton *timerButton)
{
	if (!readable) return;
	//CAMTimerButton *timerButton = MSHookIvar<CAMTimerButton *>(self, "__timerButton");
	if (timerButton) {
		configureImageLegibility(MSHookIvar<UIImageView *>(timerButton, "__glyphView"));
		for (CAMButtonLabel *label in timerButton.subviews) {
			if ([label isKindOfClass:objc_getClass("CAMButtonLabel")]) {
				if ([label respondsToSelector:@selector(setWantsLegibilityShadow:)])
						label.wantsLegibilityShadow = YES;
				else if ([label respondsToSelector:@selector(setUseLegibilityView:)])
					label.useLegibilityView = YES;
			}
		}
	}
}

static void configureLegibilityOfFlipButton(CAMFlipButton *flipButton)
{
	if (!readable) return;
	//CAMFlipButton *flipButton = MSHookIvar<CAMFlipButton *>(self, "__flipButton");
	if (flipButton) {
		//configureImageLegibility(MSHookIvar<UIImageView *>(flipButton, "_imageView"));
		configureShadowLegibility(flipButton);
	}
}

static void configureLegibilityOfFilterButton(CAMFilterButton *filterButton)
{
	if (!readable) return;
	//CAMFilterButton *filterButton = MSHookIvar<CAMFilterButton *>(self, "__filterButton");
	if (filterButton) {
		//configureImageLegibility(MSHookIvar<UIImageView *>(filterButton, "_imageView"));
		configureShadowLegibility(filterButton);
	}
}

static void configureLegibilityOfShutterButton(CAMShutterButton *shutterButton)
{
	if (!readable) return;
	//CAMShutterButton *shutterButton = MSHookIvar<CAMShutterButton *>(self, "__shutterButton");
	if (shutterButton) {
		//configureImageLegibility(MSHookIvar<UIImageView *>(shutterButton, "_imageView"));
		configureShadowLegibility(shutterButton);
	}
}

static void configureLegibilityOfFlashButton(CAMFlashButton *flashButton)
{
	if (!readable) return;
	//CAMFlashButton *flashButton = MSHookIvar<CAMFlashButton *>(self, "__flashButton");
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
				if ([label isKindOfClass:objc_getClass("CAMButtonLabel")]) {
					if ([label respondsToSelector:@selector(setWantsLegibilityShadow:)])
						label.wantsLegibilityShadow = YES;
					else if ([label respondsToSelector:@selector(setUseLegibilityView:)])
						label.useLegibilityView = YES;
				}
			}
		}
	}
}

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