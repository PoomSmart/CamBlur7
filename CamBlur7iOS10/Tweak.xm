#import <substrate.h>
#import <objc/runtime.h>
#import "../CKCB7BlurView.h"
#import "../Common.h"
#import "../Tweak.h"
#import "../../PS.h"
#define TIMER
#import "../functions.xm"

@interface CAMViewfinderViewController (CB7)
- (_Bool)cb7_shouldHideBlurryTopBarForGraphConfiguration:(CAMCaptureGraphConfiguration *)configuration;
@end

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

- (void)layoutSubviews
{
	%orig;
	UIView *backgroundView;
	object_getInstanceVariable(self, "_backgroundView", (void **)&backgroundView);
	layoutBlurBar2(backgroundView != nil ? backgroundView.bounds : self.bounds);
}

%end

%end

%hook CAMModeDial

- (void)setSelectedMode:(int)mode animated:(BOOL)animated
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

- (void)_commonCAMElapsedTimeViewInitializationWithLayoutStyle:(NSInteger)style
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

- (void)_commonCAMBottomBarInitializationInitWithLayoutStyle:(NSInteger)layoutStyle
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

%hook CAMViewfinderViewController

- (BOOL)_shouldHideFlipButtonForGraphConfiguration:(id)arg1
{
	BOOL orig = %orig;
	if (!orig)
		configureLegibilityOfFlipButton(self._flipButton);
	return orig;
}

- (void)_createHDRButtonIfNecessary
{
	%orig;
	configureLabelLegibilityOfHDRButton(self._HDRButton);
}

- (void)_createFlashButtonIfNecessary
{
	%orig;
	configureLegibilityOfFlashButton(self._flashButton);
}

- (void)_createTimerButtonIfNecessary
{
	%orig;
	configureLegibilityOfTimerButton(self._timerButton);
}

- (void)_createFilterButtonIfNecessary
{
	%orig;
	configureLegibilityOfFilterButton(self._filterButton);
}

- (void)_createShutterButtonIfNecessary
{
	%orig;
	configureLegibilityOfShutterButton(self._shutterButton);
}

%new
- (_Bool)cb7_shouldHideBlurryTopBarForGraphConfiguration:(CAMCaptureGraphConfiguration *)configuration
{
	if (handlePanoTB) {
		if ([self _isCapturingTimelapse] || [self._captureController isCapturingVideo] || self._topBar.backgroundStyle == 1)
			return YES;
	}
	return [self _shouldHideTopBarForGraphConfiguration:configuration];
}

- (void)_hideControlsForGraphConfiguration:(CAMCaptureGraphConfiguration *)configuration animated:(BOOL)animated
{
	%orig;
	NSInteger mode = configuration.mode;
	if (mode == 1 || mode == 2 || (mode == 6 && ![self cb7_shouldHideBlurryTopBarForGraphConfiguration:configuration]))
		showBar(YES);
	else if (mode == 3)
		showBar(![self _shouldHideTopBarForGraphConfiguration:configuration]);
}

- (void)_showControlsForGraphConfiguration:(CAMCaptureGraphConfiguration *)configuration animated:(BOOL)animated
{
	NSInteger mode = configuration.mode;
	if ((mode == 1 || mode == 2 || mode == 6) && (handleVideoTB || handleVideoBB))
		showBar(NO);
	else if (mode == 3 && (handlePanoTB || handlePanoBB))
		showBar(NO);
	else
		showBar(YES);
	%orig;
}

- (void)cameraEffectsRenderer:(id)renderer didStartTransitionToShowGrid:(BOOL)showGrid animated:(BOOL)animated
{
	%orig;
	showBar(!showGrid);
}

%end

%ctor
{
	HaveObserver()
	callback();
	if (blur) {
		openCamera10();
		%init;
		if (!useBackdrop) {
			%init(CKCB7BlurView);
		}
	}
}
