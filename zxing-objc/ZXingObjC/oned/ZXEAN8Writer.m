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
#import "ZXEAN8Writer.h"
#import "ZXUPCEANReader.h"

int const EAN8codeWidth = 3 + (7 * 4) + 5 + (7 * 4) + 3;

@implementation ZXEAN8Writer

- (ZXBitMatrix *)encode:(NSString *)contents format:(ZXBarcodeFormat)format width:(int)width height:(int)height hints:(ZXEncodeHints *)hints error:(NSError **)error {
  if (format != kBarcodeFormatEan8) {
    [NSException raise:NSInvalidArgumentException format:@"Can only encode EAN_8"];
  }
  return [super encode:contents format:format width:width height:height hints:hints error:error];
}

/**
 * Returns a byte array of horizontal pixels (FALSE = white, TRUE = black)
 */
- (BOOL *)encode:(NSString *)contents length:(int *)pLength {
  if ([contents length] != 8) {
    [NSException raise:NSInvalidArgumentException format:@"Requested contents should be 8 digits long, but got %d", (int)[contents length]];
  }

  if (pLength) *pLength = EAN8codeWidth;
  BOOL *result = (BOOL *)malloc(EAN8codeWidth * sizeof(BOOL));
  memset(result, 0, EAN8codeWidth * sizeof(int8_t));
  int pos = 0;

  pos += [super appendPattern:result pos:pos pattern:(int *)START_END_PATTERN patternLen:START_END_PATTERN_LEN startColor:TRUE];

  for (int i = 0; i <= 3; i++) {
    int digit = [[contents substringWithRange:NSMakeRange(i, 1)] intValue];
    pos += [super appendPattern:result pos:pos pattern:(int *)L_PATTERNS[digit] patternLen:L_PATTERNS_SUB_LEN startColor:FALSE];
  }

  pos += [super appendPattern:result pos:pos pattern:(int *)MIDDLE_PATTERN patternLen:MIDDLE_PATTERN_LEN startColor:FALSE];

  for (int i = 4; i <= 7; i++) {
    int digit = [[contents substringWithRange:NSMakeRange(i, 1)] intValue];
    pos += [super appendPattern:result pos:pos pattern:(int *)L_PATTERNS[digit] patternLen:L_PATTERNS_SUB_LEN startColor:TRUE];
  }

  [super appendPattern:result pos:pos pattern:(int *)START_END_PATTERN patternLen:START_END_PATTERN_LEN startColor:TRUE];

  return result;
}

@end
