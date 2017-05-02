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

#import "ZXBarcodeMatrix.h"
#import "ZXBitMatrix.h"
#import "ZXEncodeHints.h"
#import "ZXPDF417.h"
#import "ZXPDF417Writer.h"

@implementation ZXPDF417Writer

- (ZXBitMatrix *)encode:(NSString *)contents format:(ZXBarcodeFormat)format width:(int)width height:(int)height
                  hints:(ZXEncodeHints *)hints error:(NSError **)error {
  if (format != kBarcodeFormatPDF417) {
    [NSException raise:NSInvalidArgumentException format:@"Can only encode PDF_417, but got %d", format];
  }

  ZXPDF417 *encoder = [[ZXPDF417 alloc] init];

  if (hints != nil) {
    encoder.compact = hints.pdf417Compact;
    encoder.compaction = hints.pdf417Compaction;
    if (hints.pdf417Dimensions != nil) {
      ZXDimensions *dimensions = hints.pdf417Dimensions;
      [encoder setDimensionsWithMaxCols:dimensions.maxCols
                                minCols:dimensions.minCols
                                maxRows:dimensions.maxRows
                                minRows:dimensions.minRows];
    }
  }

  return [self bitMatrixFromEncoder:encoder contents:contents width:width height:height error:error];
}

- (ZXBitMatrix *)encode:(NSString *)contents format:(ZXBarcodeFormat)format width:(int)width height:(int)height error:(NSError **)error {
  return [self encode:contents format:format width:width height:height hints:nil error:error];
}

/**
 * Takes encoder, accounts for width/height, and retrieves bit matrix
 */
- (ZXBitMatrix *)bitMatrixFromEncoder:(ZXPDF417 *)encoder contents:(NSString *)contents width:(int)width height:(int)height error:(NSError **)error {
  int errorCorrectionLevel = 2;
  if (![encoder generateBarcodeLogic:contents errorCorrectionLevel:errorCorrectionLevel error:error]) {
    return nil;
  }

  int lineThickness = 2;
  int aspectRatio = 4;

  int scaleHeight;
  int scaleWidth;
  int8_t **originalScale = [[encoder barcodeMatrix] scaledMatrixWithHeight:&scaleHeight width:&scaleWidth xScale:lineThickness yScale:aspectRatio * lineThickness];
  BOOL rotated = NO;
  if ((height > width) ^ (scaleWidth < scaleHeight)) {
    int8_t **oldOriginalScale = originalScale;
    originalScale = [self rotateArray:oldOriginalScale height:scaleHeight width:scaleWidth];
    free(oldOriginalScale);
    rotated = YES;
  }

  int scaleX = width / scaleWidth;
  int scaleY = height / scaleHeight;

  int scale;
  if (scaleX < scaleY) {
    scale = scaleX;
  } else {
    scale = scaleY;
  }

  ZXBitMatrix *result = nil;
  if (scale > 1) {
    int8_t **scaledMatrix =
      [[encoder barcodeMatrix] scaledMatrixWithHeight:&scaleHeight width:&scaleWidth xScale:scale * lineThickness yScale:scale * aspectRatio * lineThickness];
    if (rotated) {
      int8_t **oldScaledMatrix = scaledMatrix;
      scaledMatrix = [self rotateArray:scaledMatrix height:scaleHeight width:scaleWidth];
      free(oldScaledMatrix);
    }
    result = [self bitMatrixFrombitArray:scaledMatrix height:scaleHeight width:scaleWidth];
    free(scaledMatrix);
  } else {
    result = [self bitMatrixFrombitArray:originalScale height:scaleHeight width:scaleWidth];
  }
  free(originalScale);
  return result;
}

/**
 * This takes an array holding the values of the PDF 417
 */
- (ZXBitMatrix *)bitMatrixFrombitArray:(int8_t **)input height:(int)height width:(int)width {
  // Creates a small whitespace boarder around the barcode
  int whiteSpace = 30;

  // Creates the bitmatrix with extra space for whtespace
  ZXBitMatrix *output = [[ZXBitMatrix alloc] initWithWidth:width + 2 * whiteSpace height:height + 2 * whiteSpace];
  [output clear];
  for (int y = 0, yOutput = output.height - whiteSpace; y < height; y++, yOutput--) {
    for (int x = 0; x < width; x++) {
      // Zero is white in the bytematrix
      if (input[y][x] == 1) {
        [output setX:x + whiteSpace y:yOutput];
      }
    }
  }
  return output;
}

/**
 * Takes and rotates the it 90 degrees
 */
- (int8_t **)rotateArray:(int8_t **)bitarray height:(int)height width:(int)width {
  int8_t **temp = (int8_t **)malloc(width * sizeof(int8_t *));
  for (int i = 0; i < width; i++) {
    temp[i] = (int8_t *)malloc(height * sizeof(int8_t));
  }

  for (int ii = 0; ii < height; ii++) {
    // This makes the direction consistent on screen when rotating the
    // screen;
    int inverseii = height - ii - 1;
    for (int jj = 0; jj < width; jj++) {
      temp[jj][inverseii] = bitarray[ii][jj];
    }
  }
  return temp;
}

@end
