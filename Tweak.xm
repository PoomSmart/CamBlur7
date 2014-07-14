#import "Backdrop.h"
#import <CoreGraphics/CoreGraphics.h>

#define PREF_PATH @"/var/mobile/Library/Preferences/com.PS.CamBlur7.plist"
#define PreferencesChangedNotification "com.PS.CamBlur7.prefs"
#define PH_BAR_HEIGHT 90

static BOOL pf = NO;

static BOOL blur;
static BOOL handleEffectTB;
static BOOL handleEffectBB;
static BOOL handleVideoTB;
static BOOL handleVideoBB;
static BOOL handlePanoTB;
static BOOL handlePanoBB;

static float blurAmount;
static float tR;
static float tG;
static float tB;
static float bR;
static float bG;
static float bB;

static NSString *quality = @"default";

@interface CAMTopBar : UIView
- (CGSize)sizeThatFits:(CGSize)fits;
@end

@interface CAMTopBar (CamBlur7)
- (void)updateSize:(CGRect)frame;
@end

@interface CAMBottomBar : UIView
- (CGSize)sizeThatFits:(CGSize)fits;
@end

@interface PLCameraView : UIView
@property(readonly, assign, nonatomic) CAMTopBar* _topBar;
@end

@interface PLCameraEffectsRenderer
@property(assign, nonatomic, getter=isShowingGrid) BOOL showGrid;
@end

@interface PLCameraController : NSObject
@property(retain) PLCameraEffectsRenderer *effectsRenderer;
+ (PLCameraController *)sharedInstance;
- (PLCameraView *)delegate;
@end

static _UIBackdropView *blurBar = nil;
static _UIBackdropView *blurBar2 = nil;

static void CB7Loader()
{
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
	#define BoolOpt(option) \
		option = [dict objectForKey:[NSString stringWithUTF8String:#option]] ? [[dict objectForKey:[NSString stringWithUTF8String:#option]] boolValue] : YES;
	#define FloatOpt(option) \
		option = [dict objectForKey:[NSString stringWithUTF8String:#option]] ? [[dict objectForKey:[NSString stringWithUTF8String:#option]] floatValue] : 0.35;
	BoolOpt(blur)
	BoolOpt(handleEffectTB)
	BoolOpt(handleEffectBB)
	BoolOpt(handleVideoTB)
	BoolOpt(handleVideoBB)
	BoolOpt(handlePanoTB)
	BoolOpt(handlePanoBB)
	FloatOpt(tR)
	FloatOpt(tG)
	FloatOpt(tB)
	FloatOpt(bR)
	FloatOpt(bG)
	FloatOpt(bB)
	int value = [dict objectForKey:@"Quality"] != nil ? [[dict objectForKey:@"Quality"] intValue] : 0;
	quality = value == 1 ? @"low" : @"default";
	blurAmount = [dict objectForKey:@"blurAmount"] ? [[dict objectForKey:@"blurAmount"] floatValue] : 20.0f;
}


static void PreferencesChangedCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	system("killall Camera");
	CB7Loader();
}

static void setBlurBarColor(_UIBackdropView *bar, BOOL top)
{
	UIColor *blurTint;
	if (top)
		blurTint = [UIColor colorWithRed:tR green:tG blue:tB alpha:1];
	else
		blurTint = [UIColor colorWithRed:bR green:bG blue:bB alpha:1];
	[bar.inputSettings setColorTint:blurTint];
	[bar.outputSettings setColorTint:blurTint];
}

static _UIBackdropViewSettings *blurSettings()
{
	_UIBackdropViewSettings *settings = [_UIBackdropViewSettings settingsForStyle:0];
	[settings setUsesColorTintView:YES];
	[settings setColorTintAlpha:0.4];
	[settings setRequiresColorStatistics:YES];
	[settings setBlurRadius:blurAmount];
	[settings setBlurQuality:quality];
	return settings;
}

static void createBlurBar()
{
	blurBar = [[_UIBackdropView alloc] initWithFrame:CGRectZero autosizesToFitSuperview:YES settings:blurSettings()];
	blurBar.inputSettings.blurRadius = blurAmount;
	blurBar.outputSettings.blurRadius = blurAmount;
	setBlurBarColor(blurBar, YES);
}

static void createBlurBar2()
{
	blurBar2 = [[_UIBackdropView alloc] initWithFrame:CGRectZero autosizesToFitSuperview:YES settings:blurSettings()];
	blurBar2.inputSettings.blurRadius = blurAmount;
	blurBar2.outputSettings.blurRadius = blurAmount;
	setBlurBarColor(blurBar2, NO);
}

static void releaseBlurBar()
{
	if (blurBar != nil) {
		[blurBar removeFromSuperview];
		[blurBar release];
		blurBar = nil;
	}
}

static void releaseBlurBar2()
{
	if (blurBar2 != nil) {
		[blurBar2 removeFromSuperview];
		[blurBar2 release];
		blurBar2 = nil;
	}
}

%hook CAMTopBar

- (void)_commonCAMTopBarInitialization
{
	%orig;
	pf = NO;
	if ([[[NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.PS.PhotoFlash.plist"] objectForKey:@"PFEnabled"] boolValue] &&
		dlopen("/Library/MobileSubstrate/DynamicLibraries/PhotoFlash.dylib", RTLD_LAZY) != NULL)
		pf = YES;
	if (blurBar == nil) {
		UIView* backgroundView = MSHookIvar<UIView *>(self, "__backgroundView");
		createBlurBar();
		[backgroundView addSubview:blurBar];
    }
}

- (void)dealloc
{
	releaseBlurBar();
	%orig;
}

%end

%hook CAMBottomBar

- (void)_layoutForVerticalOrientation
{
	%orig;
	if ([[%c(PLCameraController) sharedInstance].effectsRenderer isShowingGrid] && handleEffectBB)
		return;
	if (blurBar2 != nil) {
		releaseBlurBar2();
		createBlurBar2();
		[self insertSubview:blurBar2 atIndex:0];
    }
}

- (void)_layoutForHorizontalOrientation
{
	%orig;
	if ([[%c(PLCameraController) sharedInstance].effectsRenderer isShowingGrid] && handleEffectBB)
		return;
	if (blurBar2 != nil) {
		releaseBlurBar2();
		createBlurBar2();
		[self insertSubview:blurBar2 atIndex:0];
    }
}

- (void)_commonCAMBottomBarInitialization
{
	%orig;
	if (blurBar2 == nil) {
		createBlurBar2();
		[self addSubview:blurBar2];
    }
}

- (void)dealloc
{
	releaseBlurBar2();
	%orig;
}

%end

%hook PLCameraView

- (void)_showControlsForCapturingVideoAnimated:(BOOL)capturingVideoAnimated
{
	if (handleVideoTB)
		blurBar.hidden = YES;
	if (handleVideoBB)
		blurBar2.hidden = YES;
	%orig;
}

- (void)cameraControllerDidStopVideoCapture:(id)cameraController
{
	%orig;
	if (handleVideoTB)
		blurBar.hidden = NO;
	if (handleVideoBB)
		blurBar2.hidden = NO;
}

- (void)cameraController:(id)controller didStartTransitionToShowEffectsGrid:(BOOL)showEffectsGrid animated:(BOOL)animated
{
	%orig;
	if (handleEffectTB)
		blurBar.hidden = showEffectsGrid;
	if (handleEffectBB)
		blurBar2.hidden = showEffectsGrid;
}

- (void)_performPanoramaCapture
{
	if (handlePanoTB)
		blurBar.hidden = YES;
	if (handlePanoBB)
		blurBar2.hidden = YES;
	%orig;
}

- (void)cameraControllerWillStopPanoramaCapture:(id)capture
{
	if (handlePanoTB)
		blurBar.hidden = NO;
	if (handlePanoBB)
		blurBar2.hidden = NO;
	%orig;
}

%end

%ctor {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PreferencesChangedCallback, CFSTR(PreferencesChangedNotification), NULL, CFNotificationSuspensionBehaviorCoalesce);
	CB7Loader();
	if (blur) {
		%init();
	}
	[pool drain];
}
