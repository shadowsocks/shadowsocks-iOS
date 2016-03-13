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
#import "ZXEAN8Reader.h"

@interface ZXEAN8Reader ()

@property (nonatomic, assign) int *decodeMiddleCounters;

@end

@implementation ZXEAN8Reader

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

  int end = row.size;
  int rowOffset = (int)NSMaxRange(startRange);

  for (int x = 0; x < 4 && rowOffset < end; x++) {
    int bestMatch = [ZXUPCEANReader decodeDigit:row counters:counters countersLen:countersLen rowOffset:rowOffset patternType:UPC_EAN_PATTERNS_L_PATTERNS error:error];
    if (bestMatch == -1) {
      return -1;
    }
    [result appendFormat:@"%C", (unichar)('0' + bestMatch)];
    for (int i = 0; i < countersLen; i++) {
      rowOffset += counters[i];
    }
  }

  NSRange middleRange = [[self class] findGuardPattern:row rowOffset:rowOffset whiteFirst:YES pattern:(int *)MIDDLE_PATTERN patternLen:MIDDLE_PATTERN_LEN error:error];
  if (middleRange.location == NSNotFound) {
    return -1;
  }
  rowOffset = (int)NSMaxRange(middleRange);

  for (int x = 0; x < 4 && rowOffset < end; x++) {
    int bestMatch = [ZXUPCEANReader decodeDigit:row counters:counters countersLen:countersLen rowOffset:rowOffset patternType:UPC_EAN_PATTERNS_L_PATTERNS error:error];
    if (bestMatch == -1) {
      return -1;
    }
    [result appendFormat:@"%C", (unichar)('0' + bestMatch)];
    for (int i = 0; i < countersLen; i++) {
      rowOffset += counters[i];
    }
  }

  return rowOffset;
}

- (ZXBarcodeFormat)barcodeFormat {
  return kBarcodeFormatEan8;
}

@end
