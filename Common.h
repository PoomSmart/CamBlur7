#import <Foundation/Foundation.h>

CFStringRef const tweak = CFSTR("com.PS.CamBlur7");
CFStringRef const PreferencesChangedNotification = CFSTR("com.PS.CamBlur7.prefs");
NSString *const PREF_PATH = @"/var/mobile/Library/Preferences/com.PS.CamBlur7.plist";
NSString *const QualityKey = @"Quality";

@interface CAMButtonLabel : UILabel
- (void)setUseLegibilityView:(BOOL)use;
@end

@interface CAMExpandableMenuButton : UIButton
@end

@interface CAMModeDialItem : UIView
@end

@interface CAMModeDial : UIView
- (NSArray *)_items;
@end

@interface CAMFlashButton : UIButton
@property(readonly, assign, nonatomic) UIImageView *_flashIconView;
@property(readonly, assign, nonatomic) UIImageView *_iconView;
@end

@interface CAMFilterButton : UIButton
@end

@interface CAMHDRButton : UIButton
@end

@interface CAMTimerButton : UIButton
@end

@interface CAMFlipButton : UIButton
- (UIImage *)_flipImage;
@end

@interface CAMElapsedTimeView : UIView
@end

@interface CAMShutterButton : UIButton
@end

@interface CAMTopBar : UIView
@property(retain, nonatomic) CAMFlipButton *flipButton;
- (CGSize)sizeThatFits:(CGSize)fits;
- (CGSize)intrinsicContentSize;
- (CGRect)alignmentRectForFrame:(CGRect)frame;
@end

@interface CAMTopBar (CamBlur7)
- (void)updateSize:(CGRect)frame;
@end

@interface CAMBottomBar : UIView
@property(retain, nonatomic) CAMFlipButton *flipButton;
@property(retain, nonatomic) CAMShutterButton *shutterButton;
@property(retain, nonatomic) CAMModeDial *modeDial;
- (CGSize)sizeThatFits:(CGSize)fits;
- (UIView *)_shutterButtomBottomLayoutSpacer;
@end

@protocol cameraViewDelegate
@property(readonly, assign, nonatomic) CAMTopBar *_topBar;
@property(readonly, assign, nonatomic) CAMBottomBar *_bottomBar;
@end

@interface PLCameraView : UIView <cameraViewDelegate>
@end

@interface CAMCameraView : UIView <cameraViewDelegate>
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

@interface CAMCaptureController : NSObject
@property(retain) CAMEffectsRenderer *effectsRenderer;
+ (CAMCaptureController *)sharedInstance;
- (CAMCameraView *)delegate;
- (BOOL)isCapturingVideo;
@end

@interface CAMLegibilityViewHelper : NSObject
+ (UIImage *)_imageFromLabel:(UILabel *)label sizeToFit:(BOOL)fit;
@end

@interface _UILegibilitySettingsProvider : NSObject
- (_UILegibilitySettings *)settings;
@end

@interface _UILegibilitySettingsProvider (PhotoLibraryAdditions)
- (void)pl_primeForUseWithCameraOverlays;
@end

@interface UIView (Constraints)
- (NSArray *)cam_constraintsForKey:(NSString *)key;
- (void)cam_addConstraints:(NSArray *)constraints forKey:(NSString *)key;
- (void)cam_removeAllConstraintsForKey:(NSString *)key;
@end

extern NSInteger _UILegibilityViewOptionUsesColorFilters;
