#import "CKCB7BlurView.h"
#import "../PS.h"

CKCB7BlurView *blurBar = nil;
CKCB7BlurView *blurBar2 = nil;
_UIBackdropView *backdropBar = nil;
_UIBackdropView *backdropBar2 = nil;

static BOOL useBackdrop;

static BOOL blur;
static BOOL blurTop;
static BOOL blurBottom;
static BOOL readable;
static BOOL handleEffectTB, handlePanoTB, handleVideoTB;
static BOOL handleEffectBB, handlePanoBB, handleVideoBB;

static CGFloat blurAmount;
static CGFloat HuetopBar, SattopBar, BritopBar;
static CGFloat HuebottomBar, SatbottomBar, BribottomBar;

static NSString *quality;