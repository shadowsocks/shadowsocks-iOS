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
    [self.delegate SWBTabViewDidClickCloseButton:self];
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
    titleLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight
//        |UIViewAutoresizingFlexibleBottomMargin 
//        | UIViewAutoresizingFlexibleLeftMargin
//        | UIViewAutoresizingFlexibleRightMargin 
//        | UIViewAutoresizingFlexibleTopMargin 
        | UIViewAutoresizingFlexibleWidth;
    titleLabel.font = [UIFont fontWithName:@"Helvetica" size:13];
//    titleLabel.minimumFontSize = 12;
    titleLabel.minimumScaleFactor = 0.9;
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.backgroundColor = [UIColor clearColor];
//    titleLabel.lineBreakMode = UILineBreakModeMiddleTruncation;
    // TODO add a setting to do this
    titleLabel.shadowOffset = CGSizeMake(0, 1);
    titleLabel.shadowColor = [UIColor whiteColor];
    titleLabel.text = NSLocalizedString(@"New Tab", @"New Tab");
    [self addSubview:titleLabel];
    
    // progess
    
//    progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(29, 27, self.bounds.size.width - 60, 10)];
//    [progressView setProgressViewStyle:UIProgressViewStyleBar];
//    progressView.progress = 0.0;
//    progressView.transform = CGAffineTransformMakeScale(1, 0.75);
//    progressView.alpha = 0.5;
//    progressView.autoresizingMask = UIViewAutoresizingFlexibleHeight
//    //        |UIViewAutoresizingFlexibleBottomMargin 
//    //        | UIViewAutoresizingFlexibleLeftMargin
//    //        | UIViewAutoresizingFlexibleRightMargin 
//    //        | UIViewAutoresizingFlexibleTopMargin 
//    | UIViewAutoresizingFlexibleWidth;
//    progressView.contentMode = UIViewContentModeRedraw;
//    [self addSubview: progressView];
    
    // activity
    
    indicatorView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(self.bounds.size.width - 40, 8, 21, 21)];
    indicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    [indicatorView startAnimating];
    indicatorView.autoresizingMask = UIViewAutoresizingFlexibleHeight
    //        |UIViewAutoresizingFlexibleBottomMargin 
    | UIViewAutoresizingFlexibleLeftMargin;
    //        | UIViewAutoresizingFlexibleRightMargin 
    //        | UIViewAutoresizingFlexibleTopMargin 
//    | UIViewAutoresizingFlexibleWidth;
    [self addSubview:indicatorView];
    
//    [progressView release];
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
#define kPaddingTop 1.0
#define kPaddingBottom 2.5
#define kCtlX 5
#define kCtlY 0
#define kTargetX 8
#define kTargetY 10
#define kTotalXDelta 20
// don't touch this!! it's magic!!

#define kShadowColor 0.45
#define kShadowOffset CGSizeMake(0, 2)
#define kShadowBlur 4
#define kTabViewFocusedGradTopColor 0.999
#define kTabViewFocusedGradBottomColor 0.7
#define kTabViewGradTopColor 0.9
#define kTabViewGradBottomColor 0.55
#define kTabViewHighlightedGradTopColor 0.8
#define kTabViewHighlightedGradBottomColor 0.5
#define kTabViewFocusedHighlightedGradTopColor 0.95
#define kTabViewFocusedHighlightedGradBottomColor 0.6

-(void)addOutline:(CGContextRef)context width:(CGFloat)width height:(CGFloat)height close:(BOOL)close
{
	CGContextMoveToPoint(context, 0, kPaddingTop);
//	CGContextAddLineToPoint(context, 4, height-8);
//    CGContextAddArcToPoint(context, 4, height-8, 4 * 2, height - 4, 4);
    
    // draw left half
    CGContextAddQuadCurveToPoint(context, kCtlX, kPaddingTop + kCtlY, kTargetX, kTargetY + kPaddingTop);
//	CGContextAddLineToPoint(context, kTotalXDelta - kTargetX, height - kTargetY - kPaddingBottom);
    CGContextAddQuadCurveToPoint(context, kTotalXDelta - kCtlX, height - kPaddingBottom - kCtlY, kTotalXDelta, height - kPaddingBottom);
    
    // draw bottom
	CGContextAddLineToPoint(context, width - kTotalXDelta, height - kPaddingBottom);
    
    //draw right half
	CGContextAddQuadCurveToPoint(context, width - (kTotalXDelta - kCtlX), height - kPaddingBottom - kCtlY, width - (kTotalXDelta - kTargetX), height - kTargetY - kPaddingBottom);
//	CGContextAddLineToPoint(context, width - (kTotalXDelta - kTargetX), height - kTargetY - kPaddingBottom);
	CGContextAddQuadCurveToPoint(context, width - kCtlX, kPaddingTop + kCtlY, width, kPaddingTop);
    
//	CGContextAddLineToPoint(context, width, 2);
//	CGContextAddLineToPoint(context, 10, 2);
	
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
//    CGContextClipToRect(context, rect);
    
    CGColorSpaceRef myColorspace = CGColorSpaceCreateDeviceRGB();
    
	CGFloat height = self.bounds.size.height;
    CGFloat width = self.bounds.size.width;
//	CGContextClip(context);
    
    // draw shadow
    
    CGContextSaveGState(context);
    
    CGFloat shadowColorComponents[4] = {
        kShadowColor,kShadowColor, kShadowColor, 1.0};
    CGColorRef myColor = CGColorCreate(myColorspace, shadowColorComponents);
    CGContextSetShadowWithColor(context, kShadowOffset, kShadowBlur, myColor);
    CGColorRelease(myColor);
    [self addOutline:context width:width height:height close:YES];
    CGContextFillPath(context);
    
    CGContextRestoreGState(context);
    
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
    myEndPoint.y = height;//    CGContextSetRGBFillColor(context, 1, 0, 0, 1);
//    CGContextFillRect(context, rect);
    
    

    
	[self addOutline:context width:width height:height close:YES];

	// Clip to the current path using the even-odd rule.
	CGContextEOClip(context);
    
    CGContextDrawLinearGradient(context, myGradient, myStartPoint,
                                myEndPoint,
                                kCGGradientDrawsAfterEndLocation);
    CGGradientRelease(myGradient);
	CGContextRestoreGState(context);
    
    // draw line
    
    CGContextSetLineWidth(context, 1);
    CGContextSetRGBStrokeColor(context, 0.3, 0.3, 0.3, 1);
    CGContextSetLineWidth(context, 0.5);
	[self addOutline:context width:width height:height close:NO];
    CGContextDrawPath(context, kCGPathStroke);
    
    // draw top line
    
    CGContextSetLineWidth(context, 2);
    if (self.focused) {
        CGContextSetRGBStrokeColor(context, 0.99, 0.99, 0.99, 1);
    } else {
        CGContextSetRGBStrokeColor(context, 0.6, 0.6, 0.6, 1);
    }
    
    CGContextMoveToPoint(context, 1, 0);
    CGContextAddLineToPoint(context, width - 1, 0);
    CGContextStrokePath(context);
    
    CGColorSpaceRelease(myColorspace);
}

- (void)setTitle:(NSString *)newTitle {
    title = newTitle;
    titleLabel.text = title;
    closeButton.accessibilityValue = title;
}

//-(void)setPercentage:(float)newPercentage {
//    percentage = newPercentage;
//    progressView.progress = newPercentage;
//}

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
