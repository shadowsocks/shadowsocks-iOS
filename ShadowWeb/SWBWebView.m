//
//  SWBWebView.m
//  AquaWeb
//
//  Created by clowwindy on 11-6-16.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "SWBWebView.h"
#import <QuartzCore/QuartzCore.h>

@implementation SWBWebView

//+(Class)layerClass {
//    return [CATiledLayer class];
//}


//-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
//    
//}
//
//- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
//    UITouch *theTouch = [touches anyObject];
//    if ([theTouch tapCount] == 2) {
//        [self becomeFirstResponder];
//        UIMenuItem *menuItem = [[UIMenuItem alloc] initWithTitle:@"Change Color" action:@selector(changeColor:)];
//        UIMenuController *menuCont = [UIMenuController sharedMenuController];
//        [menuCont setTargetRect:self.frame inView:self.superview];
//        menuCont.arrowDirection = UIMenuControllerArrowLeft;
//        menuCont.menuItems = [NSArray arrayWithObject:menuItem];
//        [menuCont setMenuVisible:YES animated:YES];
//    }
//    [super touchesEnded:touches withEvent:event];
//}
//- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {}

- (BOOL)canBecomeFirstResponder { return YES; }

- (void)changeColor:(id)sender {
    //    if ([self.viewColor isEqual:[UIColor blackColor]]) {
    //        self.viewColor = [UIColor redColor];
    //    } else {
    //        self.viewColor = [UIColor blackColor];
    //    }
    [self setNeedsDisplay];
}

- (CGSize)windowSize
{
    CGSize size;
    size.width = [[self stringByEvaluatingJavaScriptFromString:@"window.innerWidth"] integerValue];
    size.height = [[self stringByEvaluatingJavaScriptFromString:@"window.innerHeight"] integerValue];
    return size;
}

- (CGPoint)scrollOffset
{
    CGPoint pt;
    pt.x = [[self stringByEvaluatingJavaScriptFromString:@"window.pageXOffset"] integerValue];
    pt.y = [[self stringByEvaluatingJavaScriptFromString:@"window.pageYOffset"] integerValue];
    return pt;
}

-(NSString *)lastClickedLink {
    NSString *urlString = [self stringByEvaluatingJavaScriptFromString:@"AquaWebGetLastLink()"];
    if ([NSURL URLWithString:urlString] == nil) {
        return [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    } else {
        return urlString;
    }
}

-(NSString *)lastClickedLinkText {
    NSString *urlString = [self stringByEvaluatingJavaScriptFromString:@"AquaWebGetLastLinkText()"];
    return urlString;
}

-(NSString *)lastImageSrc {
    NSString *urlString = [self stringByEvaluatingJavaScriptFromString:@"AquaWebGetLastImageSrc()"];
    if ([NSURL URLWithString:urlString] == nil) {
        return [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    } else {
        return urlString;
    }
}

-(void)openLastClickedLink {
    [self stringByEvaluatingJavaScriptFromString:@"AquaWebOpenLastLink()"];
}

-(NSString *)locationHref {
    NSString *urlString = [self stringByEvaluatingJavaScriptFromString:@"window.location.href"];
    if ([NSURL URLWithString:urlString] == nil) {
        return [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    } else {
        return urlString;
    }
}

-(NSString *)pageTitle {
    return [self stringByEvaluatingJavaScriptFromString:@"document.title"];
}

-(NSString *)selection {
    NSString *selection = [self stringByEvaluatingJavaScriptFromString:@"if(window.getSelection()){window.getSelection().toString()}else{""}"];
    return selection;
}

-(UIScrollView *)scrollView {
    for (UIView *view in self.subviews) {
        if ([view isKindOfClass:[UIScrollView class]]) {
            UIScrollView *scrollView = (UIScrollView *)view;
            return scrollView;
        }
    }
    NSLog(@"scrollView not found in webView");
    return nil;
}

@end
