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

#import "ZXBinarizer.h"

#if TARGET_OS_EMBEDDED || TARGET_IPHONE_SIMULATOR
#import <UIKit/UIKit.h>
#define ZXBlack [[UIColor blackColor] CGColor]
#define ZXWhite [[UIColor whiteColor] CGColor]
#else
#define ZXBlack CGColorGetConstantColor(kCGColorBlack)
#define ZXWhite CGColorGetConstantColor(kCGColorWhite)
#endif

@implementation ZXBinarizer

- (id)initWithSource:(ZXLuminanceSource *)source {
  if (self = [super init]) {
    _luminanceSource = source;
  }

  return self;
}

- (id)initWithLuminanceSource:(ZXLuminanceSource *)source {
  return [self initWithSource:source];
}

+ (id)binarizerWithSource:(ZXLuminanceSource *)source {
  return [[self alloc] initWithLuminanceSource:source];
}

/**
 * Converts one row of luminance data to 1 bit data. May actually do the conversion, or return
 * cached data. Callers should assume this method is expensive and call it as seldom as possible.
 * This method is intended for decoding 1D barcodes and may choose to apply sharpening.
 * For callers which only examine one row of pixels at a time, the same BitArray should be reused
 * and passed in with each call for performance. However it is legal to keep more than one row
 * at a time if needed.
 */
- (ZXBitArray *)blackRow:(int)y row:(ZXBitArray *)row error:(NSError **)error {
  @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                 reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                               userInfo:nil];
}


/**
 * Converts a 2D array of luminance data to 1 bit data. As above, assume this method is expensive
 * and do not call it repeatedly. This method is intended for decoding 2D barcodes and may or
 * may not apply sharpening. Therefore, a row from this matrix may not be identical to one
 * fetched using blackRow(), so don't mix and match between them.
 */
- (ZXBitMatrix *)blackMatrixWithError:(NSError **)error {
  @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                 reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                               userInfo:nil];
}


/**
 * Creates a new object with the same type as this Binarizer implementation, but with pristine
 * state. This is needed because Binarizer implementations may be stateful, e.g. keeping a cache
 * of 1 bit data. See Effective Java for why we can't use Java's clone() method.
 */
- (ZXBinarizer *)createBinarizer:(ZXLuminanceSource *)source {
  @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                 reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                               userInfo:nil];
}

- (CGImageRef)createImage CF_RETURNS_RETAINED {
  ZXBitMatrix *matrix = [self blackMatrixWithError:nil];
  if (!matrix) {
    return nil;
  }
  ZXLuminanceSource *source = [self luminanceSource];

  int width = source.width;
  int height = source.height;

  int bytesPerRow = ((width&0xf)>>4)<<4;

  CGColorSpaceRef gray = CGColorSpaceCreateDeviceGray();
  CGContextRef context = CGBitmapContextCreate (
                                                0,
                                                width,
                                                height,
                                                8,      // bits per component
                                                bytesPerRow,
                                                gray,
                                                kCGBitmapAlphaInfoMask & kCGImageAlphaNone);
  CGColorSpaceRelease(gray);

  CGRect r = CGRectZero;
  r.size.width = width;
  r.size.height = height;
  CGContextSetFillColorWithColor(context, ZXBlack);
  CGContextFillRect(context, r);

  r.size.width = 1;
  r.size.height = 1;

  CGContextSetFillColorWithColor(context, ZXWhite);
  for(int y=0; y<height; y++) {
    r.origin.y = height-1-y;
    for(int x=0; x<width; x++) {
      if (![matrix getX:x y:y]) {
        r.origin.x = x;
        CGContextFillRect(context, r);
      }
    }
  }

  CGImageRef binary = CGBitmapContextCreateImage(context);

  CGContextRelease(context);

  return binary;
}

- (int)width {
  return self.luminanceSource.width;
}

- (int)height {
  return self.luminanceSource.height;
}

@end
