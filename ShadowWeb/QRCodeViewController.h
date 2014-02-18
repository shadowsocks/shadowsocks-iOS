//
// Created by clowwindy on 14-2-17.
// Copyright (c) 2014 clowwindy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ZXingObjC/ZXingObjC.h>

typedef void (^QRCodeViewControllerReturnBlock)(NSString *code);

@interface QRCodeViewController : UIViewController<ZXCaptureDelegate>

-(id)initWithReturnBlock:(QRCodeViewControllerReturnBlock)block;

@end