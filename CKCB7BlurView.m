//
//  CKBlurView.m
//  CKBlurView
//
//  Created by Conrad Kramer on 10/25/13.
//  Copyright (c) 2013 Kramer Software Productions, LLC. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "CKCB7BlurView.h"

@interface CABackdropLayer : CALayer

@end

@interface CKCB7BlurView ()

@property (retain, nonatomic) CAFilter *blurFilter;

@property (retain, nonatomic) CAFilter *colorFilter;

@end

extern NSString * const kCAFilterGaussianBlur;

NSString * const CKBlurViewQualityDefault = @"default";

NSString * const CKBlurViewQualityLow = @"low";

static NSString * const CKBlurViewQualityKey = @"inputQuality";

static NSString * const CKBlurViewRadiusKey = @"inputRadius";

static NSString * const CKBlurViewBoundsKey = @"inputBounds";

static NSString * const CKBlurViewHardEdgesKey = @"inputHardEdges";


@implementation CKCB7BlurView

+ (Class)layerClass
{
    return [CABackdropLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        CAFilter *filter = [CAFilter filterWithName:kCAFilterGaussianBlur];
        self.layer.filters = @[ filter ];
        self.blurFilter = filter;

        self.blurQuality = CKBlurViewQualityDefault;
        self.blurRadius = 5.0f;        
    }
    return self;
}

- (void)setQuality:(NSString *)quality
{
	[self.blurFilter setValue:quality forKey:CKBlurViewQualityKey];
}

- (NSString *)quality
{
	return [self.blurFilter valueForKey:CKBlurViewQualityKey];
}

- (void)setBlurRadius:(CGFloat)radius
{
	[self.blurFilter setValue:@(radius) forKey:CKBlurViewRadiusKey];
}

- (CGFloat)blurRadius
{
	return [[self.blurFilter valueForKey:CKBlurViewRadiusKey] floatValue];
}

- (void)setBlurCroppingRect:(CGRect)croppingRect
{
	[self.blurFilter setValue:[NSValue valueWithCGRect:croppingRect] forKey:CKBlurViewBoundsKey];
}

- (CGRect)blurCroppingRect
{
	NSValue *value = [self.blurFilter valueForKey:CKBlurViewBoundsKey];
	return value ? [value CGRectValue] : CGRectNull;
}

- (void)setBlurEdges:(BOOL)blurEdges
{
	[self.blurFilter setValue:@(!blurEdges) forKey:CKBlurViewHardEdgesKey];
}

- (void)setTintColorFilter:(CAFilter *)filter
{
    self.colorFilter = filter;
    self.layer.filters = @[ self.colorFilter , self.blurFilter ];
}

- (BOOL)blurEdges
{
	return ![[self.blurFilter valueForKey:CKBlurViewHardEdgesKey] boolValue];
}

@end
