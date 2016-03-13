/*
 * Copyright 2013 ZXing authors
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
#import "ZXByteMatrix.h"
#import "ZXDataMatrixErrorCorrection.h"
#import "ZXDataMatrixWriter.h"
#import "ZXDefaultPlacement.h"
#import "ZXDimension.h"
#import "ZXEncodeHints.h"
#import "ZXHighLevelEncoder.h"
#import "ZXSymbolInfo.h"
#import "ZXSymbolShapeHint.h"

@implementation ZXDataMatrixWriter

- (ZXBitMatrix *)encode:(NSString *)contents format:(ZXBarcodeFormat)format width:(int)width height:(int)height error:(NSError **)error {
  return [self encode:contents format:format width:width height:height hints:nil error:error];
}

- (ZXBitMatrix *)encode:(NSString *)contents format:(ZXBarcodeFormat)format width:(int)width height:(int)height hints:(ZXEncodeHints *)hints error:(NSError **)error {
  if (contents.length == 0) {
    [NSException raise:NSInvalidArgumentException format:@"Found empty contents"];
  }

  if (format != kBarcodeFormatDataMatrix) {
    [NSException raise:NSInvalidArgumentException format:@"Can only encode kBarcodeFormatDataMatrix"];
  }

  if (width < 0 || height < 0) {
    [NSException raise:NSInvalidArgumentException
                format:@"Requested dimensions are too small: %dx%d", width, height];
  }

  // Try to get force shape & min / max size
  ZXSymbolShapeHint *shape = [ZXSymbolShapeHint forceNone];
  ZXDimension *minSize = nil;
  ZXDimension *maxSize = nil;
  if (hints != nil) {
    ZXSymbolShapeHint *requestedShape = hints.dataMatrixShape;
    if (requestedShape != nil) {
      shape = requestedShape;
    }
    ZXDimension *requestedMinSize = hints.minSize;
    if (requestedMinSize != nil) {
      minSize = requestedMinSize;
    }
    ZXDimension *requestedMaxSize = hints.maxSize;
    if (requestedMaxSize != nil) {
      maxSize = requestedMaxSize;
    }
  }

  //1. step: Data encodation
  NSString *encoded = [ZXHighLevelEncoder encodeHighLevel:contents shape:shape minSize:minSize maxSize:maxSize];

  ZXSymbolInfo *symbolInfo = [ZXSymbolInfo lookup:(int)encoded.length shape:shape minSize:minSize maxSize:maxSize fail:YES];

  //2. step: ECC generation
  NSString *codewords = [ZXDataMatrixErrorCorrection encodeECC200:encoded symbolInfo:symbolInfo];

  //3. step: Module placement in Matrix
  ZXDefaultPlacement *placement = [[ZXDefaultPlacement alloc] initWithCodewords:codewords numcols:symbolInfo.symbolDataWidth numrows:symbolInfo.symbolDataHeight];
  [placement place];

  //4. step: low-level encoding
  return [self encodeLowLevel:placement symbolInfo:symbolInfo];
}

/**
 * Encode the given symbol info to a bit matrix.
 */
- (ZXBitMatrix *)encodeLowLevel:(ZXDefaultPlacement *)placement symbolInfo:(ZXSymbolInfo *)symbolInfo {
  int symbolWidth = symbolInfo.symbolDataWidth;
  int symbolHeight = symbolInfo.symbolDataHeight;

  ZXByteMatrix *matrix = [[ZXByteMatrix alloc] initWithWidth:symbolInfo.symbolWidth height:symbolInfo.symbolHeight];

  int matrixY = 0;

  for (int y = 0; y < symbolHeight; y++) {
    // Fill the top edge with alternate 0 / 1
    int matrixX;
    if ((y % symbolInfo.matrixHeight) == 0) {
      matrixX = 0;
      for (int x = 0; x < symbolInfo.symbolWidth; x++) {
        [matrix setX:matrixX y:matrixY boolValue:(x % 2) == 0];
        matrixX++;
      }
      matrixY++;
    }
    matrixX = 0;
    for (int x = 0; x < symbolWidth; x++) {
      // Fill the right edge with full 1
      if ((x % symbolInfo.matrixWidth) == 0) {
        [matrix setX:matrixX y:matrixY boolValue:YES];
        matrixX++;
      }
      [matrix setX:matrixX y:matrixY boolValue:[placement bitAtCol:x row:y]];
      matrixX++;
      // Fill the right edge with alternate 0 / 1
      if ((x % symbolInfo.matrixWidth) == symbolInfo.matrixWidth - 1) {
        [matrix setX:matrixX y:matrixY boolValue:(y % 2) == 0];
        matrixX++;
      }
    }
    matrixY++;
    // Fill the bottom edge with full 1
    if ((y % symbolInfo.matrixHeight) == symbolInfo.matrixHeight - 1) {
      matrixX = 0;
      for (int x = 0; x < symbolInfo.symbolWidth; x++) {
        [matrix setX:matrixX y:matrixY boolValue:YES];
        matrixX++;
      }
      matrixY++;
    }
  }

  return [self convertByteMatrixToBitMatrix:matrix];
}

/**
 * Convert the ByteMatrix to BitMatrix.
 */
- (ZXBitMatrix *)convertByteMatrixToBitMatrix:(ZXByteMatrix *)matrix {
  int matrixWidgth = matrix.width;
  int matrixHeight = matrix.height;

  ZXBitMatrix *output = [[ZXBitMatrix alloc] initWithWidth:matrixWidgth height:matrixHeight];
  [output clear];
  for (int i = 0; i < matrixWidgth; i++) {
    for (int j = 0; j < matrixHeight; j++) {
      // Zero is white in the bytematrix
      if ([matrix getX:i y:j] == 1) {
        [output setX:i y:j];
      }
    }
  }

  return output;
}

@end
