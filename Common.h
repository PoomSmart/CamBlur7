#import "../PS.h"
#import <HBPreferences.h>

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

void registerPref(HBPreferences *preferences)
{
	[preferences registerDefaults:@{
		blurKey : @YES,
		blurTopKey : @YES,
		blurBottomKey : @YES,
		useBackdropKey : @NO,
		readableKey : @NO,
		handleEffectTBKey : @YES,
		handleEffectBBKey : @YES,
		handleVideoTBKey : @YES,
		handleVideoBBKey : @YES,
		handlePanoTBKey : @YES,
		handlePanoBBKey : @YES,
		HuetopBarKey : @0.35,
		SattopBarKey : @0.35,
		BritopBarKey : @0.35,
		HuebottomBarKey : @0.35,
		SatbottomBarKey : @0.35,
		BribottomBarKey : @0.35,
		QualityKey: @0,
		blurAmountKey : @20.0
	}];
}