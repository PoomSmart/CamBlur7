#import "Backdrop.h"
#import "CKCB7BlurView.h"
#import <CoreGraphics/CoreGraphics.h>

#define PREF_PATH @"/var/mobile/Library/Preferences/com.PS.CamBlur7.plist"
#define PreferencesChangedNotification "com.PS.CamBlur7.prefs"
#define isiOS8 (kCFCoreFoundationVersionNumber >= 1140.0)
#define PH_BAR_HEIGHT 90

static BOOL pf = NO;
static BOOL notUseBackdrop = YES;

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

static NSString *quality = CKBlurViewQualityDefault;

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
@property(readonly, assign, nonatomic) CAMTopBar *_topBar;
@end

@interface CAMCameraView : UIView
@property(readonly, assign, nonatomic) CAMTopBar *_topBar;
@end

@interface PLCameraEffectsRenderer
@property(assign, nonatomic, getter=isShowingGrid) BOOL showGrid;
@end

@interface CAMEffectsRenderer
@property(assign, nonatomic, getter=isShowingGrid) BOOL showGrid;
@end

@interface PLCameraController : NSObject
@property(retain) PLCameraEffectsRenderer *effectsRenderer;
+ (PLCameraController *)sharedInstance;
- (PLCameraView *)delegate;
- (BOOL)isCapturingVideo;
@end

@interface CAMCameraController : NSObject
@property(retain) CAMEffectsRenderer *effectsRenderer;
+ (CAMCameraController *)sharedInstance;
- (CAMCameraView *)delegate;
- (BOOL)isCapturingVideo;
@end

static CKCB7BlurView *blurBar = nil;
static CKCB7BlurView *blurBar2 = nil;
static _UIBackdropView *backdropBar = nil;
static _UIBackdropView *backdropBar2 = nil;

static void CB7Loader()
{
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
	#define BoolOpt(option) \
		option = [dict objectForKey:[NSString stringWithUTF8String:#option]] ? [[dict objectForKey:[NSString stringWithUTF8String:#option]] boolValue] : YES;
	#define FloatOpt(option) \
		option = [dict objectForKey:[NSString stringWithUTF8String:#option]] ? [[dict objectForKey:[NSString stringWithUTF8String:#option]] floatValue] : 0.35;
	BoolOpt(blur)
	notUseBackdrop = [dict objectForKey:@"notUseBackdrop"] ? ![[dict objectForKey:@"notUseBackdrop"] boolValue] : YES;
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
	quality = value == 1 ? CKBlurViewQualityLow : CKBlurViewQualityDefault;
	blurAmount = [dict objectForKey:@"blurAmount"] ? [[dict objectForKey:@"blurAmount"] floatValue] : 20.0f;
}


static void PreferencesChangedCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	system("killall Camera");
	CB7Loader();
}

static void setBlurBarColor(id bar, BOOL top)
{
	UIColor *blurTint = nil;
	if (top)
		blurTint = [UIColor colorWithRed:tR green:tG blue:tB alpha:1];
	else
		blurTint = [UIColor colorWithRed:bR green:bG blue:bB alpha:1];
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
	[settings setColorTintAlpha:0.5];
	[settings setRequiresColorStatistics:YES];
	[settings setBlurRadius:blurAmount];
	[settings setBlurQuality:quality];
	return settings;
}

static void createBlurBarWithFrame(CGRect frame)
{
	blurBar = [[CKCB7BlurView alloc] initWithFrame:frame];
	blurBar.blurRadius = blurAmount;
	blurBar.frame = frame;
	blurBar.blurCroppingRect = frame;
	[blurBar setBlurQuality:quality];
	setBlurBarColor(blurBar, YES);
}

static void createBlurBar2WithFrame(CGRect frame)
{
	blurBar2 = [[CKCB7BlurView alloc] initWithFrame:frame];
	blurBar2.blurRadius = blurAmount;
	blurBar2.frame = frame;
	blurBar2.blurCroppingRect = frame;
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

%group CKCB7BlurView

%hook CameraController

- (void)_setCameraMode:(int)mode cameraDevice:(int)device
{
	%orig;
	if (pf) {
		CGSize size = blurBar.frame.size;
		CGRect frame = CGRectMake(0, 0, size.width, device == 0 ? PH_BAR_HEIGHT : 40);
		[[[self delegate] _topBar] updateSize:frame];
	}
}

%end

%hook CAMTopBar

%new
- (void)updateSize:(CGRect)frame
{
	releaseBlurBars();
	UIView* backgroundView = MSHookIvar<UIView *>(self, "__backgroundView");
	createBlurBarWithFrame(frame);
	[backgroundView insertSubview:blurBar atIndex:0];
}

%end

%hook CAMBottomBar

- (void)_layoutForVerticalOrientation
{
	%orig;
	Class CameraController = isiOS8 ? objc_getClass("CAMCameraController") : objc_getClass("PLCameraController");
	if (([[CameraController sharedInstance].effectsRenderer isShowingGrid] && handleEffectBB) || ([[%c(PLCameraController) sharedInstance] isCapturingVideo] && handleVideoBB))
		return;
	if (blurBar2 != nil) {
		releaseBlurBars2();
		CGSize size = self.frame.size;
		CGRect frame = CGRectMake(0, 0, size.width, size.height);
		createBlurBar2WithFrame(frame);
		[self insertSubview:blurBar2 atIndex:0];
    }
}

- (void)_layoutForHorizontalOrientation
{
	%orig;
	if (([[%c(PLCameraController) sharedInstance].effectsRenderer isShowingGrid] && handleEffectBB) || ([[%c(PLCameraController) sharedInstance] isCapturingVideo] && handleVideoBB))
		return;
	if (blurBar2 != nil) {
		releaseBlurBars2();
		CGSize size = self.frame.size;
		CGRect frame = CGRectMake(0, 0, size.width, size.height);
		createBlurBar2WithFrame(frame);
		[self insertSubview:blurBar2 atIndex:0];
    }
}

%end

%end

%group Common

%hook CAMTopBar

- (void)_commonCAMTopBarInitialization
{
	%orig;
	pf = NO;
	if ([[[NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.PS.PhotoFlash.plist"] objectForKey:@"PFEnabled"] boolValue] &&
		dlopen("/Library/MobileSubstrate/DynamicLibraries/PhotoFlash.dylib", RTLD_LAZY) != NULL)
		pf = YES;
	UIView* backgroundView = MSHookIvar<UIView *>(self, "__backgroundView");
	if (!notUseBackdrop) {
		createBackdropBar();
		[backgroundView addSubview:backdropBar];
	} else {
		CGSize size = [self sizeThatFits:CGSizeZero];
		CGRect frame = CGRectMake(0, 0, size.width, pf ? PH_BAR_HEIGHT : size.height);
		createBlurBarWithFrame(frame);
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
	if (!notUseBackdrop) {
		createBackdropBar2();
		[self addSubview:backdropBar2];
    } else {
    	createBlurBar2WithFrame(CGRectZero);
		[self addSubview:blurBar2];
    }
}

- (void)dealloc
{
	releaseBlurBars2();
	%orig;
}

%end

%hook CameraView

- (void)_showControlsForCapturingVideoAnimated:(BOOL)capturingVideoAnimated
{
	if (handleVideoTB) {
		blurBar.hidden = YES;
		backdropBar.hidden = YES;
	}
	if (handleVideoBB) {
		blurBar2.hidden = YES;
		backdropBar2.hidden = YES;
	}
	%orig;
}

- (void)cameraControllerDidStopVideoCapture:(id)cameraController
{
	%orig;
	if (handleVideoTB) {
		blurBar.hidden = NO;
		backdropBar.hidden = NO;
	}
	if (handleVideoBB) {
		blurBar2.hidden = NO;
		backdropBar2.hidden = NO;
	}
}

- (void)cameraController:(id)controller didStartTransitionToShowEffectsGrid:(BOOL)showEffectsGrid animated:(BOOL)animated
{
	%orig;
	if (handleEffectTB) {
		blurBar.hidden = showEffectsGrid;
		backdropBar.hidden = showEffectsGrid;
	}
	if (handleEffectBB) {
		blurBar2.hidden = showEffectsGrid;
		backdropBar2.hidden = showEffectsGrid;
	}
}

- (void)_performPanoramaCapture
{
	if (handlePanoTB) {
		blurBar.hidden = YES;
		backdropBar.hidden = YES;
	}
	if (handlePanoBB) {
		blurBar2.hidden = YES;
		backdropBar2.hidden = YES;
	}
	%orig;
}

- (void)cameraControllerWillStopPanoramaCapture:(id)capture
{
	if (handlePanoTB) {
		blurBar.hidden = NO;
		backdropBar.hidden = NO;
	}
	if (handlePanoBB) {
		backdropBar2.hidden = NO;
	}
	%orig;
}

%end

%end

%ctor {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PreferencesChangedCallback, CFSTR(PreferencesChangedNotification), NULL, CFNotificationSuspensionBehaviorCoalesce);
	CB7Loader();
	if (blur) {
		%init(Common, CameraView = isiOS8 ? objc_getClass("CAMCameraView") : objc_getClass("PLCameraView"));
		if (notUseBackdrop) {
			%init(CKCB7BlurView, CameraController = isiOS8 ? objc_getClass("CAMCameraController") : objc_getClass("PLCameraController"));
		}
	}
	[pool drain];
}
