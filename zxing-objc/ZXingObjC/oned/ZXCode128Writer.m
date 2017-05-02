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

#import "ZXCode128Reader.h"
#import "ZXCode128Writer.h"

// Dummy characters used to specify control characters in input
const unichar ESCAPE_FNC_1 = L'\u00f1';
const unichar ESCAPE_FNC_2 = L'\u00f2';
const unichar ESCAPE_FNC_3 = L'\u00f3';
const unichar ESCAPE_FNC_4 = L'\u00f4';

@implementation ZXCode128Writer

- (ZXBitMatrix *)encode:(NSString *)contents format:(ZXBarcodeFormat)format width:(int)width height:(int)height hints:(ZXEncodeHints *)hints error:(NSError **)error {
  if (format != kBarcodeFormatCode128) {
    [NSException raise:NSInvalidArgumentException format:@"Can only encode CODE_128"];
  }
  return [super encode:contents format:format width:width height:height hints:hints error:error];
}

- (BOOL *)encode:(NSString *)contents length:(int *)pLength {
  int length = (int)[contents length];
  // Check length
  if (length < 1 || length > 80) {
    [NSException raise:NSInvalidArgumentException format:@"Contents length should be between 1 and 80 characters, but got %d", length];
  }
  // Check content
  for (int i = 0; i < length; i++) {
    unichar c = [contents characterAtIndex:i];
    if (c < ' ' || c > '~') {
      switch (c) {
        case ESCAPE_FNC_1:
        case ESCAPE_FNC_2:
        case ESCAPE_FNC_3:
        case ESCAPE_FNC_4:
          break;
        default:
          [NSException raise:NSInvalidArgumentException format:@"Bad character in input: %C", c];
      }
    }
  }

  NSMutableArray *patterns = [NSMutableArray array]; // temporary storage for patterns
  int checkSum = 0;
  int checkWeight = 1;
  int codeSet = 0; // selected code (CODE_CODE_B or CODE_CODE_C)
  int position = 0; // position in contents

  while (position < length) {
    //Select code to use
    int requiredDigitCount = codeSet == CODE_CODE_C ? 2 : 4;
    int newCodeSet;
    if ([self isDigits:contents start:position length:requiredDigitCount]) {
      newCodeSet = CODE_CODE_C;
    } else {
      newCodeSet = CODE_CODE_B;
    }

    //Get the pattern index
    int patternIndex;
    if (newCodeSet == codeSet) {
      // Encode the current character
      if (codeSet == CODE_CODE_B) {
        patternIndex = [contents characterAtIndex:position] - ' ';
        position += 1;
      } else { // CODE_CODE_C
        switch ([contents characterAtIndex:position]) {
          case ESCAPE_FNC_1:
            patternIndex = CODE_FNC_1;
            position++;
            break;
          case ESCAPE_FNC_2:
            patternIndex = CODE_FNC_2;
            position++;
            break;
          case ESCAPE_FNC_3:
            patternIndex = CODE_FNC_3;
            position++;
            break;
          case ESCAPE_FNC_4:
            patternIndex = CODE_FNC_4_B; // FIXME if this ever outputs Code A
            position++;
            break;
          default:
            patternIndex = [[contents substringWithRange:NSMakeRange(position, 2)] intValue];
            position += 2;
            break;
        }
      }
    } else {
      // Should we change the current code?
      // Do we have a code set?
      if (codeSet == 0) {
        // No, we don't have a code set
        if (newCodeSet == CODE_CODE_B) {
          patternIndex = CODE_START_B;
        } else {
          // CODE_CODE_C
          patternIndex = CODE_START_C;
        }
      } else {
        // Yes, we have a code set
        patternIndex = newCodeSet;
      }
      codeSet = newCodeSet;
    }

    // Get the pattern
    NSMutableArray *pattern = [NSMutableArray array];
    for (int i = 0; i < sizeof(CODE_PATTERNS[patternIndex]) / sizeof(int); i++) {
      [pattern addObject:@(CODE_PATTERNS[patternIndex][i])];
    }
    [patterns addObject:pattern];

    // Compute checksum
    checkSum += patternIndex * checkWeight;
    if (position != 0) {
      checkWeight++;
    }
  }

  // Compute and append checksum
  checkSum %= 103;
  NSMutableArray *pattern = [NSMutableArray array];
  for (int i = 0; i < sizeof(CODE_PATTERNS[checkSum]) / sizeof(int); i++) {
    [pattern addObject:@(CODE_PATTERNS[checkSum][i])];
  }
  [patterns addObject:pattern];

  // Append stop code
  pattern = [NSMutableArray array];
  for (int i = 0; i < sizeof(CODE_PATTERNS[CODE_STOP]) / sizeof(int); i++) {
    [pattern addObject:@(CODE_PATTERNS[CODE_STOP][i])];
  }
  [patterns addObject:pattern];

  // Compute code width
  int codeWidth = 0;
  for (pattern in patterns) {
    for (int i = 0; i < pattern.count; i++) {
      codeWidth += [pattern[i] intValue];
    }
  }

  // Compute result
  if (pLength) *pLength = codeWidth;
  BOOL *result = (BOOL *)malloc(codeWidth * sizeof(BOOL));
  int pos = 0;
  for (NSArray *patternArray in patterns) {
    int patternLen = (int)[patternArray count];
    int pattern[patternLen];
    for(int i = 0; i < patternLen; i++) {
      pattern[i] = [patternArray[i] intValue];
    }

    pos += [super appendPattern:result pos:pos pattern:pattern patternLen:patternLen startColor:TRUE];
  }

  return result;
}

- (BOOL)isDigits:(NSString *)value start:(int)start length:(unsigned int)length {
  int end = start + length;
  int last = (int)[value length];
  for (int i = start; i < end && i < last; i++) {
    unichar c = [value characterAtIndex:i];
    if (c < '0' || c > '9') {
      if (c != ESCAPE_FNC_1) {
        return NO;
      }
      end++; // ignore FNC_1
    }
  }
  return end <= last; // end > last if we've run out of string
}

@end
