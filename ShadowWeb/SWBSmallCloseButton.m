//
//  SWBSmallCloseButton.m
//  SWBuaWeb
//
//  Created by clowwindy on 11-6-10.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "SWBSmallCloseButton.h"


@implementation SWBSmallCloseButton

@synthesize radius;

-(void) loadDefaults {
    radius = 7;
    highlightView = [[SWBSmallCloseButtonHighlightView alloc] init];
    highlightView.backgroundColor = [UIColor clearColor];
    highlightView.userInteractionEnabled = NO;
    highlightView.frame = self.bounds;
    highlightView.center = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
    highlightView.hidden = YES;
    [self addSubview:highlightView];
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

#define kButtonBGColor 0.5
#define kButtonFGColor 1
#define kButtonLineWidth 1.5
#define kButtonShadowColor 0.0
#define kButtonHighlightedScale 1.5

-(void)drawRect:(CGRect)rect {
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
	CGFloat height = self.bounds.size.height;
    CGFloat width = self.bounds.size.width;
    CGFloat radiusToDraw;
    if (self.highlighted) {
        radiusToDraw = radius * 1.0;
    } else {
        radiusToDraw = radius;
    }

    //draw circle
    
    CGContextAddArc(context, width / 2, height / 2, radiusToDraw, 0, 2 * M_PI, 0);
    
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
    
}

-(void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    [self setNeedsDisplay];
    
    if (highlighted) {
//        self.transform = CGAffineTransformMakeScale(kButtonHighlightedScale, kButtonHighlightedScale);
        highlightView.hidden = NO;
        highlightView.alpha = 1;
    } else {
        [UIView beginAnimations:@"buttonHighlighted" context:NULL]; 
        [UIView setAnimationDuration:0.6];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
        highlightView.alpha = 0;
        [UIView commitAnimations];        
    }
    
}

@end
