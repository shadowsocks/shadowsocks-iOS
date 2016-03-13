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
#import "ZXCodaBarReader.h"
#import "ZXErrors.h"
#import "ZXResult.h"
#import "ZXResultPoint.h"

// These values are critical for determining how permissive the decoding
// will be. All stripe sizes must be within the window these define, as
// compared to the average stripe size.
static int MAX_ACCEPTABLE;
static int PADDING;

const int CODA_ALPHABET_LEN = 22;
const char CODA_ALPHABET[CODA_ALPHABET_LEN] = "0123456789-$:/.+ABCDTN";

/**
 * These represent the encodings of characters, as patterns of wide and narrow bars. The 7 least-significant bits of
 * each int correspond to the pattern of wide and narrow, with 1s representing "wide" and 0s representing narrow.
 */
const int CODA_CHARACTER_ENCODINGS_LEN = 20;
const int CODA_CHARACTER_ENCODINGS[CODA_CHARACTER_ENCODINGS_LEN] = {
  0x003, 0x006, 0x009, 0x060, 0x012, 0x042, 0x021, 0x024, 0x030, 0x048, // 0-9
  0x00c, 0x018, 0x045, 0x051, 0x054, 0x015, 0x01A, 0x029, 0x00B, 0x00E, // -$:/.+ABCD
};

// minimal number of characters that should be present (inclusing start and stop characters)
// under normal circumstances this should be set to 3, but can be set higher
// as a last-ditch attempt to reduce false positives.
const int MIN_CHARACTER_LENGTH = 3;

// official start and end patterns
const int STARTEND_ENCODING_LEN = 4;
const char STARTEND_ENCODING[STARTEND_ENCODING_LEN]  = {'A', 'B', 'C', 'D'};

// some codabar generator allow the codabar string to be closed by every
// character. This will cause lots of false positives!

// some industries use a checksum standard but this is not part of the original codabar standard
// for more information see : http://www.mecsw.com/specs/codabar.html

@interface ZXCodaBarReader ()

@property (nonatomic, strong) NSMutableString *decodeRowResult;
@property (nonatomic, assign) int *counters;
@property (nonatomic, assign) int countersLen;
@property (nonatomic, assign) int counterLength;

@end

@implementation ZXCodaBarReader

+ (void)initialize {
  MAX_ACCEPTABLE = (int) (PATTERN_MATCH_RESULT_SCALE_FACTOR * 2.0f);
  PADDING = (int) (PATTERN_MATCH_RESULT_SCALE_FACTOR * 1.5f);
}

- (id)init {
  if (self = [super init]) {
    _decodeRowResult = [NSMutableString stringWithCapacity:20];
    _countersLen = 80;
    _counters = (int *)malloc(_countersLen * sizeof(int));
    memset(_counters, 0, _countersLen * sizeof(int));
    _counterLength = 0;
  }

  return self;
}

- (void)dealloc {
  if (_counters != NULL) {
    free(_counters);
    _counters = NULL;
  }
}

- (ZXResult *)decodeRow:(int)rowNumber row:(ZXBitArray *)row hints:(ZXDecodeHints *)hints error:(NSError **)error {
  if (![self setCountersWithRow:row]) {
    if (error) *error = NotFoundErrorInstance();
    return nil;
  }

  int startOffset = [self findStartPattern];
  if (startOffset == -1) {
    if (error) *error = NotFoundErrorInstance();
    return nil;
  }

  int nextStart = startOffset;

  self.decodeRowResult = [NSMutableString string];
  do {
    int charOffset = [self toNarrowWidePattern:nextStart];
    if (charOffset == -1) {
      if (error) *error = NotFoundErrorInstance();
      return nil;
    }
    // Hack: We store the position in the alphabet table into a
    // NSMutableString, so that we can access the decoded patterns in
    // validatePattern. We'll translate to the actual characters later.
    [self.decodeRowResult appendFormat:@"%C", (unichar)charOffset];
    nextStart += 8;
    // Stop as soon as we see the end character.
    if (self.decodeRowResult.length > 1 &&
        [ZXCodaBarReader arrayContains:(char *)STARTEND_ENCODING length:STARTEND_ENCODING_LEN key:CODA_ALPHABET[charOffset]]) {
      break;
    }
  } while (nextStart < self.counterLength); // no fixed end pattern so keep on reading while data is available

  // Look for whitespace after pattern:
  int trailingWhitespace = self.counters[nextStart - 1];
  int lastPatternSize = 0;
  for (int i = -8; i < -1; i++) {
    lastPatternSize += self.counters[nextStart + i];
  }

  // We need to see whitespace equal to 50% of the last pattern size,
  // otherwise this is probably a false positive. The exception is if we are
  // at the end of the row. (I.e. the barcode barely fits.)
  if (nextStart < self.counterLength && trailingWhitespace < lastPatternSize / 2) {
    if (error) *error = NotFoundErrorInstance();
    return nil;
  }

  if (![self validatePattern:startOffset]) {
    if (error) *error = NotFoundErrorInstance();
    return nil;
  }

  // Translate character table offsets to actual characters.
  for (int i = 0; i < self.decodeRowResult.length; i++) {
    [self.decodeRowResult replaceCharactersInRange:NSMakeRange(i, 1) withString:[NSString stringWithFormat:@"%c", CODA_ALPHABET[[self.decodeRowResult characterAtIndex:i]]]];
  }
  // Ensure a valid start and end character
  unichar startchar = [self.decodeRowResult characterAtIndex:0];
  if (![ZXCodaBarReader arrayContains:(char *)STARTEND_ENCODING length:STARTEND_ENCODING_LEN key:startchar]) {
    if (error) *error = NotFoundErrorInstance();
    return nil;
  }
  unichar endchar = [self.decodeRowResult characterAtIndex:self.decodeRowResult.length - 1];
  if (![ZXCodaBarReader arrayContains:(char *)STARTEND_ENCODING length:STARTEND_ENCODING_LEN key:endchar]) {
    if (error) *error = NotFoundErrorInstance();
    return nil;
  }

  // remove stop/start characters character and check if a long enough string is contained
  if (self.decodeRowResult.length <= MIN_CHARACTER_LENGTH) {
    if (error) *error = NotFoundErrorInstance();
    return nil;
  }

  [self.decodeRowResult deleteCharactersInRange:NSMakeRange(self.decodeRowResult.length - 1, 1)];
  [self.decodeRowResult deleteCharactersInRange:NSMakeRange(0, 1)];

  int runningCount = 0;
  for (int i = 0; i < startOffset; i++) {
    runningCount += self.counters[i];
  }
  float left = (float) runningCount;
  for (int i = startOffset; i < nextStart - 1; i++) {
    runningCount += self.counters[i];
  }
  float right = (float) runningCount;
  return [ZXResult resultWithText:self.decodeRowResult
                         rawBytes:nil
                           length:0
                     resultPoints:@[[[ZXResultPoint alloc] initWithX:left y:(float)rowNumber],
                                    [[ZXResultPoint alloc] initWithX:right y:(float)rowNumber]]
                           format:kBarcodeFormatCodabar];
}

- (BOOL)validatePattern:(int)start {
  // First, sum up the total size of our four categories of stripe sizes;
  int sizes[4] = {0, 0, 0, 0};
  int counts[4] = {0, 0, 0, 0};
  int end = (int)self.decodeRowResult.length - 1;

  // We break out of this loop in the middle, in order to handle
  // inter-character spaces properly.
  int pos = start;
  for (int i = 0; true; i++) {
    int pattern = CODA_CHARACTER_ENCODINGS[[self.decodeRowResult characterAtIndex:i]];
    for (int j = 6; j >= 0; j--) {
      // Even j = bars, while odd j = spaces. Categories 2 and 3 are for
      // long stripes, while 0 and 1 are for short stripes.
      int category = (j & 1) + (pattern & 1) * 2;
      sizes[category] += self.counters[pos + j];
      counts[category]++;
      pattern >>= 1;
    }
    if (i >= end) {
      break;
    }
    // We ignore the inter-character space - it could be of any size.
    pos += 8;
  }

  // Calculate our allowable size thresholds using fixed-point math.
  int maxes[4] = {0};
  int mins[4] = {0};
  // Define the threshold of acceptability to be the midpoint between the
  // average small stripe and the average large stripe. No stripe lengths
  // should be on the "wrong" side of that line.
  for (int i = 0; i < 2; i++) {
    mins[i] = 0;  // Accept arbitrarily small "short" stripes.
    mins[i + 2] = ((sizes[i] << INTEGER_MATH_SHIFT) / counts[i] +
                   (sizes[i + 2] << INTEGER_MATH_SHIFT) / counts[i + 2]) >> 1;
    maxes[i] = mins[i + 2];
    maxes[i + 2] = (sizes[i + 2] * MAX_ACCEPTABLE + PADDING) / counts[i + 2];
  }

  // Now verify that all of the stripes are within the thresholds.
  pos = start;
  for (int i = 0; true; i++) {
    int pattern = CODA_CHARACTER_ENCODINGS[[self.decodeRowResult characterAtIndex:i]];
    for (int j = 6; j >= 0; j--) {
      // Even j = bars, while odd j = spaces. Categories 2 and 3 are for
      // long stripes, while 0 and 1 are for short stripes.
      int category = (j & 1) + (pattern & 1) * 2;
      int size = self.counters[pos + j] << INTEGER_MATH_SHIFT;
      if (size < mins[category] || size > maxes[category]) {
        return NO;
      }
      pattern >>= 1;
    }
    if (i >= end) {
      break;
    }
    pos += 8;
  }

  return YES;
}

/**
 * Records the size of all runs of white and black pixels, starting with white.
 * This is just like recordPattern, except it records all the counters, and
 * uses our builtin "counters" member for storage.
 */
- (BOOL)setCountersWithRow:(ZXBitArray *)row {
  self.counterLength = 0;
  // Start from the first white bit.
  int i = [row nextUnset:0];
  int end = row.size;
  if (i >= end) {
    return NO;
  }
  BOOL isWhite = YES;
  int count = 0;
  for (; i < end; i++) {
    if ([row get:i] ^ isWhite) { // that is, exactly one is true
      count++;
    } else {
      [self counterAppend:count];
      count = 1;
      isWhite = !isWhite;
    }
  }
  [self counterAppend:count];
  return YES;
}

- (void)counterAppend:(int)e {
  self.counters[self.counterLength] = e;
  self.counterLength++;
  if (self.counterLength >= self.countersLen) {
    int *temp = (int *)malloc(2 * self.counterLength * sizeof(int));
    memcpy(temp, self.counters, self.countersLen * sizeof(int));
    self.counters = temp;
    memset(self.counters, 0, 2 * self.counterLength * sizeof(int));
    self.countersLen = 2 * self.counterLength;
  }
}

- (int)findStartPattern {
  for (int i = 1; i < self.counterLength; i += 2) {
    int charOffset = [self toNarrowWidePattern:i];
    if (charOffset != -1 && [[self class] arrayContains:(char *)STARTEND_ENCODING length:STARTEND_ENCODING_LEN key:CODA_ALPHABET[charOffset]]) {
      // Look for whitespace before start pattern, >= 50% of width of start pattern
      // We make an exception if the whitespace is the first element.
      int patternSize = 0;
      for (int j = i; j < i + 7; j++) {
        patternSize += self.counters[j];
      }
      if (i == 1 || self.counters[i-1] >= patternSize / 2) {
        return i;
      }
    }
  }

  return -1;
}

+ (BOOL)arrayContains:(char *)array length:(unsigned int)length key:(unichar)key {
  if (array != nil) {
    for (int i = 0; i < length; i++) {
      if (array[i] == key) {
        return YES;
      }
    }
  }
  return NO;
}

// Assumes that counters[position] is a bar.
- (int)toNarrowWidePattern:(int)position {
  int end = position + 7;
  if (end >= self.counterLength) {
    return -1;
  }

  int maxBar = 0;
  int minBar = INT_MAX;
  for (int j = position; j < end; j += 2) {
    int currentCounter = self.counters[j];
    if (currentCounter < minBar) {
      minBar = currentCounter;
    }
    if (currentCounter > maxBar) {
      maxBar = currentCounter;
    }
  }
  int thresholdBar = (minBar + maxBar) / 2;

  int maxSpace = 0;
  int minSpace = INT_MAX;
  for (int j = position + 1; j < end; j += 2) {
    int currentCounter = self.counters[j];
    if (currentCounter < minSpace) {
      minSpace = currentCounter;
    }
    if (currentCounter > maxSpace) {
      maxSpace = currentCounter;
    }
  }
  int thresholdSpace = (minSpace + maxSpace) / 2;

  int bitmask = 1 << 7;
  int pattern = 0;
  for (int i = 0; i < 7; i++) {
    int threshold = (i & 1) == 0 ? thresholdBar : thresholdSpace;
    bitmask >>= 1;
    if (self.counters[position + i] > threshold) {
      pattern |= bitmask;
    }
  }

  for (int i = 0; i < CODA_CHARACTER_ENCODINGS_LEN; i++) {
    if (CODA_CHARACTER_ENCODINGS[i] == pattern) {
      return i;
    }
  }
  return -1;
}

@end
