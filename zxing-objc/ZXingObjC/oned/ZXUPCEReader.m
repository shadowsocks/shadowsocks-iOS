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
#import "ZXErrors.h"
#import "ZXUPCEReader.h"

/**
 * The pattern that marks the middle, and end, of a UPC-E pattern.
 * There is no "second half" to a UPC-E barcode.
 */
#define MIDDLE_END_PATTERN_LEN 6
const int MIDDLE_END_PATTERN[MIDDLE_END_PATTERN_LEN] = {1, 1, 1, 1, 1, 1};

/**
 * See {@link #L_AND_G_PATTERNS}; these values similarly represent patterns of
 * even-odd parity encodings of digits that imply both the number system (0 or 1)
 * used, and the check digit.
 */
const int NUMSYS_AND_CHECK_DIGIT_PATTERNS[2][10] = {
  {0x38, 0x34, 0x32, 0x31, 0x2C, 0x26, 0x23, 0x2A, 0x29, 0x25},
  {0x07, 0x0B, 0x0D, 0x0E, 0x13, 0x19, 0x1C, 0x15, 0x16, 0x1A}
};

@interface ZXUPCEReader ()

@property (nonatomic, assign) int *decodeMiddleCounters;

@end

@implementation ZXUPCEReader

- (id)init {
  if (self = [super init]) {
    _decodeMiddleCounters = (int *)malloc(sizeof(4) * sizeof(int));
    _decodeMiddleCounters[0] = 0;
    _decodeMiddleCounters[1] = 0;
    _decodeMiddleCounters[2] = 0;
    _decodeMiddleCounters[3] = 0;
  }

  return self;
}

- (void)dealloc {
  if (_decodeMiddleCounters != NULL) {
    free(_decodeMiddleCounters);
    _decodeMiddleCounters = NULL;
  }
}

- (int)decodeMiddle:(ZXBitArray *)row startRange:(NSRange)startRange result:(NSMutableString *)result error:(NSError **)error {
  const int countersLen = 4;
  int counters[countersLen];
  memset(counters, 0, countersLen * sizeof(int));

  int end = [row size];
  int rowOffset = (int)NSMaxRange(startRange);
  int lgPatternFound = 0;

  for (int x = 0; x < 6 && rowOffset < end; x++) {
    int bestMatch = [ZXUPCEANReader decodeDigit:row counters:counters countersLen:countersLen rowOffset:rowOffset patternType:UPC_EAN_PATTERNS_L_AND_G_PATTERNS error:error];
    if (bestMatch == -1) {
      return -1;
    }
    [result appendFormat:@"%C", (unichar)('0' + bestMatch % 10)];

    for (int i = 0; i < sizeof(counters) / sizeof(int); i++) {
      rowOffset += counters[i];
    }

    if (bestMatch >= 10) {
      lgPatternFound |= 1 << (5 - x);
    }
  }

  if (![self determineNumSysAndCheckDigit:result lgPatternFound:lgPatternFound]) {
    if (error) *error = NotFoundErrorInstance();
    return -1;
  }
  return rowOffset;
}

- (NSRange)decodeEnd:(ZXBitArray *)row endStart:(int)endStart error:(NSError **)error {
  return [ZXUPCEANReader findGuardPattern:row rowOffset:endStart whiteFirst:YES pattern:(int *)MIDDLE_END_PATTERN patternLen:MIDDLE_END_PATTERN_LEN error:error];
}

- (BOOL)checkChecksum:(NSString *)s error:(NSError **)error {
  return [super checkChecksum:[ZXUPCEReader convertUPCEtoUPCA:s] error:error];
}

- (BOOL)determineNumSysAndCheckDigit:(NSMutableString *)resultString lgPatternFound:(int)lgPatternFound {
  for (int numSys = 0; numSys <= 1; numSys++) {
    for (int d = 0; d < 10; d++) {
      if (lgPatternFound == NUMSYS_AND_CHECK_DIGIT_PATTERNS[numSys][d]) {
        [resultString insertString:[NSString stringWithFormat:@"%C", (unichar)('0' + numSys)] atIndex:0];
        [resultString appendFormat:@"%C", (unichar)('0' + d)];
        return YES;
      }
    }
  }

  return NO;
}

- (ZXBarcodeFormat)barcodeFormat {
  return kBarcodeFormatUPCE;
}

/**
 * Expands a UPC-E value back into its full, equivalent UPC-A code value.
 */
+ (NSString *)convertUPCEtoUPCA:(NSString *)upce {
  NSString *upceChars = [upce substringWithRange:NSMakeRange(1, 6)];
  NSMutableString *result = [NSMutableString stringWithCapacity:12];
  [result appendFormat:@"%C", [upce characterAtIndex:0]];
  unichar lastChar = [upceChars characterAtIndex:5];
  switch (lastChar) {
    case '0':
    case '1':
    case '2':
      [result appendString:[upceChars substringToIndex:2]];
      [result appendFormat:@"%C", lastChar];
      [result appendString:@"0000"];
      [result appendString:[upceChars substringWithRange:NSMakeRange(2, 3)]];
      break;
    case '3':
      [result appendString:[upceChars substringToIndex:3]];
      [result appendString:@"00000"];
      [result appendString:[upceChars substringWithRange:NSMakeRange(3, 2)]];
      break;
    case '4':
      [result appendString:[upceChars substringToIndex:4]];
      [result appendString:@"00000"];
      [result appendString:[upceChars substringWithRange:NSMakeRange(4, 1)]];
      break;
    default:
      [result appendString:[upceChars substringToIndex:5]];
      [result appendString:@"0000"];
      [result appendFormat:@"%C", lastChar];
      break;
  }
  [result appendFormat:@"%C", [upce characterAtIndex:7]];
  return result;
}

@end
