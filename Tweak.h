#import "CKCB7BlurView.h"
#import "../PS.h"
#import "Common.h"
#import <HBPreferences.h>

CKCB7BlurView *blurBar = nil;
CKCB7BlurView *blurBar2 = nil;
_UIBackdropView *backdropBar = nil;
_UIBackdropView *backdropBar2 = nil;

BOOL useBackdrop;

BOOL blur;
BOOL blurTop;
BOOL blurBottom;
BOOL readable;
BOOL handleEffectTB, handlePanoTB, handleVideoTB;
BOOL handleEffectBB, handlePanoBB, handleVideoBB;

CGFloat blurAmount;
CGFloat HuetopBar, SattopBar, BritopBar;
CGFloat HuebottomBar, SatbottomBar, BribottomBar;

NSInteger _quality;
NSString *quality;

HBPreferences *preferences;

void registerPref_tweak(HBPreferences *preferences)
{
	[preferences registerBool:&blur default:YES forKey:blurKey];
	[preferences registerBool:&blurTop default:YES forKey:blurTopKey];
	[preferences registerBool:&blurBottom default:YES forKey:blurBottomKey];
	[preferences registerBool:&useBackdrop default:NO forKey:useBackdropKey];
	[preferences registerBool:&readable default:NO forKey:readableKey];
	[preferences registerBool:&handleEffectTB default:YES forKey:handleEffectTBKey];
	[preferences registerBool:&handlePanoTB default:YES forKey:handlePanoTBKey];
	[preferences registerBool:&handleVideoTB default:YES forKey:handleVideoTBKey];
	[preferences registerBool:&handleEffectBB default:YES forKey:handleEffectBBKey];
	[preferences registerBool:&handlePanoBB default:YES forKey:handlePanoBBKey];
	[preferences registerBool:&handleVideoBB default:YES forKey:handleVideoBBKey];
	[preferences registerFloat:&HuetopBar default:0.35 forKey:HuetopBarKey];
	[preferences registerFloat:&SattopBar default:0.35 forKey:SattopBarKey];
	[preferences registerFloat:&BritopBar default:0.35 forKey:BritopBarKey];
	[preferences registerFloat:&HuebottomBar default:0.35 forKey:HuebottomBarKey];
	[preferences registerFloat:&SatbottomBar default:0.35 forKey:SatbottomBarKey];
	[preferences registerFloat:&BribottomBar default:0.35 forKey:BribottomBarKey];
	[preferences registerInteger:&_quality default:0 forKey:QualityKey];
	[preferences registerPreferenceChangeBlock:^(NSString *key, id <NSCopying> _Nullable value) {
		quality = _quality == 1 ? CKBlurViewQualityLow : CKBlurViewQualityDefault;
	} forKey:QualityKey];
	[preferences registerFloat:&blurAmount default:20.0 forKey:blurAmountKey];
}