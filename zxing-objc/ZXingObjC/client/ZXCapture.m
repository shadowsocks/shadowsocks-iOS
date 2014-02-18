/*
 * Copyright 2012 ZXing authors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "ZXCapture.h"

#if !TARGET_IPHONE_SIMULATOR
#include "ZXCGImageLuminanceSource.h"
#include "ZXBinaryBitmap.h"
#include "ZXDecodeHints.h"
#include "ZXHybridBinarizer.h"
#include "ZXMultiFormatReader.h"
#include "ZXReader.h"
#include "ZXResult.h"

#if TARGET_OS_EMBEDDED || TARGET_IPHONE_SIMULATOR
#import <UIKit/UIKit.h>
#define ZXCaptureOutput AVCaptureOutput
#define ZXMediaTypeVideo AVMediaTypeVideo
#define ZXCaptureConnection AVCaptureConnection
#else
#define ZXCaptureOutput QTCaptureOutput
#define ZXCaptureConnection QTCaptureConnection
#define ZXMediaTypeVideo QTMediaTypeVideo
#endif

#if ZXAV(1)+0
static bool isIPad();
#endif

#if TARGET_OS_IPHONE
#   if __IPHONE_OS_VERSION_MIN_REQUIRED < 60000
#       define KS_DISPATCH_RELEASE(q) (dispatch_release(q))
#   endif
#else
#   if MAC_OS_X_VERSION_MIN_REQUIRED < 1080
#       define KS_DISPATCH_RELEASE(q) (dispatch_release(q))
#   endif
#endif
#ifndef KS_DISPATCH_RELEASE
#   define KS_DISPATCH_RELEASE(q)
#endif

@interface ZXCapture ()

@property (nonatomic, assign) dispatch_queue_t captureQueue;

@end

@implementation ZXCapture

@synthesize delegate;
@synthesize captureToFilename;
@synthesize transform;
@synthesize rotation;
@synthesize hints;

// Adapted from http://blog.coriolis.ch/2009/09/04/arbitrary-rotation-of-a-cgimage/ and https://github.com/JanX2/CreateRotateWriteCGImage
- (CGImageRef)createRotatedImage:(CGImageRef)original degrees:(float)degrees CF_RETURNS_RETAINED {
  if (degrees == 0.0f) {
    CGImageRetain(original);
    return original;
  } else {
    double radians = degrees * M_PI / 180;

#if TARGET_OS_EMBEDDED || TARGET_IPHONE_SIMULATOR
    radians = -1 * radians;
#endif

    size_t _width = CGImageGetWidth(original);
    size_t _height = CGImageGetHeight(original);

    CGRect imgRect = CGRectMake(0, 0, _width, _height);
    CGAffineTransform _transform = CGAffineTransformMakeRotation(radians);
    CGRect rotatedRect = CGRectApplyAffineTransform(imgRect, _transform);

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL,
                                                 rotatedRect.size.width,
                                                 rotatedRect.size.height,
                                                 CGImageGetBitsPerComponent(original),
                                                 0,
                                                 colorSpace,
                                                 kCGBitmapAlphaInfoMask & kCGImageAlphaPremultipliedFirst);
    CGContextSetAllowsAntialiasing(context, FALSE);
    CGContextSetInterpolationQuality(context, kCGInterpolationNone);
    CGColorSpaceRelease(colorSpace);

    CGContextTranslateCTM(context,
                          +(rotatedRect.size.width/2),
                          +(rotatedRect.size.height/2));
    CGContextRotateCTM(context, radians);

    CGContextDrawImage(context, CGRectMake(-imgRect.size.width/2,
                                           -imgRect.size.height/2,
                                           imgRect.size.width,
                                           imgRect.size.height),
                       original);

    CGImageRef rotatedImage = CGBitmapContextCreateImage(context);
    CFRelease(context);

    return rotatedImage;
  }
}

- (ZXCapture *)init {
  if ((self = [super init])) {
    on_screen = running = NO;
    reported_width = 0;
    reported_height = 0;
    width = 1920;
    height = 1080;
    hard_stop = false;
    capture_device = 0;
    capture_device_index = -1;
    order_in_skip = 0;
    order_out_skip = 0;
    transform = CGAffineTransformIdentity;
    rotation = 0.0f;
    ZXQT({
        transform.a = -1;
      });
    self.reader = [ZXMultiFormatReader reader];
    self.hints = [ZXDecodeHints hints];
    _captureQueue = dispatch_queue_create("com.zxing.captureQueue", NULL);
  }
  return self;
}

- (BOOL)running {return running;}

- (BOOL)mirror {
  return mirror;
}

- (void)setMirror:(BOOL)mirror_ {
  if (mirror != mirror_) {
    mirror = mirror_;
    if (layer) {
      transform.a = -transform.a;
      [layer setAffineTransform:transform];
    }
  }
}

- (void)order_skip {
  order_out_skip = order_in_skip = 1;
}

- (ZXCaptureDevice *)device {
  if (capture_device) {
    return capture_device;
  }

  ZXCaptureDevice *zxd = nil;

#if ZXAV(1)+0
  NSArray *devices = 
    [ZXCaptureDevice
        ZXAV(devicesWithMediaType:)
      ZXQT(inputDevicesWithMediaType:) ZXMediaTypeVideo];

  if ([devices count] > 0) {
    if (capture_device_index == -1) {
      AVCaptureDevicePosition position = AVCaptureDevicePositionBack;
      if (camera == self.front) {
        position = AVCaptureDevicePositionFront;
      }

      for(unsigned int i=0; i < [devices count]; ++i) {
        ZXCaptureDevice *dev = [devices objectAtIndex:i];
        if (dev.position == position) {
          capture_device_index = i;
          zxd = dev;
          break;
        }
      }
    }
    
    if (!zxd && capture_device_index != -1) {
      zxd = [devices objectAtIndex:capture_device_index];
    }
  }
#endif

  if (!zxd) {
    zxd = 
      [ZXCaptureDevice
          ZXAV(defaultDeviceWithMediaType:)
        ZXQT(defaultInputDeviceWithMediaType:) ZXMediaTypeVideo];
  }

  capture_device = zxd;

  return zxd;
}

- (ZXCaptureDevice *)captureDevice {
  return capture_device;
}

- (void)setCaptureDevice:(ZXCaptureDevice *)device {
  if (device == capture_device) {
    return;
  }

  if(capture_device) {
    ZXQT({
      if ([capture_device isOpen]) {
        [capture_device close];
      }});
  }

  capture_device = device;
}

- (void)replaceInput {
  if ([session respondsToSelector:@selector(beginConfiguration)]) {
    [session performSelector:@selector(beginConfiguration)];
  }

  if (session && input) {
    [session removeInput:input];
    input = nil;
  }

  ZXCaptureDevice *zxd = [self device];
  ZXQT([zxd open:nil]);

  if (zxd) {
    input =
      [ZXCaptureDeviceInput deviceInputWithDevice:zxd
                                       ZXAV(error:nil)];
  }
  
  if (input) {
    ZXAV({
      NSString *preset = 0;
      if (!preset &&
          NSClassFromString(@"NSOrderedSet") && // Proxy for "is this iOS 5" ...
          [UIScreen mainScreen].scale > 1 &&
          isIPad() &&
          &AVCaptureSessionPresetiFrame960x540 != nil &&
          [zxd supportsAVCaptureSessionPreset:AVCaptureSessionPresetiFrame960x540]) {
        // NSLog(@"960");
        preset = AVCaptureSessionPresetiFrame960x540;
      }
      if (!preset) {
        // NSLog(@"MED");
        preset = AVCaptureSessionPresetMedium;
      }
      session.sessionPreset = preset;
    });
    [session addInput:input ZXQT(error:nil)];
  }

  if ([session respondsToSelector:@selector(commitConfiguration)]) {
    [session performSelector:@selector(commitConfiguration)];
  }
}

- (ZXCaptureSession *)session {
  if (session == 0) {
    session = [[ZXCaptureSession alloc] init];
    [self replaceInput];
  }
  return session;
}

- (void)stop {
  // NSLog(@"stop");

  if (!running) {
    return;
  }

  if (true ZXAV(&& self.session.running)) {
    // NSLog(@"stop running");
    [self.layer removeFromSuperlayer];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      [self.session stopRunning];
    });
  } else {
    // NSLog(@"already stopped");
  }
  running = false;
}

- (void)setOutputAttributes {
    NSString *key = (NSString *)kCVPixelBufferPixelFormatTypeKey;
    NSNumber *value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA];
    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithObject:value forKey:key];
    ZXQT({
      key = (NSString *)kCVPixelBufferWidthKey;
      value = [NSNumber numberWithUnsignedLong:width];
      [attributes setObject:value forKey:key]; 
      key = (NSString *)kCVPixelBufferHeightKey;
      value = [NSNumber numberWithUnsignedLong:height];
      [attributes setObject:value forKey:key];
    });
    [output ZXQT(setPixelBufferAttributes:)ZXAV(setVideoSettings:)attributes];
}

- (ZXCaptureVideoOutput *)output {
  if (!output) {
    output = [[ZXCaptureVideoOutput alloc] init];
    [self setOutputAttributes];
    [output ZXQT(setAutomaticallyDropsLateVideoFrames:)
                ZXAV(setAlwaysDiscardsLateVideoFrames:)YES];

    [output ZXQT(setDelegate:)ZXAV(setSampleBufferDelegate:)self
                  ZXAV(queue:self.captureQueue)];

    [self.session addOutput:output ZXQT(error:nil)];
  }
  return output;
}

- (void)start {
  // NSLog(@"start %@ %d %@ %@", self.session, running, output, delegate);

  if (hard_stop) {
    return;
  }

  if (delegate || luminance || binary) {
    // for side effects
    [self output];
  }
    
  if (false ZXAV(|| self.session.running)) {
    // NSLog(@"already running");
  } else {

    static int i = 0;
    if (++i == -2) {
      abort();
    }

    // NSLog(@"start running");
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      [self.session startRunning];
    });
  }
  running = true;
}

- (void)start_stop {
  // NSLog(@"ss %d %@ %d %@ %@ %@", running, delegate, on_screen, output, luminanceLayer, binary);
  if ((!running && (delegate || on_screen)) ||
      (!output &&
       (delegate ||
        (on_screen && (luminance || binary))))) {
    [self start];
  }
  if (running && !delegate && !on_screen) {
    [self stop];
  }
}

- (void)setDelegate:(id<ZXCaptureDelegate>)_delegate {
  delegate = _delegate;
  if (delegate) {
    hard_stop = false;
  }
  [self start_stop];
}

- (void)hard_stop {
  hard_stop = true;
  if (running) {
    [self stop];
  }
}

- (void)setLuminance:(BOOL)on {
  if (on && !luminance) {
    luminance = [CALayer layer];
  } else if (!on && luminance) {
    luminance = nil;
  }
}

- (CALayer *)luminance {
  return luminance;
}

- (void)setBinary:(BOOL)on {
  if (on && !binary) {
    binary = [CALayer layer];
  } else if (!on && binary) {
    binary = nil;
  }
}

- (CALayer *)binary {
  return binary;
}

- (CALayer *)layer {
  if (!layer) {
    layer = [[ZXCaptureVideoPreviewLayer alloc] initWithSession:self.session];

    ZXAV(layer.videoGravity = AVLayerVideoGravityResizeAspect);
    ZXAV(layer.videoGravity = AVLayerVideoGravityResizeAspectFill);
    
    [layer setAffineTransform:transform];
    layer.delegate = self;

    ZXQT({
      ProcessSerialNumber psn;
      GetCurrentProcess(&psn);
      TransformProcessType(&psn, 1);
    });
  }
  return layer;
}

- (void)runActionForKey:(NSString *)key
                 object:(id)anObject
              arguments:(NSDictionary *)dict {
  // NSLog(@" rAFK %@ %@ %@", key, anObject, dict); 
  (void)anObject;
  (void)dict;
  if ([key isEqualToString:kCAOnOrderIn]) {
    
    if (order_in_skip) {
      --order_in_skip;
      // NSLog(@"order in skip");
      return;
    }

    // NSLog(@"order in");

    on_screen = true;
    if (luminance && luminance.superlayer != layer) {
      // [layer addSublayer:luminance];
    }
    if (binary && binary.superlayer != layer) {
      // [layer addSublayer:binary];
    }
    [self start_stop];
  } else if ([key isEqualToString:kCAOnOrderOut]) {
    if (order_out_skip) {
      --order_out_skip;
      // NSLog(@"order out skip");
      return;
    }

    on_screen = false;
    // NSLog(@"order out");
    [self start_stop];
  }
}

- (id<CAAction>)actionForLayer:(CALayer *)_layer forKey:(NSString *)event {
  (void)_layer;

  // NSLog(@"layer event %@", event);

  // never animate
  [CATransaction setValue:[NSNumber numberWithFloat:0.0f]
                   forKey:kCATransactionAnimationDuration];

  // NSLog(@"afl %@ %@", _layer, event);
  if ([event isEqualToString:kCAOnOrderIn]
      || [event isEqualToString:kCAOnOrderOut]
      // || ([event isEqualToString:@"bounds"] && (binary || luminance))
      // || ([event isEqualToString:@"onLayout"] && (binary || luminance))
    ) {
    return self;
  } else if ([event isEqualToString:@"contents"] ) {
  } else if ([event isEqualToString:@"sublayers"] ) {
  } else if ([event isEqualToString:@"onLayout"] ) {
  } else if ([event isEqualToString:@"position"] ) {
  } else if ([event isEqualToString:@"bounds"] ) {
  } else if ([event isEqualToString:@"layoutManager"] ) {
  } else if ([event isEqualToString:@"transform"] ) {
  } else {
    NSLog(@"afl %@ %@", _layer, event);
  }
  return nil;
}

- (void)dealloc {
  if (input && session) {
    [session removeInput:input];
  }
  if (output && session) {
    [session removeOutput:output];
  }
  if (_captureQueue) {
    KS_DISPATCH_RELEASE(_captureQueue);
    _captureQueue = nil;
  }
}

- (void)captureOutput:(ZXCaptureOutput *)captureOutput
ZXQT(didOutputVideoFrame:(CVImageBufferRef)videoFrame
     withSampleBuffer:(QTSampleBuffer *)sampleBuffer)
ZXAV(didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer)
       fromConnection:(ZXCaptureConnection *)connection {
  @autoreleasepool {
    if (!cameraIsReady)
    {
      cameraIsReady = YES;
      if ([self.delegate respondsToSelector:@selector(captureCameraIsReady:)])
      {
        dispatch_async(dispatch_get_main_queue(), ^{
          [self.delegate captureCameraIsReady:self];
        });
      }
    }
             
    if (!captureToFilename && !luminance && !binary && !delegate) {
      // NSLog(@"skipping capture");
      return;
    }

    // NSLog(@"received frame");

    ZXAV(CVImageBufferRef videoFrame = CMSampleBufferGetImageBuffer(sampleBuffer));

    // NSLog(@"%ld %ld", CVPixelBufferGetWidth(videoFrame), CVPixelBufferGetHeight(videoFrame));
    // NSLog(@"delegate %@", delegate);

    ZXQT({
    if (!reported_width || !reported_height) {
      NSSize size = 
        [[[[input.device.formatDescriptions objectAtIndex:0]
            formatDescriptionAttributes] objectForKey:@"videoEncodedPixelsSize"] sizeValue];
      width = size.width;
      height = size.height;
      // NSLog(@"reported: %f x %f", size.width, size.height);
      [self performSelectorOnMainThread:@selector(setOutputAttributes) withObject:nil waitUntilDone:NO];
      reported_width = size.width;
      reported_height = size.height;
      if ([delegate  respondsToSelector:@selector(captureSize:width:height:)]) {
          dispatch_async(dispatch_get_main_queue(), ^{
              [delegate captureSize:self
                              width:[NSNumber numberWithFloat:size.width]
                             height:[NSNumber numberWithFloat:size.height]];
          });
      }
    }});

    (void)sampleBuffer;
    (void)captureOutput;
    (void)connection;

#if !TARGET_OS_EMBEDDED
    // The routines don't exist in iOS. There are alternatives, but a good
    // solution would have to figure out a reasonable path and might be
    // better as a post to url

    if (captureToFilename) {
      CGImageRef image = 
        [ZXCGImageLuminanceSource createImageFromBuffer:videoFrame];
      NSURL *url = [NSURL fileURLWithPath:captureToFilename];
      CGImageDestinationRef dest =
        CGImageDestinationCreateWithURL((__bridge CFURLRef)url, kUTTypePNG, 1, nil);
      CGImageDestinationAddImage(dest, image, nil);
      CGImageDestinationFinalize(dest);
      CGImageRelease(image);
      CFRelease(dest);
      self.captureToFilename = nil;
    }
#endif

    CGImageRef videoFrameImage = [ZXCGImageLuminanceSource createImageFromBuffer:videoFrame];
    CGImageRef rotatedImage = [self createRotatedImage:videoFrameImage degrees:rotation];
    CGImageRelease(videoFrameImage);

    ZXCGImageLuminanceSource *source = [[ZXCGImageLuminanceSource alloc] initWithCGImage:rotatedImage];
    CGImageRelease(rotatedImage);

    if (luminance) {
      CGImageRef image = source.image;
      CGImageRetain(image);
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0), dispatch_get_main_queue(), ^{
          luminance.contents = (__bridge id)image;
          CGImageRelease(image);
        });
    }

    if (binary || delegate) {
      ZXHybridBinarizer *binarizer = [[ZXHybridBinarizer alloc] initWithSource:source];

      if (binary) {
        CGImageRef image = [binarizer createImage];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0), dispatch_get_main_queue(), ^{
          binary.contents = (__bridge id)image;
          CGImageRelease(image);
        });
      }

      if (delegate) {
        ZXBinaryBitmap *bitmap = [[ZXBinaryBitmap alloc] initWithBinarizer:binarizer];

        NSError *error;
        ZXResult *result = [self.reader decode:bitmap hints:hints error:&error];
        if (result) {
          dispatch_async(dispatch_get_main_queue(), ^{
            [delegate captureResult:self result:result];
          });
        }
      }
    }
  }
}

- (BOOL)hasFront {
  NSArray *devices = 
    [ZXCaptureDevice
        ZXAV(devicesWithMediaType:)
      ZXQT(inputDevicesWithMediaType:) ZXMediaTypeVideo];
  return [devices count] > 1;
}

- (BOOL)hasBack {
  NSArray *devices = 
    [ZXCaptureDevice
        ZXAV(devicesWithMediaType:)
      ZXQT(inputDevicesWithMediaType:) ZXMediaTypeVideo];
  return [devices count] > 0;
}

- (BOOL)hasTorch {
  if ([self device]) {
    return false ZXAV(|| [self device].hasTorch);
  } else {
    return NO;
  }
}

- (int)front {
  return 0;
}

- (int)back {
  return 1;
}

- (int)camera {
  return camera;
}

- (BOOL)torch {
  return torch;
}

- (void)setCamera:(int)camera_ {
  if (camera  != camera_) {
    camera = camera_;
    capture_device_index = -1;
    capture_device = 0;
    [self replaceInput];
  }
}

- (void)setTorch:(BOOL)torch_ {
  torch = torch_;
  ZXAV({
      [input.device lockForConfiguration:nil];
      if (torch) {
        input.device.torchMode = AVCaptureTorchModeOn;
      } else {
        input.device.torchMode = AVCaptureTorchModeOff;
      }
      [input.device unlockForConfiguration];
    });
}

- (void)setTransform:(CGAffineTransform)transform_ {
  transform = transform_;
  [layer setAffineTransform:transform];
}

@end

// If you try to define this higher, there (seem to be) clashes with something(s) defined
// in the includes ...

#if ZXAV(1)+0
#include <sys/types.h>
#include <sys/sysctl.h>
// Gross, I know, but ...
static bool isIPad() {
  static int is_ipad = -1;
  if (is_ipad < 0) {
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0); // Get size of data to be returned.
    char *name = (char *)malloc(size);
    sysctlbyname("hw.machine", name, &size, NULL, 0);
    NSString *machine = [NSString stringWithCString:name encoding:NSASCIIStringEncoding];
    free(name);
    is_ipad = [machine hasPrefix:@"iPad"];
  }
  return !!is_ipad;
}
#endif

#else

@implementation ZXCapture

- (id)init {
  if ((self = [super init])) {

  }
  return 0;
}

- (BOOL)running {return NO;}

- (CALayer *)layer {
  return 0;
}

- (CALayer *)luminance {
  return 0;
}

- (CALayer *)binary {
  return 0;
}

- (void)setLuminance:(BOOL)on {}
- (void)setBinary:(BOOL)on {}

- (void)hard_stop {
}

- (BOOL)hasFront {
  return YES;
}

- (BOOL)hasBack {
  return NO;
}

- (BOOL)hasTorch {
  return NO;
}

- (int)front {
  return 0;
}

- (int)back {
  return 1;
}

- (int)camera {
  return self.front;
}

- (BOOL)torch {
  return NO;
}

- (void)setCamera:(int)camera_ {}
- (void)setTorch:(BOOL)torch {}
- (void)order_skip {}
- (void)start {}
- (void)stop {}
- (void *)output {return 0;}

@end

#endif
