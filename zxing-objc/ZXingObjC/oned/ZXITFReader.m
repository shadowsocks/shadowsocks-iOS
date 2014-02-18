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
#import "ZXDecodeHints.h"
#import "ZXErrors.h"
#import "ZXITFReader.h"
#import "ZXResult.h"
#import "ZXResultPoint.h"

static int MAX_AVG_VARIANCE;
static int MAX_INDIVIDUAL_VARIANCE;

static const int W = 3; // Pixel width of a wide line
static const int N = 1; // Pixel width of a narrow line

int const DEFAULT_ALLOWED_LENGTHS[11] = { 48, 44, 24, 20, 18, 16, 14, 12, 10, 8, 6 };

/**
 * Start/end guard pattern.
 * 
 * Note: The end pattern is reversed because the row is reversed before
 * searching for the END_PATTERN
 */
int const ITF_START_PATTERN[4] = {N, N, N, N};
int const END_PATTERN_REVERSED[3] = {N, N, W};

/**
 * Patterns of Wide / Narrow lines to indicate each digit
 */
const int PATTERNS_LEN = 10;
const int PATTERNS[PATTERNS_LEN][5] = {
  {N, N, W, W, N}, // 0
  {W, N, N, N, W}, // 1
  {N, W, N, N, W}, // 2
  {W, W, N, N, N}, // 3
  {N, N, W, N, W}, // 4
  {W, N, W, N, N}, // 5
  {N, W, W, N, N}, // 6
  {N, N, N, W, W}, // 7
  {W, N, N, W, N}, // 8
  {N, W, N, W, N}  // 9
};

@interface ZXITFReader ()

@property (nonatomic, assign) int narrowLineWidth;

@end

@implementation ZXITFReader

+ (void)initialize {
  MAX_AVG_VARIANCE = (int)(PATTERN_MATCH_RESULT_SCALE_FACTOR * 0.42f);
  MAX_INDIVIDUAL_VARIANCE = (int)(PATTERN_MATCH_RESULT_SCALE_FACTOR * 0.8f);
}

- (id)init {
  if (self = [super init]) {
    _narrowLineWidth = -1;
  }

  return self;
}

- (ZXResult *)decodeRow:(int)rowNumber row:(ZXBitArray *)row hints:(ZXDecodeHints *)hints error:(NSError **)error {
  NSArray *startRange = [self decodeStart:row];
  NSArray *endRange = [self decodeEnd:row];
  if (!startRange || !endRange) {
    if (error) *error = NotFoundErrorInstance();
    return nil;
  }

  NSMutableString *resultString = [NSMutableString stringWithCapacity:20];
  if (![self decodeMiddle:row payloadStart:[startRange[1] intValue] payloadEnd:[endRange[0] intValue] resultString:resultString]) {
    if (error) *error = NotFoundErrorInstance();
    return nil;
  }

  NSArray *allowedLengths = nil;
  if (hints != nil) {
    allowedLengths = hints.allowedLengths;
  }
  if (allowedLengths == nil) {
    NSMutableArray *temp = [NSMutableArray array];
    for (int i = 0; i < sizeof(DEFAULT_ALLOWED_LENGTHS) / sizeof(int); i++) {
      [temp addObject:@(DEFAULT_ALLOWED_LENGTHS[i])];
    }
    allowedLengths = [NSArray arrayWithArray:temp];
  }

  NSUInteger length = [resultString length];
  BOOL lengthOK = NO;
  for (NSNumber *i in allowedLengths) {
    if (length == [i intValue]) {
      lengthOK = YES;
      break;
    }
  }
  if (!lengthOK) {
    if (error) *error = FormatErrorInstance();
    return nil;
  }

  return [ZXResult resultWithText:resultString
                         rawBytes:nil
                           length:0
                     resultPoints:@[[[ZXResultPoint alloc] initWithX:[startRange[1] floatValue] y:(float)rowNumber],
                                    [[ZXResultPoint alloc] initWithX:[endRange[0] floatValue] y:(float)rowNumber]]
                           format:kBarcodeFormatITF];
}


- (BOOL)decodeMiddle:(ZXBitArray *)row payloadStart:(int)payloadStart payloadEnd:(int)payloadEnd resultString:(NSMutableString *)resultString {
  const int counterDigitPairLen = 10;
  int counterDigitPair[counterDigitPairLen];
  memset(counterDigitPair, 0, counterDigitPairLen * sizeof(int));

  const int counterBlackLen = 5;
  int counterBlack[counterBlackLen];
  memset(counterBlack, 0, counterBlackLen * sizeof(int));

  const int counterWhiteLen = 5;
  int counterWhite[counterWhiteLen];
  memset(counterWhite, 0, counterWhiteLen * sizeof(int));

  while (payloadStart < payloadEnd) {
    if (![ZXOneDReader recordPattern:row start:payloadStart counters:counterDigitPair countersSize:counterDigitPairLen]) {
      return NO;
    }

    for (int k = 0; k < 5; k++) {
      int twoK = k << 1;
      counterBlack[k] = counterDigitPair[twoK];
      counterWhite[k] = counterDigitPair[twoK + 1];
    }

    int bestMatch = [self decodeDigit:counterBlack countersSize:counterBlackLen];
    if (bestMatch == -1) {
      return NO;
    }
    [resultString appendFormat:@"%C", (unichar)('0' + bestMatch)];
    bestMatch = [self decodeDigit:counterWhite countersSize:counterWhiteLen];
    if (bestMatch == -1) {
      return NO;
    }
    [resultString appendFormat:@"%C", (unichar)('0' + bestMatch)];

    for (int i = 0; i < counterDigitPairLen; i++) {
      payloadStart += counterDigitPair[i];
    }
  }
  return YES;
}


/**
 * Identify where the start of the middle / payload section starts.
 */
- (NSArray *)decodeStart:(ZXBitArray *)row {
  int endStart = [self skipWhiteSpace:row];
  if (endStart == -1) {
    return nil;
  }
  NSArray *startPattern = [self findGuardPattern:row rowOffset:endStart pattern:(int *)ITF_START_PATTERN patternLen:sizeof(ITF_START_PATTERN)/sizeof(int)];
  if (!startPattern) {
    return nil;
  }

  self.narrowLineWidth = ([startPattern[1] intValue] - [startPattern[0] intValue]) >> 2;

  if (![self validateQuietZone:row startPattern:[startPattern[0] intValue]]) {
    return nil;
  }

  return startPattern;
}


/**
 * The start & end patterns must be pre/post fixed by a quiet zone. This
 * zone must be at least 10 times the width of a narrow line.  Scan back until
 * we either get to the start of the barcode or match the necessary number of
 * quiet zone pixels.
 * 
 * Note: Its assumed the row is reversed when using this method to find
 * quiet zone after the end pattern.
 * 
 * ref: http://www.barcode-1.net/i25code.html
 */
- (BOOL)validateQuietZone:(ZXBitArray *)row startPattern:(int)startPattern {
  int quietCount = self.narrowLineWidth * 10;

  for (int i = startPattern - 1; quietCount > 0 && i >= 0; i--) {
    if ([row get:i]) {
      break;
    }
    quietCount--;
  }
  if (quietCount != 0) {
    return NO;
  }
  return YES;
}


/**
 * Skip all whitespace until we get to the first black line.
 */
- (int)skipWhiteSpace:(ZXBitArray *)row {
  int width = [row size];
  int endStart = [row nextSet:0];
  if (endStart == width) {
    return -1;
  }
  return endStart;
}


/**
 * Identify where the end of the middle / payload section ends.
 */
- (NSArray *)decodeEnd:(ZXBitArray *)row {
  [row reverse];

  int endStart = [self skipWhiteSpace:row];
  if (endStart == -1) {
    [row reverse];
    return nil;
  }
  NSMutableArray *endPattern = [[self findGuardPattern:row rowOffset:endStart pattern:(int *)END_PATTERN_REVERSED patternLen:sizeof(END_PATTERN_REVERSED)/sizeof(int)] mutableCopy];
  if (!endPattern) {
    [row reverse];
    return nil;
  }
  [self validateQuietZone:row startPattern:[endPattern[0] intValue]];
  int temp = [endPattern[0] intValue];
  endPattern[0] = @([row size] - [endPattern[1] intValue]);
  endPattern[1] = @([row size] - temp);
  [row reverse];
  return endPattern;
}

- (NSArray *)findGuardPattern:(ZXBitArray *)row rowOffset:(int)rowOffset pattern:(int[])pattern patternLen:(int)patternLen {
  int patternLength = patternLen;
  int counters[patternLength];
  memset(counters, 0, patternLength * sizeof(int));
  int width = row.size;
  BOOL isWhite = NO;

  int counterPosition = 0;
  int patternStart = rowOffset;
  for (int x = rowOffset; x < width; x++) {
    if ([row get:x] ^ isWhite) {
      counters[counterPosition]++;
    } else {
      if (counterPosition == patternLength - 1) {
        if ([ZXOneDReader patternMatchVariance:counters countersSize:patternLength pattern:pattern maxIndividualVariance:MAX_INDIVIDUAL_VARIANCE] < MAX_AVG_VARIANCE) {
          return @[@(patternStart), @(x)];
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

/**
 * Attempts to decode a sequence of ITF black/white lines into single
 * digit.
 */
- (int)decodeDigit:(int[])counters countersSize:(int)countersSize {
  int bestVariance = MAX_AVG_VARIANCE;
  int bestMatch = -1;
  int max = PATTERNS_LEN;
  for (int i = 0; i < max; i++) {
    int pattern[countersSize];
    for(int ind = 0; ind<countersSize; ind++){
      pattern[ind] = PATTERNS[i][ind];
    }
    int variance = [ZXOneDReader patternMatchVariance:counters countersSize:countersSize pattern:pattern maxIndividualVariance:MAX_INDIVIDUAL_VARIANCE];
    if (variance < bestVariance) {
      bestVariance = variance;
      bestMatch = i;
    }
  }
  if (bestMatch >= 0) {
    return bestMatch;
  } else {
    return -1;
  }
}

@end
