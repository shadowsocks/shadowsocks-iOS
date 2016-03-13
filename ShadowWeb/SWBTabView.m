//
//  SWBTabView.m
//  SWBuaWeb
//
//  Created by clowwindy on 11-6-10.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "SWBTabView.h"


@implementation SWBTabView

@synthesize delegate;
@synthesize title;
@synthesize focused;
//@synthesize percentage;
@synthesize loading;

-(void)closeButtonDidClick {
    [self.delegate tabViewDidClickCloseButton:self];
}

-(void) loadDefaults {
    self.userInteractionEnabled = YES;
    
    self.opaque = NO;
    self.backgroundColor = [UIColor clearColor];
//    self->gradTopColor = 0.95;
//    self->gradBottomColor = 0.6;
    self->closeButton = [[SWBSmallCloseButton alloc] initWithFrame:CGRectMake(10, 0, 37, 37)];
    [closeButton addTarget:self action:@selector(closeButtonDidClick) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:closeButton];
    [closeButton setAccessibilityLabel:NSLocalizedString(@"Close", @"")];
    
    // title label
    titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(40, 8, self.bounds.size.width - 70, 21)];
    titleLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    titleLabel.font = [UIFont fontWithName:@"Helvetica" size:13];
//    titleLabel.minimumFontSize = 12;
    if ([titleLabel respondsToSelector:@selector(minimumScaleFactor)]) {
        titleLabel.minimumScaleFactor = 0.9;
    }
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.backgroundColor = [UIColor clearColor];
    // TODO add a setting to do this
    titleLabel.shadowOffset = CGSizeMake(0, 1);
    titleLabel.shadowColor = [UIColor whiteColor];
    titleLabel.text = NSLocalizedString(@"New Tab", @"New Tab");
    [self addSubview:titleLabel];
    
    // activity
    
    indicatorView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(self.bounds.size.width - 40, 8, 21, 21)];
    indicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    [indicatorView startAnimating];
    indicatorView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin;
    [self addSubview:indicatorView];
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


// don't touch this!! it's magic!!
#define kPaddingTop 0.0
#define kPaddingBottom 2.0
#define kCtlX 5
#define kCtlY 0
#define kTargetX 8
#define kTargetY 10
#define kTotalXDelta 20
// don't touch this!! it's magic!!

#define kShadowColor 0.45
#define kShadowOffset CGSizeMake(0, 2)
#define kShadowBlur 4
#define kTabViewFocusedGradTopColor 1
#define kTabViewFocusedGradBottomColor 1
#define kTabViewGradTopColor 0.93
#define kTabViewGradBottomColor 0.93
#define kTabViewHighlightedGradTopColor 0.85
#define kTabViewHighlightedGradBottomColor 0.85
#define kTabViewFocusedHighlightedGradTopColor 0.95
#define kTabViewFocusedHighlightedGradBottomColor 0.95

-(void)addOutline:(CGContextRef)context width:(CGFloat)width height:(CGFloat)height close:(BOOL)close
{
	CGContextMoveToPoint(context, 0, kPaddingTop);
    
    // draw left half
    CGContextAddQuadCurveToPoint(context, kCtlX, kPaddingTop + kCtlY, kTargetX, kTargetY + kPaddingTop);
    CGContextAddQuadCurveToPoint(context, kTotalXDelta - kCtlX, height - kPaddingBottom - kCtlY, kTotalXDelta, height - kPaddingBottom);
    
    // draw bottom
	CGContextAddLineToPoint(context, width - kTotalXDelta, height - kPaddingBottom);
    
    //draw right half
	CGContextAddQuadCurveToPoint(context, width - (kTotalXDelta - kCtlX), height - kPaddingBottom - kCtlY, width - (kTotalXDelta - kTargetX), height - kTargetY - kPaddingBottom);
	CGContextAddQuadCurveToPoint(context, width - kCtlX, kPaddingTop + kCtlY, width, kPaddingTop);
    
	
    // And close the subpath.
    if (close) {
        CGContextClosePath(context);
    }
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGColorSpaceRef myColorspace = CGColorSpaceCreateDeviceRGB();
    
	CGFloat height = self.bounds.size.height;
    CGFloat width = self.bounds.size.width;
    
    // draw shadow
    
//    CGContextSaveGState(context);
//    
//    CGFloat shadowColorComponents[4] = {
//        kShadowColor,kShadowColor, kShadowColor, 1.0};
//    CGColorRef myColor = CGColorCreate(myColorspace, shadowColorComponents);
//    CGContextSetShadowWithColor(context, kShadowOffset, kShadowBlur, myColor);
//    CGColorRelease(myColor);
//    [self addOutline:context width:width height:height close:YES];
//    CGContextFillPath(context);
//    
//    CGContextRestoreGState(context);
    
    // draw gradient
    CGContextSaveGState(context);
    
    CGGradientRef myGradient;
    size_t num_locations = 2;
    CGFloat locations[2] = { 0.0, 1.0 };
    if(self.highlighted) {
        if (self.focused) {
            CGFloat components[8] = {
                kTabViewFocusedHighlightedGradTopColor, kTabViewFocusedHighlightedGradTopColor, kTabViewFocusedHighlightedGradTopColor, 1.0,
                kTabViewFocusedHighlightedGradBottomColor, kTabViewFocusedHighlightedGradBottomColor, kTabViewFocusedHighlightedGradBottomColor, 1.0 };
            
            myGradient = CGGradientCreateWithColorComponents (myColorspace, components,
                                                              locations, num_locations);        
        } else {
        CGFloat components[8] = {
                kTabViewHighlightedGradTopColor, kTabViewHighlightedGradTopColor, kTabViewHighlightedGradTopColor, 1.0,
                kTabViewHighlightedGradBottomColor, kTabViewHighlightedGradBottomColor, kTabViewHighlightedGradBottomColor, 1.0 };
            
            myGradient = CGGradientCreateWithColorComponents (myColorspace, components,
                                                              locations, num_locations);
        }
    } else if (self.focused) {
        CGFloat components[8] = {
            kTabViewFocusedGradTopColor, kTabViewFocusedGradTopColor, kTabViewFocusedGradTopColor, 1.0,
            kTabViewFocusedGradBottomColor, kTabViewFocusedGradBottomColor, kTabViewFocusedGradBottomColor, 1.0 };
        
        myGradient = CGGradientCreateWithColorComponents (myColorspace, components,
                                                          locations, num_locations);
    } else {
        CGFloat components[8] = {
            kTabViewGradTopColor, kTabViewGradTopColor, kTabViewGradTopColor, 1.0,
            kTabViewGradBottomColor, kTabViewGradBottomColor, kTabViewGradBottomColor, 1.0 };
        
        myGradient = CGGradientCreateWithColorComponents (myColorspace, components,
                                                          locations, num_locations);        
    }
    
    CGPoint myStartPoint, myEndPoint;
    myStartPoint.x = 0;
    myStartPoint.y = 0;
    myEndPoint.x = 0;
    myEndPoint.y = height;
    
	[self addOutline:context width:width height:height close:YES];

	// Clip to the current path using the even-odd rule.
	CGContextEOClip(context);
    
    CGContextDrawLinearGradient(context, myGradient, myStartPoint,
                                myEndPoint,
                                kCGGradientDrawsAfterEndLocation);
    CGGradientRelease(myGradient);
	CGContextRestoreGState(context);
    
    // draw line
    
    CGContextSetLineWidth(context, 0.5);
    CGContextSetRGBStrokeColor(context, 0.1, 0.1, 0.1, 1);
    CGContextSetLineWidth(context, 0.5);
	[self addOutline:context width:width height:height close:NO];
    CGContextDrawPath(context, kCGPathStroke);
    
    // draw top white line
    
    CGContextSetLineWidth(context, 1);
    if (self.focused) {
        CGContextSetRGBStrokeColor(context, 0.99, 0.99, 0.99, 1);
    } else {
        CGContextSetRGBStrokeColor(context, 0.6, 0.6, 0.6, 1);
    }
    
    CGContextMoveToPoint(context, 3, 0);
    CGContextAddLineToPoint(context, width - 3, 0);
    CGContextStrokePath(context);
    
    CGColorSpaceRelease(myColorspace);
}

- (void)setTitle:(NSString *)newTitle {
    title = newTitle;
    titleLabel.text = title;
    closeButton.accessibilityValue = title;
}

-(void)setLoading:(BOOL)newLoading {
    loading = newLoading;
    if (newLoading) {
        [indicatorView startAnimating];
//        progressView.hidden = NO;
    } else {
        [indicatorView stopAnimating];
//        progressView.hidden = YES;
    }
}

-(void)setFocused:(BOOL)newFocused {
    focused = newFocused;
    [self setNeedsDisplay];
}

-(void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    [self setNeedsDisplay];
}

-(void)layoutSubviews {
    [super layoutSubviews];
//    [self setNeedsDisplay];
}

-(UILabel *)titleLabel {
    return titleLabel;
}


@end
