//
//  SWBNewTabButton.m
//  SWBuaWeb
//
//  Created by clowwindy on 11-6-12.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "SWBNewTabButton.h"


@implementation SWBNewTabButton


-(void) loadDefaults {
    self.contentMode = UIViewContentModeLeft;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self loadDefaults];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        //
        [self loadDefaults];
    }
    return self;
}

#define kCrossFillColor 0.99
#define kCrossPressedFillColor 0.7
#define kCrossStrokeColor 0.1
#define kCrossPressedShadowColor 0.0
#define kCrossShadowColor 1.0
#define kCrossPadding 10
#define kCrossWidth 6

-(void)addCross:(CGContextRef)context width:(CGFloat)width height:(CGFloat)height
{
    CGFloat padding = kCrossPadding;
    CGFloat crossWidth = kCrossWidth;
    
    CGFloat x1 = padding;
    CGFloat x2 = (height - crossWidth) / 2;
    CGFloat x3 = x2 + crossWidth;
    CGFloat x4 = height - padding;
    
	CGContextMoveToPoint(context, x1, x2);
    CGContextAddLineToPoint(context, x1, x3);
    CGContextAddLineToPoint(context, x2, x3);
    CGContextAddLineToPoint(context, x2, x4);
    CGContextAddLineToPoint(context, x3, x4);
    CGContextAddLineToPoint(context, x3, x3);
    CGContextAddLineToPoint(context, x4, x3);
    CGContextAddLineToPoint(context, x4, x2);
    CGContextAddLineToPoint(context, x3, x2);
    CGContextAddLineToPoint(context, x3, x1);
    CGContextAddLineToPoint(context, x2, x1);
    CGContextAddLineToPoint(context, x2, x2);
    CGContextAddLineToPoint(context, x1, x2);
    
    CGContextClosePath(context);
}


-(void)drawRect:(CGRect)rect {
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //draw circle
    
    CGFloat fillColor = self.highlighted ? kCrossPressedFillColor : kCrossFillColor;
    CGFloat fillColorComponents[4] = {
        fillColor, fillColor, fillColor, 1.0};
    CGFloat strokeColorComponents[4] = {
            kCrossStrokeColor, kCrossStrokeColor, kCrossStrokeColor, 1.0};
    CGContextSetFillColor(context, fillColorComponents);
    CGContextSetStrokeColor(context, strokeColorComponents);
    CGContextSetLineWidth(context, 0.5);
    CGContextSetLineJoin(context, kCGLineJoinMiter);
    
    CGContextSaveGState(context);
    
//    if (self.highlighted) {
//        CGColorSpaceRef myColorspace = CGColorSpaceCreateDeviceRGB();
//        CGFloat shadowColorComponents[4] = {
//            kCrossPressedShadowColor, kCrossPressedShadowColor, kCrossPressedShadowColor, 1.0};
//        CGColorRef myColor = CGColorCreate(myColorspace, shadowColorComponents);
//        CGContextSetShadowWithColor(context, CGSizeMake(0, 0), 20, myColor);
//        CGColorSpaceRelease(myColorspace);
//        CGColorRelease(myColor);
//    } else {
//        CGColorSpaceRef myColorspace = CGColorSpaceCreateDeviceRGB();
//        CGFloat shadowColorComponents[4] = {
//            kCrossShadowColor, kCrossShadowColor, kCrossShadowColor, 1.0};
//        CGColorRef myColor = CGColorCreate(myColorspace, shadowColorComponents);
//        CGContextSetShadowWithColor(context, CGSizeMake(0, 1.5), 0, myColor);
//        CGColorSpaceRelease(myColorspace);
//        CGColorRelease(myColor);
//    }

    [self addCross:context width:self.bounds.size.width height:self.bounds.size.height];
    
    CGContextFillPath(context);
    
    CGContextRestoreGState(context);
    
    [self addCross:context width:self.bounds.size.width height:self.bounds.size.height];
    CGContextStrokePath(context);
    
}

-(void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    [self setNeedsDisplay];
}



@end
