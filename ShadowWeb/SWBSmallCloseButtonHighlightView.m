//
//  SWBSmallCloseButtonHighlightView.m
//  SWBuaWeb
//
//  Created by clowwindy on 11-6-10.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "SWBSmallCloseButtonHighlightView.h"


@implementation SWBSmallCloseButtonHighlightView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

#define kButtonBGColor 0.1
#define kButtonFGColor 0.9
#define kButtonLineWidth 2
#define kButtonShadowColor 0.0
#define kButtonHighlightedScale 1.5

-(void)drawRect:(CGRect)rect {
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGColorSpaceRef myColorspace = CGColorSpaceCreateDeviceRGB();
    
	CGFloat height = self.bounds.size.height;
    CGFloat width = self.bounds.size.width;
    CGFloat radiusToDraw = 8;
    
    //draw circle
    
    CGContextAddArc(context, width / 2, height / 2, radiusToDraw, 0, 2 * M_PI, 0);
    
    CGFloat shadowColorComponents[4] = {
        kButtonShadowColor, kButtonShadowColor, kButtonShadowColor, 1.0};
    CGColorRef myColor = CGColorCreate(myColorspace, shadowColorComponents);
    CGContextSetShadowWithColor(context, CGSizeMake(0, 0), 20, myColor);
    CGColorRelease(myColor);
    
    CGFloat bgColorComponents[4] = {
        kButtonBGColor, kButtonBGColor, kButtonBGColor, 1.0};
    
    CGContextSetFillColor(context, bgColorComponents);
    CGContextFillPath(context);
    
    // draw x
    
    CGFloat centerX = width / 2;
    CGFloat centerY = height / 2;
    CGFloat delta = radiusToDraw / 2.2;
    
    CGContextMoveToPoint(context, centerX - delta, centerY - delta);
    CGContextAddLineToPoint(context, centerX + delta, centerY + delta);
    
    CGContextMoveToPoint(context, centerX - delta, centerY + delta);
    CGContextAddLineToPoint(context, centerX + delta, centerY - delta);
    
    CGFloat fgColorComponents[4] = {
        kButtonFGColor, kButtonFGColor, kButtonFGColor, 1.0};
    CGContextSetStrokeColor(context, fgColorComponents);
    CGContextSetLineWidth(context, kButtonLineWidth);
    
    
    CGContextStrokePath(context);
    
    CGColorSpaceRelease(myColorspace);
    
}


@end
