#import "CKCB7BlurView.h"
#import "../PS.h"
#import "Common.h"
#import "../PSPrefs.x"

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

int Quality;
NSString *quality;

HaveCallback()
{
	GetPrefs()
	GetBool2(blur, YES)
	GetBool2(blurTop, YES)
	GetBool2(blurBottom, YES)
	GetBool2(useBackdrop, NO)
	GetBool2(readable, NO)
	GetBool2(handleEffectTB, YES)
	GetBool2(handlePanoTB, YES)
	GetBool2(handleVideoTB, YES)
	GetBool2(handleEffectBB, YES)
	GetBool2(handlePanoBB, YES)
	GetBool2(handleVideoBB, YES)
	GetFloat2(HuetopBar, 0.35)
	GetFloat2(SattopBar, 0.35)
	GetFloat2(BritopBar, 0.35)
	GetFloat2(HuebottomBar, 0.35)
	GetFloat2(SatbottomBar, 0.35)
	GetFloat2(BribottomBar, 0.35)
	GetInt2(Quality, 0)
	quality = Quality == 1 ? CKBlurViewQualityLow : CKBlurViewQualityDefault;
	GetFloat2(blurAmount, 20.0)
}