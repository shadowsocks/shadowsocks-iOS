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

#import "ZXAI01393xDecoder.h"
#import "ZXBitArray.h"
#import "ZXDecodedInformation.h"
#import "ZXErrors.h"
#import "ZXGeneralAppIdDecoder.h"

@implementation ZXAI01393xDecoder

int const AI01393xDecoder_HEADER_SIZE = 5 + 1 + 2;
int const AI01393xDecoder_LAST_DIGIT_SIZE = 2;
int const AI01393xDecoder_FIRST_THREE_DIGITS_SIZE = 10;

- (NSString *)parseInformationWithError:(NSError **)error {
  if (self.information.size < AI01393xDecoder_HEADER_SIZE + GTIN_SIZE) {
    if (error) *error = NotFoundErrorInstance();
    return nil;
  }

  NSMutableString *buf = [NSMutableString string];

  [self encodeCompressedGtin:buf currentPos:AI01393xDecoder_HEADER_SIZE];

  int lastAIdigit = [self.generalDecoder extractNumericValueFromBitArray:AI01393xDecoder_HEADER_SIZE + GTIN_SIZE bits:AI01393xDecoder_LAST_DIGIT_SIZE];

  [buf appendFormat:@"(393%d)", lastAIdigit];

  int firstThreeDigits = [self.generalDecoder extractNumericValueFromBitArray:AI01393xDecoder_HEADER_SIZE + GTIN_SIZE + AI01393xDecoder_LAST_DIGIT_SIZE bits:AI01393xDecoder_FIRST_THREE_DIGITS_SIZE];
  if (firstThreeDigits / 100 == 0) {
    [buf appendString:@"0"];
  }
  if (firstThreeDigits / 10 == 0) {
    [buf appendString:@"0"];
  }
  [buf appendFormat:@"%d", firstThreeDigits];

  ZXDecodedInformation *generalInformation = [self.generalDecoder decodeGeneralPurposeField:AI01393xDecoder_HEADER_SIZE + GTIN_SIZE + AI01393xDecoder_LAST_DIGIT_SIZE + AI01393xDecoder_FIRST_THREE_DIGITS_SIZE remaining:nil];
  [buf appendString:generalInformation.theNewString];

  return buf;
}

@end
