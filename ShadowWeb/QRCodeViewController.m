//
// Created by clowwindy on 14-2-17.
// Copyright (c) 2014 clowwindy. All rights reserved.
//

#import "QRCodeViewController.h"


@implementation QRCodeViewController {
    QRCodeViewControllerReturnBlock returnBlock;
    UIView *cameraView;
    ZXCapture *capture;
    UIButton *cancelButton;
    BOOL stopped;
}

- (id)initWithReturnBlock:(QRCodeViewControllerReturnBlock)block {
    self = [super init];
    if (self) {
        returnBlock = block;
        stopped = NO;
    }
    return self;
}

- (void)viewDidLoad {
    capture = [[ZXCapture alloc] init];
    capture.rotation = 90.0f;
    capture.camera = capture.back;
    capture.layer.frame = self.view.bounds;
    cameraView = [[UIView alloc] initWithFrame:self.view.bounds];
    cameraView.autoresizingMask = (UIViewAutoresizingFlexibleTopMargin |
            UIViewAutoresizingFlexibleBottomMargin |
            UIViewAutoresizingFlexibleLeftMargin |
            UIViewAutoresizingFlexibleRightMargin |
            UIViewAutoresizingFlexibleWidth |
            UIViewAutoresizingFlexibleHeight);
    cameraView.backgroundColor = [UIColor blackColor];
    [cameraView.layer addSublayer:capture.layer];
    [self.view addSubview:cameraView];
    capture.delegate = self;
    
#if !TARGET_IPHONE_SIMULATOR
    AVCaptureDevice *currentDevice = capture.captureDevice;
    if ([currentDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]){
        NSError *error = nil;
        [currentDevice lockForConfiguration:&error];
        if (!error) {
            [currentDevice setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
            [currentDevice unlockForConfiguration];
        }
    }
#endif
    
    cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.bounds.size.width - 44 - 10, 20, 44, 44)];
    [cancelButton setImage:[UIImage imageNamed:@"cancel"] forState:UIControlStateNormal];
    [cancelButton addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:cancelButton];
}

- (void)cancel {
    [capture stop];
    [self dismissModalViewControllerAnimated:YES];
}

- (void)captureResult:(ZXCapture *)_capture result:(ZXResult *)result {
    if (result && !stopped) {
        stopped = YES;
        [capture stop];
        [self dismissModalViewControllerAnimated:YES];
        returnBlock([result text]);
    }

}

@end