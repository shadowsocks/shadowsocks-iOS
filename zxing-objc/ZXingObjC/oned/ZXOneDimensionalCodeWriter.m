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
#import "ZXEncodeHints.h"
#import "ZXOneDimensionalCodeWriter.h"

@implementation ZXOneDimensionalCodeWriter

- (ZXBitMatrix *)encode:(NSString *)contents format:(ZXBarcodeFormat)format width:(int)width height:(int)height error:(NSError **)error {
  return [self encode:contents format:format width:width height:height hints:nil error:error];
}

- (ZXBitMatrix *)encode:(NSString *)contents format:(ZXBarcodeFormat)format width:(int)width height:(int)height
                 hints:(ZXEncodeHints *)hints error:(NSError **)error {
  if (contents.length == 0) {
    @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Found empty contents" userInfo:nil];
  }

  if (width < 0 || height < 0) {
    @throw [NSException exceptionWithName:NSInvalidArgumentException
                                   reason:[NSString stringWithFormat:@"Negative size is not allowed. Input: %dx%d", width, height]
                                 userInfo:nil];
  }

  int sidesMargin = [self defaultMargin];
  if (hints && hints.margin) {
    sidesMargin = hints.margin.intValue;
  }

  int length;
  BOOL *code = [self encode:contents length:&length];
  ZXBitMatrix *result = [self renderResult:code length:length width:width height:height sidesMargin:sidesMargin];
  free(code);
  return result;
}

- (ZXBitMatrix *)renderResult:(BOOL *)code length:(int)length width:(int)width height:(int)height sidesMargin:(int)sidesMargin {
  int inputWidth = length;
  // Add quiet zone on both sides.
  int fullWidth = inputWidth + sidesMargin;
  int outputWidth = MAX(width, fullWidth);
  int outputHeight = MAX(1, height);

  int multiple = outputWidth / fullWidth;
  int leftPadding = (outputWidth - (inputWidth * multiple)) / 2;

  ZXBitMatrix *output = [ZXBitMatrix bitMatrixWithWidth:outputWidth height:outputHeight];
  for (int inputX = 0, outputX = leftPadding; inputX < inputWidth; inputX++, outputX += multiple) {
    if (code[inputX]) {
      [output setRegionAtLeft:outputX top:0 width:multiple height:outputHeight];
    }
  }
  return output;
}

/**
 * Appends the given pattern to the target array starting at pos.
 */
- (int)appendPattern:(BOOL *)target pos:(int)pos pattern:(int *)pattern patternLen:(int)patternLen startColor:(BOOL)startColor {
  BOOL color = startColor;
  int numAdded = 0;
  for (int i = 0; i < patternLen; i++) {
    for (int j = 0; j < pattern[i]; j++) {
      target[pos++] = color;
    }
    numAdded += pattern[i];
    color = !color; // flip color after each segment
  }
  return numAdded;
}

- (int)defaultMargin {
  // CodaBar spec requires a side margin to be more than ten times wider than narrow space.
  // This seems like a decent idea for a default for all formats.
  return 10;
}

/**
 * Encode the contents to boolean array expression of one-dimensional barcode.
 * Start code and end code should be included in result, and side margins should not be included.
 */
- (BOOL *)encode:(NSString *)contents length:(int *)pLength {
  @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                 reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                               userInfo:nil];
}

@end
