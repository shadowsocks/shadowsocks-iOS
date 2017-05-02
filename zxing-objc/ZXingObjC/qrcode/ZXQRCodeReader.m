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

#import "ZXBarcodeFormat.h"
#import "ZXBinaryBitmap.h"
#import "ZXBitMatrix.h"
#import "ZXDecodeHints.h"
#import "ZXDecoderResult.h"
#import "ZXDetectorResult.h"
#import "ZXErrors.h"
#import "ZXQRCodeDecoder.h"
#import "ZXQRCodeDetector.h"
#import "ZXQRCodeReader.h"
#import "ZXResult.h"

@implementation ZXQRCodeReader

- (id)init {
  if (self = [super init]) {
    _decoder = [[ZXQRCodeDecoder alloc] init];
  }

  return self;
}

/**
 * Locates and decodes a QR code in an image.
 */
- (ZXResult *)decode:(ZXBinaryBitmap *)image error:(NSError **)error {
  return [self decode:image hints:nil error:error];
}

- (ZXResult *)decode:(ZXBinaryBitmap *)image hints:(ZXDecodeHints *)hints error:(NSError **)error {
  ZXDecoderResult *decoderResult;
  NSArray *points;
  ZXBitMatrix *matrix = [image blackMatrixWithError:error];
  if (!matrix) {
    return nil;
  }
  if (hints != nil && hints.pureBarcode) {
    ZXBitMatrix *bits = [self extractPureBits:matrix];
    if (!bits) {
      if (error) *error = NotFoundErrorInstance();
      return nil;
    }
    decoderResult = [self.decoder decodeMatrix:bits hints:hints error:error];
    if (!decoderResult) {
      return nil;
    }
    points = @[];
  } else {
    ZXDetectorResult *detectorResult = [[[ZXQRCodeDetector alloc] initWithImage:matrix] detect:hints error:error];
    if (!detectorResult) {
      return nil;
    }
    decoderResult = [self.decoder decodeMatrix:[detectorResult bits] hints:hints error:error];
    if (!decoderResult) {
      return nil;
    }
    points = [detectorResult points];
  }

  ZXResult *result = [ZXResult resultWithText:decoderResult.text
                                      rawBytes:decoderResult.rawBytes
                                        length:decoderResult.length
                                  resultPoints:points
                                        format:kBarcodeFormatQRCode];
  NSMutableArray *byteSegments = decoderResult.byteSegments;
  if (byteSegments != nil) {
    [result putMetadata:kResultMetadataTypeByteSegments value:byteSegments];
  }
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
  NSArray *leftTopBlack = image.topLeftOnBit;
  NSArray *rightBottomBlack = image.bottomRightOnBit;
  if (leftTopBlack == nil || rightBottomBlack == nil) {
    return nil;
  }

  float moduleSize = [self moduleSize:leftTopBlack image:image];
  if (moduleSize == -1) {
    return nil;
  }

  int top = [leftTopBlack[1] intValue];
  int bottom = [rightBottomBlack[1] intValue];
  int left = [leftTopBlack[0] intValue];
  int right = [rightBottomBlack[0] intValue];

  // Sanity check!
  if (left >= right || top >= bottom) {
    return nil;
  }

  if (bottom - top != right - left) {
    // Special case, where bottom-right module wasn't black so we found something else in the last row
    // Assume it's a square, so use height as the width
    right = left + (bottom - top);
  }

  int matrixWidth = round((right - left + 1) / moduleSize);
  int matrixHeight = round((bottom - top + 1) / moduleSize);
  if (matrixWidth <= 0 || matrixHeight <= 0) {
    return nil;
  }
  if (matrixHeight != matrixWidth) {
    return nil;
  }

  int nudge = (int) (moduleSize / 2.0f);
  top += nudge;
  left += nudge;

  // But careful that this does not sample off the edge
  int nudgedTooFarRight = left + (int) ((matrixWidth - 1) * moduleSize) - (right - 1);
  if (nudgedTooFarRight > 0) {
    left -= nudgedTooFarRight;
  }
  int nudgedTooFarDown = top + (int) ((matrixHeight - 1) * moduleSize) - (bottom - 1);
  if (nudgedTooFarDown > 0) {
    top -= nudgedTooFarDown;
  }

  // Now just read off the bits
  ZXBitMatrix *bits = [[ZXBitMatrix alloc] initWithWidth:matrixWidth height:matrixHeight];
  for (int y = 0; y < matrixHeight; y++) {
    int iOffset = top + (int) (y * moduleSize);
    for (int x = 0; x < matrixWidth; x++) {
      if ([image getX:left + (int) (x * moduleSize) y:iOffset]) {
        [bits setX:x y:y];
      }
    }
  }
  return bits;
}

- (float)moduleSize:(NSArray *)leftTopBlack image:(ZXBitMatrix *)image {
  int height = image.height;
  int width = image.width;
  int x = [leftTopBlack[0] intValue];
  int y = [leftTopBlack[1] intValue];
  BOOL inBlack = YES;
  int transitions = 0;
  while (x < width && y < height) {
    if (inBlack != [image getX:x y:y]) {
      if (++transitions == 5) {
        break;
      }
    }
    x++;
    y++;
  }
  if (x == width || y == height) {
    return -1;
  }

  return (x - [leftTopBlack[0] intValue]) / 7.0f;
}

@end
