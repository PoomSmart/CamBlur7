#import "CKBlurView.h"

#define PREF_PATH @"/var/mobile/Library/Preferences/com.PS.CamBlur7.plist"
#define PreferencesChangedNotification "com.PS.CamBlur7.prefs"
#define IPAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define PH_BAR_HEIGHT 90

static BOOL pf = NO;

static BOOL blur;
static BOOL handleEffectiPhone;
static BOOL handleVideoTB;
static BOOL handleVideoBB;
static float blurAmount;

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

@interface PLCameraController
- (PLCameraView *)delegate;
@end

static CKBlurView *blurBar;
static CKBlurView *blurBar2;

static void CB7Loader()
{
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
	blur = [dict objectForKey:@"blur"] ? [[dict objectForKey:@"blur"] boolValue] : YES;
	handleEffectiPhone = [dict objectForKey:@"handleEffectiPhone"] ? [[dict objectForKey:@"handleEffectiPhone"] boolValue] : YES;
	handleVideoTB = [dict objectForKey:@"handleVideoTB"] ? [[dict objectForKey:@"handleVideoTB"] boolValue] : YES;
	handleVideoBB = [dict objectForKey:@"handleVideoBB"] ? [[dict objectForKey:@"handleVideoBB"] boolValue] : YES;
	blurAmount = [dict objectForKey:@"blurAmount"] ? [[dict objectForKey:@"blurAmount"] floatValue] : 20.0f;
}


static void PreferencesChangedCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	system("killall Camera");
	CB7Loader();
}

static void createBlurBarWithFrame(CGRect frame)
{
	blurBar = [[CKBlurView alloc] initWithFrame:frame];
	blurBar.blurRadius = blurAmount;
	blurBar.frame = frame;
	blurBar.blurCroppingRect = frame;
}

static void createBlurBar2WithFrame(CGRect frame)
{
	blurBar2 = [[CKBlurView alloc] initWithFrame:frame];
	blurBar2.blurRadius = blurAmount;
	blurBar2.frame = frame;
	blurBar2.blurCroppingRect = frame;
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
	if ([[[NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.PS.PhotoFlash.plist"] objectForKey:@"PFEnabled"] boolValue])
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
	if (!IPAD && handleEffectiPhone)
		blurBar2.hidden = showEffectsGrid;
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
