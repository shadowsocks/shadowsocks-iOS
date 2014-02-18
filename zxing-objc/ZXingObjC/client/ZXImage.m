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

#import "ZXBitMatrix.h"
#import "ZXImage.h"

#if TARGET_OS_EMBEDDED || TARGET_IPHONE_SIMULATOR
#import <ImageIO/ImageIO.h>
#endif

@interface ZXImage ()

@property (nonatomic, assign) CGImageRef cgimage;

@end

@implementation ZXImage

- (ZXImage *)initWithCGImageRef:(CGImageRef)image {
  if (self = [super init]) {
    _cgimage = CGImageRetain(image);
  }

  return self;
}

- (ZXImage *)initWithURL:(NSURL const *)url {
  if (self = [super init]) {
    CGDataProviderRef provider = CGDataProviderCreateWithURL((__bridge CFURLRef)url);

    if (provider) {
      CGImageSourceRef source = CGImageSourceCreateWithDataProvider(provider, 0);

      if (source) {
        _cgimage = CGImageSourceCreateImageAtIndex(source, 0, 0);
        CFRelease(source);
      }

      CGDataProviderRelease(provider);
    }
  }

  return self;
}

- (size_t)width {
  return CGImageGetWidth(self.cgimage);
}

- (size_t)height {
  return CGImageGetHeight(self.cgimage);
}

- (void)dealloc {
  if (_cgimage) {
    CGImageRelease(_cgimage);
  }
}

+ (ZXImage *)imageWithMatrix:(ZXBitMatrix *)matrix {
  int width = matrix.width;
  int height = matrix.height;
  int8_t *bytes = (int8_t *)malloc(width * height * 4);
  for(int y = 0; y < height; y++) {
    for(int x = 0; x < width; x++) {
      BOOL bit = [matrix getX:x y:y];
      int8_t intensity = bit ? 0 : 255;
      for(int i = 0; i < 3; i++) {
        bytes[y * width * 4 + x * 4 + i] = intensity;
      }
      bytes[y * width * 4 + x * 4 + 3] = 255;
    }
  }

  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  CGContextRef c = CGBitmapContextCreate(bytes, width, height, 8, 4 * width, colorSpace, kCGBitmapAlphaInfoMask & kCGImageAlphaPremultipliedLast);
  CFRelease(colorSpace);
  CGImageRef image = CGBitmapContextCreateImage(c);
  CFRelease(c);
  free(bytes);

  ZXImage *zxImage = [[ZXImage alloc] initWithCGImageRef:image];

  CFRelease(image);
  return zxImage;
}

@end
