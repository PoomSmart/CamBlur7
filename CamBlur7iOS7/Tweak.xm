#import <substrate.h>
#import <objc/runtime.h>
#import "../CKCB7BlurView.h"
#import "../Common.h"
#import "../Tweak.h"
#import "../../PS.h"
#import "../functions.xm"

@interface PLCameraView (CB7)
- (BOOL)cb7_shouldHideBlurryTopBarForMode:(NSInteger)mode;
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

%hook PLCameraView

- (BOOL)_shouldHideFlipButtonForMode:(NSInteger)mode
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

%ctor
{
	HaveObserver()
	callback();
	if (blur) {
		openCamera7();
		%init;
		if (!useBackdrop) {
			%init(CKCB7BlurView);
		}
	}
}