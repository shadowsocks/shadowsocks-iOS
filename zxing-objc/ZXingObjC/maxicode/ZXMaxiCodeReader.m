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

#import "ZXBinaryBitmap.h"
#import "ZXBitMatrix.h"
#import "ZXDecodeHints.h"
#import "ZXDecoderResult.h"
#import "ZXErrors.h"
#import "ZXMaxiCodeDecoder.h"
#import "ZXMaxiCodeReader.h"
#import "ZXResult.h"

const int MATRIX_WIDTH = 30;
const int MATRIX_HEIGHT = 33;

@interface ZXMaxiCodeReader ()

@property (nonatomic, strong) ZXMaxiCodeDecoder *decoder;

@end

@implementation ZXMaxiCodeReader

- (id)init {
  if (self = [super init]) {
    _decoder = [[ZXMaxiCodeDecoder alloc] init];
  }

  return self;
}

/**
 * Locates and decodes a MaxiCode code in an image.
 */
- (ZXResult *)decode:(ZXBinaryBitmap *)image error:(NSError **)error {
  return [self decode:image hints:nil error:error];
}

- (ZXResult *)decode:(ZXBinaryBitmap *)image hints:(ZXDecodeHints *)hints error:(NSError **)error {
  ZXDecoderResult *decoderResult;
  if (hints != nil && hints.pureBarcode) {
    ZXBitMatrix *matrix = [image blackMatrixWithError:error];
    if (!matrix) {
      return nil;
    }
    ZXBitMatrix *bits = [self extractPureBits:matrix];
    if (!bits) {
      if (error) *error = NotFoundErrorInstance();
      return nil;
    }
    decoderResult = [self.decoder decode:bits hints:hints error:error];
    if (!decoderResult) {
      return nil;
    }
  } else {
    if (error) *error = NotFoundErrorInstance();
    return nil;
  }

  NSArray *points = @[];
  ZXResult *result = [ZXResult resultWithText:decoderResult.text
                                      rawBytes:decoderResult.rawBytes
                                        length:decoderResult.length
                                  resultPoints:points
                                        format:kBarcodeFormatMaxiCode];

  NSString *ecLevel = decoderResult.ecLevel;
  if (ecLevel != nil) {
    [result putMetadata:kResultMetadataTypeErrorCorrectionLevel value:ecLevel];
  }
  return result;
}

- (void)reset {
  // do nothing
}

/**
 * This method detects a code in a "pure" image -- that is, pure monochrome image
 * which contains only an unrotated, unskewed, image of a code, with some white border
 * around it. This is a specialized method that works exceptionally fast in this special
 * case.
 */
- (ZXBitMatrix *)extractPureBits:(ZXBitMatrix *)image {
  NSArray *enclosingRectangle = image.enclosingRectangle;
  if (enclosingRectangle == nil) {
    return nil;
  }

  int left = [enclosingRectangle[0] intValue];
  int top = [enclosingRectangle[1] intValue];
  int width = [enclosingRectangle[2] intValue];
  int height = [enclosingRectangle[3] intValue];

  // Now just read off the bits
  ZXBitMatrix *bits = [[ZXBitMatrix alloc] initWithWidth:MATRIX_WIDTH height:MATRIX_HEIGHT];
  for (int y = 0; y < MATRIX_HEIGHT; y++) {
    int iy = top + (y * height + height / 2) / MATRIX_HEIGHT;
    for (int x = 0; x < MATRIX_WIDTH; x++) {
      int ix = left + (x * width + width / 2 + (y & 0x01) *  width / 2) / MATRIX_WIDTH;
      if ([image getX:ix y:iy]) {
        [bits setX:x y:y];
      }
    }
  }

  return bits;
}

@end
