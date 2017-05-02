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
#import "ZXDataMatrixDecoder.h"
#import "ZXDataMatrixReader.h"
#import "ZXDataMatrixDetector.h"
#import "ZXDecodeHints.h"
#import "ZXDecoderResult.h"
#import "ZXDetectorResult.h"
#import "ZXErrors.h"
#import "ZXResult.h"

@interface ZXDataMatrixReader ()

@property (nonatomic, strong) ZXDataMatrixDecoder *decoder;

@end

@implementation ZXDataMatrixReader

- (id)init {
  if (self = [super init]) {
    _decoder = [[ZXDataMatrixDecoder alloc] init];
  }

  return self;
}

/**
 * Locates and decodes a Data Matrix code in an image.
 */
- (ZXResult *)decode:(ZXBinaryBitmap *)image error:(NSError **)error {
  return [self decode:image hints:nil error:error];
}

- (ZXResult *)decode:(ZXBinaryBitmap *)image hints:(ZXDecodeHints *)hints error:(NSError **)error {
  ZXDecoderResult *decoderResult;
  NSArray *points;
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
    decoderResult = [self.decoder decodeMatrix:bits error:error];
    if (!decoderResult) {
      return nil;
    }
    points = @[];
  } else {
    ZXBitMatrix *matrix = [image blackMatrixWithError:error];
    if (!matrix) {
      return nil;
    }
    ZXDataMatrixDetector *detector = [[ZXDataMatrixDetector alloc] initWithImage:matrix error:error];
    if (!detector) {
      return nil;
    }
    ZXDetectorResult *detectorResult = [detector detectWithError:error];
    if (!detectorResult) {
      return nil;
    }
    decoderResult = [self.decoder decodeMatrix:detectorResult.bits error:error];
    if (!decoderResult) {
      return nil;
    }
    points = detectorResult.points;
  }
  ZXResult *result = [ZXResult resultWithText:decoderResult.text
                                     rawBytes:decoderResult.rawBytes
                                       length:decoderResult.length
                                 resultPoints:points
                                       format:kBarcodeFormatDataMatrix];
  if (decoderResult.byteSegments != nil) {
    [result putMetadata:kResultMetadataTypeByteSegments value:decoderResult.byteSegments];
  }
  if (decoderResult.ecLevel != nil) {
    [result putMetadata:kResultMetadataTypeErrorCorrectionLevel value:decoderResult.ecLevel];
  }
  return result;
}

- (void) reset {
  // do nothing
}


/**
 * This method detects a code in a "pure" image -- that is, pure monochrome image
 * which contains only an unrotated, unskewed, image of a code, with some white border
 * around it. This is a specialized method that works exceptionally fast in this special
 * case.
 */
- (ZXBitMatrix *)extractPureBits:(ZXBitMatrix *)image {
  NSArray *leftTopBlack = image.topLeftOnBit;
  NSArray *rightBottomBlack = image.bottomRightOnBit;
  if (leftTopBlack == nil || rightBottomBlack == nil) {
    return nil;
  }

  int moduleSize = [self moduleSize:leftTopBlack image:image];
  if (moduleSize == -1) {
    return nil;
  }

  int top = [leftTopBlack[1] intValue];
  int bottom = [rightBottomBlack[1] intValue];
  int left = [leftTopBlack[0] intValue];
  int right = [rightBottomBlack[0] intValue];

  int matrixWidth = (right - left + 1) / moduleSize;
  int matrixHeight = (bottom - top + 1) / moduleSize;
  if (matrixWidth <= 0 || matrixHeight <= 0) {
    return nil;
  }

  int nudge = moduleSize >> 1;
  top += nudge;
  left += nudge;

  ZXBitMatrix *bits = [[ZXBitMatrix alloc] initWithWidth:matrixWidth height:matrixHeight];
  for (int y = 0; y < matrixHeight; y++) {
    int iOffset = top + y * moduleSize;
    for (int x = 0; x < matrixWidth; x++) {
      if ([image getX:left + x * moduleSize y:iOffset]) {
        [bits setX:x y:y];
      }
    }
  }

  return bits;
}

- (int)moduleSize:(NSArray *)leftTopBlack image:(ZXBitMatrix *)image {
  int width = image.width;
  int x = [leftTopBlack[0] intValue];
  int y = [leftTopBlack[1] intValue];
  while (x < width && [image getX:x y:y]) {
    x++;
  }
  if (x == width) {
    return -1;
  }

  int moduleSize = x - [leftTopBlack[0] intValue];
  if (moduleSize == 0) {
    return -1;
  }
  return moduleSize;
}

@end
