#import <Foundation/Foundation.h>

CFStringRef const tweak = CFSTR("com.PS.CamBlur7");
CFStringRef const PreferencesChangedNotification = CFSTR("com.PS.CamBlur7.prefs");
NSString *const PREF_PATH = @"/var/mobile/Library/Preferences/com.PS.CamBlur7.plist";
NSString *const QualityKey = @"Quality";

@interface CAMTopBar : UIView
- (CGSize)sizeThatFits:(CGSize)fits;
- (CGSize)intrinsicContentSize;
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

@interface CAMCaptureController : NSObject
@property(retain) CAMEffectsRenderer *effectsRenderer;
+ (CAMCaptureController *)sharedInstance;
- (CAMCameraView *)delegate;
- (BOOL)isCapturingVideo;
@end