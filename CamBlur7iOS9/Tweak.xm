#import <substrate.h>
#import <objc/runtime.h>
#import "../CKCB7BlurView.h"
#import "../Common.h"
#import "../Tweak.h"
#import "../../PS.h"
#define TIMER
#import "../functions.xm"

@interface CAMViewfinderViewController (CB7)
- (BOOL)cb7_shouldHideBlurryTopBarForMode:(int)mode device:(int)device;
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

%hook CAMViewfinderViewController

- (BOOL)_shouldHideFlipButtonForMode:(int)mode device:(int)device
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
- (BOOL)cb7_shouldHideBlurryTopBarForMode:(int)mode device:(int)device
{
	if (handlePanoTB) {
		if ([self _isCapturingTimelapse] || [self._captureController isCapturingVideo] || self._topBar.backgroundStyle == 1)
			return YES;
	}
	return [self _shouldHideTopBarForMode:mode device:device];
}

- (void)_hideControlsForMode:(int)mode device:(int)device animated:(BOOL)animated
{
	%orig;
	if (mode == 1 || mode == 2 || (mode == 6 && ![self cb7_shouldHideBlurryTopBarForMode:3 device:device]))
		showBar(YES);
	else if (mode == 3)
		showBar(![self _shouldHideTopBarForMode:mode device:device]);
}

- (void)_showControlsForMode:(int)mode device:(int)device animated:(BOOL)animated
{
	if (mode == 1 || mode == 2 || mode == 3 || mode == 6)
		showBar(NO);
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
		openCamera9();
		%init;
		if (!useBackdrop) {
			%init(CKCB7BlurView);
		}
	}
}