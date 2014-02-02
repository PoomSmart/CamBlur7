#import "CKBlurView.h"
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

@interface CAMTopBar : UIView
- (CGSize)sizeThatFits:(CGSize)fits;
@end

@interface CAMTopBar (CamBlur7)
- (void)updateSize:(CGRect)frame;
@end

@interface CAMBottomBar : UIView
- (CGSize)sizeThatFits:(CGSize)fits;
@end

@interface PLCameraView
@property(readonly, assign, nonatomic) CAMTopBar* _topBar;
@end

@interface PLCameraEffectsRenderer
@property(assign, nonatomic, getter=isShowingGrid) BOOL showGrid;
@end

@interface PLCameraController : NSObject
@property(retain) PLCameraEffectsRenderer* effectsRenderer;
+ (PLCameraController *)sharedInstance;
- (PLCameraView *)delegate;
@end

static CKBlurView *blurBar;
static CKBlurView *blurBar2;

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
	blurAmount = [dict objectForKey:@"blurAmount"] ? [[dict objectForKey:@"blurAmount"] floatValue] : 20.0f;
}


static void PreferencesChangedCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	system("killall Camera");
	CB7Loader();
}

static void setBlurBarColor(CKBlurView *bar, BOOL top)
{
	UIColor *blurTint;
	if (top)
		blurTint = [UIColor colorWithRed:tR green:tG blue:tB alpha:1];
	else
		blurTint = [UIColor colorWithRed:bR green:bG blue:bB alpha:1];
	const CGFloat *rgb = CGColorGetComponents(blurTint.CGColor);
    CAFilter *tintFilter = [CAFilter filterWithName:@"colorAdd"];
    [tintFilter setValue:@[@(rgb[0]), @(rgb[1]), @(rgb[2]), @(CGColorGetAlpha(blurTint.CGColor))] forKey:@"inputColor"];
	[bar setTintColorFilter:tintFilter];
}

static void createBlurBarWithFrame(CGRect frame)
{
	blurBar = [[CKBlurView alloc] initWithFrame:frame];
	blurBar.blurRadius = blurAmount;
	blurBar.frame = frame;
	blurBar.blurCroppingRect = frame;
	setBlurBarColor(blurBar, YES);
}

static void createBlurBar2WithFrame(CGRect frame)
{
	blurBar2 = [[CKBlurView alloc] initWithFrame:frame];
	blurBar2.blurRadius = blurAmount;
	blurBar2.frame = frame;
	blurBar2.blurCroppingRect = frame;
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

%hook PLCameraController

- (void)_setCameraMode:(int)mode cameraDevice:(int)device
{
	%orig;
	if (pf) {
		CGSize size = blurBar.frame.size;
		CGRect frame = CGRectMake(0, 0, size.width, device == 0 ? PH_BAR_HEIGHT : 40);
		[[self delegate]._topBar updateSize:frame];
	}
}

%end

%hook CAMTopBar

%new
- (void)updateSize:(CGRect)frame
{
	releaseBlurBar();
	UIView* backgroundView = MSHookIvar<UIView *>(self, "__backgroundView");
	createBlurBarWithFrame(frame);
	[backgroundView insertSubview:blurBar atIndex:0];
}

- (void)_commonCAMTopBarInitialization
{
	%orig;
	pf = NO;
	if ([[[NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.PS.PhotoFlash.plist"] objectForKey:@"PFEnabled"] boolValue] &&
		dlopen("/Library/MobileSubstrate/DynamicLibraries/PhotoFlash.dylib", RTLD_LAZY) != NULL)
		pf = YES;
	if (blurBar == nil) {
		CGSize size = [self sizeThatFits:CGSizeZero];
		CGRect frame = CGRectMake(0, 0, size.width, pf ? PH_BAR_HEIGHT : size.height);
		UIView* backgroundView = MSHookIvar<UIView *>(self, "__backgroundView");
		createBlurBarWithFrame(frame);
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
		CGSize size = self.frame.size;
		CGRect frame = CGRectMake(0, 0, size.width, size.height);
		createBlurBar2WithFrame(frame);
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
		CGSize size = self.frame.size;
		CGRect frame = CGRectMake(0, 0, size.width, size.height);
		createBlurBar2WithFrame(frame);
		[self insertSubview:blurBar2 atIndex:0];
    }
}

- (void)_commonCAMBottomBarInitialization
{
	%orig;
	if (blurBar2 == nil) {
		createBlurBar2WithFrame(CGRectZero);
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
