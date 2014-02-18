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

#import "ZXBitArray.h"
#import "ZXCode128Reader.h"
#import "ZXDecodeHints.h"
#import "ZXErrors.h"
#import "ZXOneDReader.h"
#import "ZXResult.h"
#import "ZXResultPoint.h"

#define CODE_PATTERNS_LENGTH 107
#define countersLength 7

const int CODE_PATTERNS[CODE_PATTERNS_LENGTH][countersLength] = {
  {2, 1, 2, 2, 2, 2}, // 0
  {2, 2, 2, 1, 2, 2},
  {2, 2, 2, 2, 2, 1},
  {1, 2, 1, 2, 2, 3},
  {1, 2, 1, 3, 2, 2},
  {1, 3, 1, 2, 2, 2}, // 5
  {1, 2, 2, 2, 1, 3},
  {1, 2, 2, 3, 1, 2},
  {1, 3, 2, 2, 1, 2},
  {2, 2, 1, 2, 1, 3},
  {2, 2, 1, 3, 1, 2}, // 10
  {2, 3, 1, 2, 1, 2},
  {1, 1, 2, 2, 3, 2},
  {1, 2, 2, 1, 3, 2},
  {1, 2, 2, 2, 3, 1},
  {1, 1, 3, 2, 2, 2}, // 15
  {1, 2, 3, 1, 2, 2},
  {1, 2, 3, 2, 2, 1},
  {2, 2, 3, 2, 1, 1},
  {2, 2, 1, 1, 3, 2},
  {2, 2, 1, 2, 3, 1}, // 20
  {2, 1, 3, 2, 1, 2},
  {2, 2, 3, 1, 1, 2},
  {3, 1, 2, 1, 3, 1},
  {3, 1, 1, 2, 2, 2},
  {3, 2, 1, 1, 2, 2}, // 25
  {3, 2, 1, 2, 2, 1},
  {3, 1, 2, 2, 1, 2},
  {3, 2, 2, 1, 1, 2},
  {3, 2, 2, 2, 1, 1},
  {2, 1, 2, 1, 2, 3}, // 30
  {2, 1, 2, 3, 2, 1},
  {2, 3, 2, 1, 2, 1},
  {1, 1, 1, 3, 2, 3},
  {1, 3, 1, 1, 2, 3},
  {1, 3, 1, 3, 2, 1}, // 35
  {1, 1, 2, 3, 1, 3},
  {1, 3, 2, 1, 1, 3},
  {1, 3, 2, 3, 1, 1},
  {2, 1, 1, 3, 1, 3},
  {2, 3, 1, 1, 1, 3}, // 40
  {2, 3, 1, 3, 1, 1},
  {1, 1, 2, 1, 3, 3},
  {1, 1, 2, 3, 3, 1},
  {1, 3, 2, 1, 3, 1},
  {1, 1, 3, 1, 2, 3}, // 45
  {1, 1, 3, 3, 2, 1},
  {1, 3, 3, 1, 2, 1},
  {3, 1, 3, 1, 2, 1},
  {2, 1, 1, 3, 3, 1},
  {2, 3, 1, 1, 3, 1}, // 50
  {2, 1, 3, 1, 1, 3},
  {2, 1, 3, 3, 1, 1},
  {2, 1, 3, 1, 3, 1},
  {3, 1, 1, 1, 2, 3},
  {3, 1, 1, 3, 2, 1}, // 55
  {3, 3, 1, 1, 2, 1},
  {3, 1, 2, 1, 1, 3},
  {3, 1, 2, 3, 1, 1},
  {3, 3, 2, 1, 1, 1},
  {3, 1, 4, 1, 1, 1}, // 60
  {2, 2, 1, 4, 1, 1},
  {4, 3, 1, 1, 1, 1},
  {1, 1, 1, 2, 2, 4},
  {1, 1, 1, 4, 2, 2},
  {1, 2, 1, 1, 2, 4}, // 65
  {1, 2, 1, 4, 2, 1},
  {1, 4, 1, 1, 2, 2},
  {1, 4, 1, 2, 2, 1},
  {1, 1, 2, 2, 1, 4},
  {1, 1, 2, 4, 1, 2}, // 70
  {1, 2, 2, 1, 1, 4},
  {1, 2, 2, 4, 1, 1},
  {1, 4, 2, 1, 1, 2},
  {1, 4, 2, 2, 1, 1},
  {2, 4, 1, 2, 1, 1}, // 75
  {2, 2, 1, 1, 1, 4},
  {4, 1, 3, 1, 1, 1},
  {2, 4, 1, 1, 1, 2},
  {1, 3, 4, 1, 1, 1},
  {1, 1, 1, 2, 4, 2}, // 80
  {1, 2, 1, 1, 4, 2},
  {1, 2, 1, 2, 4, 1},
  {1, 1, 4, 2, 1, 2},
  {1, 2, 4, 1, 1, 2},
  {1, 2, 4, 2, 1, 1}, // 85
  {4, 1, 1, 2, 1, 2},
  {4, 2, 1, 1, 1, 2},
  {4, 2, 1, 2, 1, 1},
  {2, 1, 2, 1, 4, 1},
  {2, 1, 4, 1, 2, 1}, // 90
  {4, 1, 2, 1, 2, 1},
  {1, 1, 1, 1, 4, 3},
  {1, 1, 1, 3, 4, 1},
  {1, 3, 1, 1, 4, 1},
  {1, 1, 4, 1, 1, 3}, // 95
  {1, 1, 4, 3, 1, 1},
  {4, 1, 1, 1, 1, 3},
  {4, 1, 1, 3, 1, 1},
  {1, 1, 3, 1, 4, 1},
  {1, 1, 4, 1, 3, 1}, // 100
  {3, 1, 1, 1, 4, 1},
  {4, 1, 1, 1, 3, 1},
  {2, 1, 1, 4, 1, 2},
  {2, 1, 1, 2, 1, 4},
  {2, 1, 1, 2, 3, 2}, // 105
  {2, 3, 3, 1, 1, 1, 2}
};

static int MAX_AVG_VARIANCE = -1;
static int MAX_INDIVIDUAL_VARIANCE = -1;

int const CODE_SHIFT = 98;
int const CODE_CODE_C = 99;
int const CODE_CODE_B = 100;
int const CODE_CODE_A = 101;
int const CODE_FNC_1 = 102;
int const CODE_FNC_2 = 97;
int const CODE_FNC_3 = 96;
int const CODE_FNC_4_A = 101;
int const CODE_FNC_4_B = 100;
int const CODE_START_A = 103;
int const CODE_START_B = 104;
int const CODE_START_C = 105;
int const CODE_STOP = 106;

@implementation ZXCode128Reader

+ (void)initialize {
  if (MAX_AVG_VARIANCE == -1) {
    MAX_AVG_VARIANCE = (int)(PATTERN_MATCH_RESULT_SCALE_FACTOR * 0.25f);
  }

  if (MAX_INDIVIDUAL_VARIANCE == -1) {
    MAX_INDIVIDUAL_VARIANCE = (int)(PATTERN_MATCH_RESULT_SCALE_FACTOR * 0.7f);
  }
}

- (NSArray *)findStartPattern:(ZXBitArray *)row {
  int width = row.size;
  int rowOffset = [row nextSet:0];

  int counterPosition = 0;

  const int patternLength = 6;
  int counters[patternLength];
  memset(counters, 0, patternLength * sizeof(int));

  int patternStart = rowOffset;
  BOOL isWhite = NO;

  for (int i = rowOffset; i < width; i++) {
    if ([row get:i] ^ isWhite) {
      counters[counterPosition]++;
    } else {
      if (counterPosition == patternLength - 1) {
        int bestVariance = MAX_AVG_VARIANCE;
        int bestMatch = -1;
        for (int startCode = CODE_START_A; startCode <= CODE_START_C; startCode++) {
          int variance = [ZXOneDReader patternMatchVariance:counters countersSize:patternLength pattern:(int *)CODE_PATTERNS[startCode] maxIndividualVariance:MAX_INDIVIDUAL_VARIANCE];
          if (variance < bestVariance) {
            bestVariance = variance;
            bestMatch = startCode;
          }
        }
        // Look for whitespace before start pattern, >= 50% of width of start pattern
        if (bestMatch >= 0 &&
            [row isRange:MAX(0, patternStart - (i - patternStart) / 2) end:patternStart value:NO]) {
          return @[@(patternStart), @(i), @(bestMatch)];
        }
        patternStart += counters[0] + counters[1];
        for (int y = 2; y < patternLength; y++) {
          counters[y - 2] = counters[y];
        }
        counters[patternLength - 2] = 0;
        counters[patternLength - 1] = 0;
        counterPosition--;
      } else {
        counterPosition++;
      }
      counters[counterPosition] = 1;
      isWhite = !isWhite;
    }
  }

  return nil;
}

- (int)decodeCode:(ZXBitArray *)row counters:(int[])counters countersCount:(int)countersCount rowOffset:(int)rowOffset {
  if (![ZXOneDReader recordPattern:row start:rowOffset counters:counters countersSize:countersCount]) {
    return -1;
  }
  int bestVariance = MAX_AVG_VARIANCE;
  int bestMatch = -1;

  for (int d = 0; d < CODE_PATTERNS_LENGTH; d++) {
    int *pattern = (int *)CODE_PATTERNS[d];
    int variance = [ZXOneDReader patternMatchVariance:counters countersSize:countersCount pattern:pattern maxIndividualVariance:MAX_INDIVIDUAL_VARIANCE];
    if (variance < bestVariance) {
      bestVariance = variance;
      bestMatch = d;
    }
  }

  if (bestMatch >= 0) {
    return bestMatch;
  } else {
    return -1;
  }
}

- (ZXResult *)decodeRow:(int)rowNumber row:(ZXBitArray *)row hints:(ZXDecodeHints *)hints error:(NSError **)error {
  BOOL convertFNC1 = hints && hints.assumeGS1;

  NSArray *startPatternInfo = [self findStartPattern:row];
  if (!startPatternInfo) {
    if (error) *error = NotFoundErrorInstance();
    return nil;
  }

  int startCode = [startPatternInfo[2] intValue];
  int codeSet;

  switch (startCode) {
  case CODE_START_A:
    codeSet = CODE_CODE_A;
    break;
  case CODE_START_B:
    codeSet = CODE_CODE_B;
    break;
  case CODE_START_C:
    codeSet = CODE_CODE_C;
    break;
  default:
    if (error) *error = FormatErrorInstance();
    return nil;
  }

  BOOL done = NO;
  BOOL isNextShifted = NO;

  NSMutableString *result = [NSMutableString stringWithCapacity:20];
  NSMutableArray *rawCodes = [NSMutableArray arrayWithCapacity:20];

  int lastStart = [startPatternInfo[0] intValue];
  int nextStart = [startPatternInfo[1] intValue];

  const int countersLen = 6;
  int counters[countersLen];
  memset(counters, 0, countersLen * sizeof(int));

  int lastCode = 0;
  int code = 0;
  int checksumTotal = startCode;
  int multiplier = 0;
  BOOL lastCharacterWasPrintable = YES;

  while (!done) {
    BOOL unshift = isNextShifted;
    isNextShifted = NO;

    // Save off last code
    lastCode = code;

    // Decode another code from image
    code = [self decodeCode:row counters:counters countersCount:countersLen rowOffset:nextStart];
    if (code == -1) {
      if (error) *error = NotFoundErrorInstance();
      return nil;
    }

    [rawCodes addObject:[NSNumber numberWithChar:(int8_t)code]];

    // Remember whether the last code was printable or not (excluding CODE_STOP)
    if (code != CODE_STOP) {
      lastCharacterWasPrintable = YES;
    }

    // Add to checksum computation (if not CODE_STOP of course)
    if (code != CODE_STOP) {
      multiplier++;
      checksumTotal += multiplier * code;
    }

    // Advance to where the next code will to start
    lastStart = nextStart;
    for (int i = 0; i < countersLen; i++) {
      nextStart += counters[i];
    }

    // Take care of illegal start codes
    switch (code) {
    case CODE_START_A:
    case CODE_START_B:
    case CODE_START_C:
      if (error) *error = FormatErrorInstance();
      return nil;
    }

    switch (codeSet) {
    case CODE_CODE_A:
      if (code < 64) {
        [result appendFormat:@"%C", (unichar)(' ' + code)];
      } else if (code < 96) {
        [result appendFormat:@"%C", (unichar)(code - 64)];
      } else {
        // Don't let CODE_STOP, which always appears, affect whether whether we think the last
        // code was printable or not.
        if (code != CODE_STOP) {
          lastCharacterWasPrintable = NO;
        }

        switch (code) {
        case CODE_FNC_1:
            if (convertFNC1) {
              if (result.length == 0) {
                // GS1 specification 5.4.3.7. and 5.4.6.4. If the first char after the start code
                // is FNC1 then this is GS1-128. We add the symbology identifier.
                [result appendString:@"]C1"];
              } else {
                // GS1 specification 5.4.7.5. Every subsequent FNC1 is returned as ASCII 29 (GS)
                [result appendFormat:@"%c", (char) 29];
              }
            }
            break;
        case CODE_FNC_2:
        case CODE_FNC_3:
        case CODE_FNC_4_A:
          break;
        case CODE_SHIFT:
          isNextShifted = YES;
          codeSet = CODE_CODE_B;
          break;
        case CODE_CODE_B:
          codeSet = CODE_CODE_B;
          break;
        case CODE_CODE_C:
          codeSet = CODE_CODE_C;
          break;
        case CODE_STOP:
          done = YES;
          break;
        }
      }
      break;
    case CODE_CODE_B:
      if (code < 96) {
        [result appendFormat:@"%C", (unichar)(' ' + code)];
      } else {
        if (code != CODE_STOP) {
          lastCharacterWasPrintable = NO;
        }

        switch (code) {
        case CODE_FNC_1:
            if (convertFNC1) {
              if (result.length == 0) {
                // GS1 specification 5.4.3.7. and 5.4.6.4. If the first char after the start code
                // is FNC1 then this is GS1-128. We add the symbology identifier.
                [result appendString:@"]C1"];
              } else {
                // GS1 specification 5.4.7.5. Every subsequent FNC1 is returned as ASCII 29 (GS)
                [result appendFormat:@"%c", (char) 29];
              }
            }
            break;
        case CODE_FNC_2:
        case CODE_FNC_3:
        case CODE_FNC_4_B:
          break;
        case CODE_SHIFT:
          isNextShifted = YES;
          codeSet = CODE_CODE_A;
          break;
        case CODE_CODE_A:
          codeSet = CODE_CODE_A;
          break;
        case CODE_CODE_C:
          codeSet = CODE_CODE_C;
          break;
        case CODE_STOP:
          done = YES;
          break;
        }
      }
      break;
    case CODE_CODE_C:
      if (code < 100) {
        if (code < 10) {
          [result appendString:@"0"];
        }
        [result appendFormat:@"%d", code];
      } else {
        if (code != CODE_STOP) {
          lastCharacterWasPrintable = NO;
        }

        switch (code) {
        case CODE_FNC_1:
            if (convertFNC1) {
              if (result.length == 0) {
                // GS1 specification 5.4.3.7. and 5.4.6.4. If the first char after the start code
                // is FNC1 then this is GS1-128. We add the symbology identifier.
                [result appendString:@"]C1"];
              } else {
                // GS1 specification 5.4.7.5. Every subsequent FNC1 is returned as ASCII 29 (GS)
                [result appendFormat:@"%c", (char) 29];
              }
            }
            break;
        case CODE_CODE_A:
          codeSet = CODE_CODE_A;
          break;
        case CODE_CODE_B:
          codeSet = CODE_CODE_B;
          break;
        case CODE_STOP:
          done = YES;
          break;
        }
      }
      break;
    }

    // Unshift back to another code set if we were shifted
    if (unshift) {
      codeSet = codeSet == CODE_CODE_A ? CODE_CODE_B : CODE_CODE_A;
    }
  }

  // Check for ample whitespace following pattern, but, to do this we first need to remember that
  // we fudged decoding CODE_STOP since it actually has 7 bars, not 6. There is a black bar left
  // to read off. Would be slightly better to properly read. Here we just skip it:
  nextStart = [row nextUnset:nextStart];
  if (![row isRange:nextStart end:MIN(row.size, nextStart + (nextStart - lastStart) / 2) value:NO]) {
    if (error) *error = NotFoundErrorInstance();
    return nil;
  }

  // Pull out from sum the value of the penultimate check code
  checksumTotal -= multiplier * lastCode;
  // lastCode is the checksum then:
  if (checksumTotal % 103 != lastCode) {
    if (error) *error = ChecksumErrorInstance();
    return nil;
  }

  // Need to pull out the check digits from string
  NSUInteger resultLength = [result length];
  if (resultLength == 0) {
    // false positive
    if (error) *error = NotFoundErrorInstance();
    return nil;
  }

  // Only bother if the result had at least one character, and if the checksum digit happened to
  // be a printable character. If it was just interpreted as a control code, nothing to remove.
  if (resultLength > 0 && lastCharacterWasPrintable) {
    if (codeSet == CODE_CODE_C) {
      [result deleteCharactersInRange:NSMakeRange(resultLength - 2, 2)];
    } else {
      [result deleteCharactersInRange:NSMakeRange(resultLength - 1, 1)];
    }
  }

  float left = (float)([startPatternInfo[1] intValue] + [startPatternInfo[0] intValue]) / 2.0f;
  float right = (float)(nextStart + lastStart) / 2.0f;

  NSUInteger rawCodesSize = [rawCodes count];
  int8_t rawBytes[rawCodesSize];
  for (int i = 0; i < rawCodesSize; i++) {
    rawBytes[i] = [rawCodes[i] charValue];
  }

  return [ZXResult resultWithText:result
                         rawBytes:rawBytes
                           length:(int)rawCodesSize
                     resultPoints:@[[[ZXResultPoint alloc] initWithX:left y:(float)rowNumber],
                                   [[ZXResultPoint alloc] initWithX:right y:(float)rowNumber]]
                           format:kBarcodeFormatCode128];
}

@end
