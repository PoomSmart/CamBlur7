#import "../PS.h"

NSString *tweakIdentifier = @"com.PS.CamBlur7";

NSString *blurKey = @"blur";
NSString *blurTopKey = @"blurTop";
NSString *blurBottomKey = @"blurBottom";
NSString *useBackdropKey = @"useBackdrop";
NSString *readableKey = @"readable";
NSString *handleEffectTBKey = @"handleEffectTB";
NSString *handleEffectBBKey = @"handleEffectBB";
NSString *handleVideoTBKey = @"handleVideoTB";
NSString *handleVideoBBKey = @"handleVideoBB";
NSString *handlePanoTBKey = @"handlePanoTB";
NSString *handlePanoBBKey = @"handlePanoBB";
NSString *HuetopBarKey = @"HuetopBar";
NSString *SattopBarKey = @"SattopBar";
NSString *BritopBarKey = @"BritopBar";
NSString *HuebottomBarKey = @"HuebottomBar";
NSString *SatbottomBarKey = @"SatbottomBar";
NSString *BribottomBarKey = @"BribottomBar";
NSString *QualityKey = @"QualityKey";
NSString *blurAmountKey = @"blurAmount";

@interface CAMTopBar (CamBlur7)
- (void)updateSize:(CGRect)frame;
@end