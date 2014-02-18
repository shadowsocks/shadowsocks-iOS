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
#import "ZXBinaryBitmap.h"
#import "ZXBitArray.h"
#import "ZXBitMatrix.h"

@interface ZXBinaryBitmap ()

@property (nonatomic, strong) ZXBinarizer *binarizer;
@property (nonatomic, strong) ZXBitMatrix *matrix;

@end

@implementation ZXBinaryBitmap

- (id)initWithBinarizer:(ZXBinarizer *)binarizer {
  if (self = [super init]) {
    if (binarizer == nil) {
      [NSException raise:NSInvalidArgumentException format:@"Binarizer must be non-null."];
    }

    self.binarizer = binarizer;
  }

  return self;
}

+ (id)binaryBitmapWithBinarizer:(ZXBinarizer *)binarizer {
  return [[self alloc] initWithBinarizer:binarizer];
}

- (int)width {
  return self.binarizer.width;
}

- (int)height {
  return self.binarizer.height;
}

/**
 * Converts one row of luminance data to 1 bit data. May actually do the conversion, or return
 * cached data. Callers should assume this method is expensive and call it as seldom as possible.
 * This method is intended for decoding 1D barcodes and may choose to apply sharpening.
 */
- (ZXBitArray *)blackRow:(int)y row:(ZXBitArray *)row error:(NSError **)error {
  return [self.binarizer blackRow:y row:row error:error];
}

/**
 * Converts a 2D array of luminance data to 1 bit. As above, assume this method is expensive
 * and do not call it repeatedly. This method is intended for decoding 2D barcodes and may or
 * may not apply sharpening. Therefore, a row from this matrix may not be identical to one
 * fetched using blackRow(), so don't mix and match between them.
 */
- (ZXBitMatrix *)blackMatrixWithError:(NSError **)error {
  if (self.matrix == nil) {
    self.matrix = [self.binarizer blackMatrixWithError:error];
  }
  return self.matrix;
}

- (BOOL)cropSupported {
  return [[self.binarizer luminanceSource] cropSupported];
}

/**
 * Returns a new object with cropped image data. Implementations may keep a reference to the
 * original data rather than a copy. Only callable if isCropSupported() is true.
 */
- (ZXBinaryBitmap *)crop:(int)left top:(int)top width:(int)aWidth height:(int)aHeight {
  ZXLuminanceSource *newSource = [[self.binarizer luminanceSource] crop:left top:top width:aWidth height:aHeight];
  return [[ZXBinaryBitmap alloc] initWithBinarizer:[self.binarizer createBinarizer:newSource]];
}

- (BOOL)rotateSupported {
  return [[self.binarizer luminanceSource] rotateSupported];
}

/**
 * Returns a new object with rotated image data by 90 degrees counterclockwise.
 * Only callable if isRotateSupported() is true.
 */
- (ZXBinaryBitmap *)rotateCounterClockwise {
  ZXLuminanceSource *newSource = [[self.binarizer luminanceSource] rotateCounterClockwise];
  return [[ZXBinaryBitmap alloc] initWithBinarizer:[self.binarizer createBinarizer:newSource]];
}

- (ZXBinaryBitmap *)rotateCounterClockwise45 {
  ZXLuminanceSource *newSource = [[self.binarizer luminanceSource] rotateCounterClockwise45];
  return [[ZXBinaryBitmap alloc] initWithBinarizer:[self.binarizer createBinarizer:newSource]];
}

@end
