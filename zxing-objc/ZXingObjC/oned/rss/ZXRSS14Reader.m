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
#import "ZXBarcodeFormat.h"
#import "ZXDecodeHints.h"
#import "ZXErrors.h"
#import "ZXPair.h"
#import "ZXResult.h"
#import "ZXResultPointCallback.h"
#import "ZXRSS14Reader.h"
#import "ZXRSSFinderPattern.h"
#import "ZXRSSUtils.h"

const int OUTSIDE_EVEN_TOTAL_SUBSET[5] = {1,10,34,70,126};
const int INSIDE_ODD_TOTAL_SUBSET[4] = {4,20,48,81};
const int OUTSIDE_GSUM[5] = {0,161,961,2015,2715};
const int INSIDE_GSUM[4] = {0,336,1036,1516};
const int OUTSIDE_ODD_WIDEST[5] = {8,6,4,3,1};
const int INSIDE_ODD_WIDEST[4] = {2,4,6,8};

@interface ZXRSS14Reader ()

@property (nonatomic, strong) NSMutableArray *possibleLeftPairs;
@property (nonatomic, strong) NSMutableArray *possibleRightPairs;

@end

@implementation ZXRSS14Reader

- (id)init {
  if (self = [super init]) {
    _possibleLeftPairs = [NSMutableArray array];
    _possibleRightPairs = [NSMutableArray array];
  }

  return self;
}

- (ZXResult *)decodeRow:(int)rowNumber row:(ZXBitArray *)row hints:(ZXDecodeHints *)hints error:(NSError **)error {
  ZXPair *leftPair = [self decodePair:row right:NO rowNumber:rowNumber hints:hints];
  [self addOrTally:self.possibleLeftPairs pair:leftPair];
  [row reverse];
  ZXPair *rightPair = [self decodePair:row right:YES rowNumber:rowNumber hints:hints];
  [self addOrTally:self.possibleRightPairs pair:rightPair];
  [row reverse];

  for (ZXPair *left in self.possibleLeftPairs) {
    if ([left count] > 1) {
      for (ZXPair *right in self.possibleRightPairs) {
        if ([right count] > 1) {
          if ([self checkChecksum:left rightPair:right]) {
            return [self constructResult:left rightPair:right];
          }
        }
      }
    }
  }

  if (error) *error = NotFoundErrorInstance();
  return nil;
}

- (void)addOrTally:(NSMutableArray *)possiblePairs pair:(ZXPair *)pair {
  if (pair == nil) {
    return;
  }
  BOOL found = NO;
  for (ZXPair *other in possiblePairs) {
    if (other.value == pair.value) {
      [other incrementCount];
      found = YES;
      break;
    }
  }

  if (!found) {
    [possiblePairs addObject:pair];
  }
}

- (void)reset {
  [self.possibleLeftPairs removeAllObjects];
  [self.possibleRightPairs removeAllObjects];
}

- (ZXResult *)constructResult:(ZXPair *)leftPair rightPair:(ZXPair *)rightPair {
  long long symbolValue = 4537077LL * leftPair.value + rightPair.value;
  NSString *text = [@(symbolValue) stringValue];
  NSMutableString *buffer = [NSMutableString stringWithCapacity:14];

  for (int i = 13 - (int)[text length]; i > 0; i--) {
    [buffer appendString:@"0"];
  }

  [buffer appendString:text];
  int checkDigit = 0;

  for (int i = 0; i < 13; i++) {
    int digit = [buffer characterAtIndex:i] - '0';
    checkDigit += (i & 0x01) == 0 ? 3 * digit : digit;
  }

  checkDigit = 10 - (checkDigit % 10);
  if (checkDigit == 10) {
    checkDigit = 0;
  }
  [buffer appendFormat:@"%d", checkDigit];
  NSArray *leftPoints = [[leftPair finderPattern] resultPoints];
  NSArray *rightPoints = [[rightPair finderPattern] resultPoints];
  return [ZXResult resultWithText:buffer
                         rawBytes:NULL
                           length:0
                     resultPoints:@[leftPoints[0], leftPoints[1], rightPoints[0], rightPoints[1]]
                           format:kBarcodeFormatRSS14];
}

- (BOOL)checkChecksum:(ZXPair *)leftPair rightPair:(ZXPair *)rightPair {
//  int leftFPValue = leftPair.finderPattern.value;
//  int rightFPValue = rightPair.finderPattern.value;
//  if ((leftFPValue == 0 && rightFPValue == 8) || (leftFPValue == 8 && rightFPValue == 0)) {
//  }
  int checkValue = (leftPair.checksumPortion + 16 * rightPair.checksumPortion) % 79;
  int targetCheckValue = 9 * leftPair.finderPattern.value + rightPair.finderPattern.value;
  if (targetCheckValue > 72) {
    targetCheckValue--;
  }
  if (targetCheckValue > 8) {
    targetCheckValue--;
  }
  return checkValue == targetCheckValue;
}

- (ZXPair *)decodePair:(ZXBitArray *)row right:(BOOL)right rowNumber:(int)rowNumber hints:(ZXDecodeHints *)hints {
  NSArray *startEnd = [self findFinderPattern:row rowOffset:0 rightFinderPattern:right];
  if (!startEnd) {
    return nil;
  }
  ZXRSSFinderPattern *pattern = [self parseFoundFinderPattern:row rowNumber:rowNumber right:right startEnd:startEnd];
  if (!pattern) {
    return nil;
  }
  id<ZXResultPointCallback> resultPointCallback = hints == nil ? nil : hints.resultPointCallback;
  if (resultPointCallback != nil) {
    float center = ([startEnd[0] intValue] + [startEnd[1] intValue]) / 2.0f;
    if (right) {
      center = [row size] - 1 - center;
    }
    [resultPointCallback foundPossibleResultPoint:[[ZXResultPoint alloc] initWithX:center y:rowNumber]];
  }
  ZXDataCharacter *outside = [self decodeDataCharacter:row pattern:pattern outsideChar:YES];
  ZXDataCharacter *inside = [self decodeDataCharacter:row pattern:pattern outsideChar:NO];
  if (!outside || !inside) {
    return nil;
  }
  return [[ZXPair alloc] initWithValue:1597 * outside.value + inside.value
                        checksumPortion:outside.checksumPortion + 4 * inside.checksumPortion
                          finderPattern:pattern];
}

- (ZXDataCharacter *)decodeDataCharacter:(ZXBitArray *)row pattern:(ZXRSSFinderPattern *)pattern outsideChar:(BOOL)outsideChar {
  int countersLen = self.dataCharacterCountersLen;
  int *counters = self.dataCharacterCounters;
  counters[0] = 0;
  counters[1] = 0;
  counters[2] = 0;
  counters[3] = 0;
  counters[4] = 0;
  counters[5] = 0;
  counters[6] = 0;
  counters[7] = 0;

  if (outsideChar) {
    if (![ZXOneDReader recordPatternInReverse:row start:[[pattern startEnd][0] intValue] counters:counters countersSize:countersLen]) {
      return nil;
    }
  } else {
    if (![ZXOneDReader recordPattern:row start:[[pattern startEnd][1] intValue] counters:counters countersSize:countersLen]) {
      return nil;
    }

    for (int i = 0, j = countersLen - 1; i < j; i++, j--) {
      int temp = counters[i];
      counters[i] = counters[j];
      counters[j] = temp;
    }
  }

  int numModules = outsideChar ? 16 : 15;
  float elementWidth = (float)[ZXAbstractRSSReader count:counters arrayLen:countersLen] / (float)numModules;

  for (int i = 0; i < countersLen; i++) {
    float value = (float) counters[i] / elementWidth;
    int count = (int)(value + 0.5f);
    if (count < 1) {
      count = 1;
    } else if (count > 8) {
      count = 8;
    }
    int offset = i >> 1;
    if ((i & 0x01) == 0) {
      self.oddCounts[offset] = count;
      self.oddRoundingErrors[offset] = value - count;
    } else {
      self.evenCounts[offset] = count;
      self.evenRoundingErrors[offset] = value - count;
    }
  }

  if (![self adjustOddEvenCounts:outsideChar numModules:numModules]) {
    return nil;
  }

  int oddSum = 0;
  int oddChecksumPortion = 0;
  for (int i = self.oddCountsLen - 1; i >= 0; i--) {
    oddChecksumPortion *= 9;
    oddChecksumPortion += self.oddCounts[i];
    oddSum += self.oddCounts[i];
  }
  int evenChecksumPortion = 0;
  int evenSum = 0;
  for (int i = self.evenCountsLen - 1; i >= 0; i--) {
    evenChecksumPortion *= 9;
    evenChecksumPortion += self.evenCounts[i];
    evenSum += self.evenCounts[i];
  }
  int checksumPortion = oddChecksumPortion + 3 * evenChecksumPortion;

  if (outsideChar) {
    if ((oddSum & 0x01) != 0 || oddSum > 12 || oddSum < 4) {
      return nil;
    }
    int group = (12 - oddSum) / 2;
    int oddWidest = OUTSIDE_ODD_WIDEST[group];
    int evenWidest = 9 - oddWidest;
    int vOdd = [ZXRSSUtils rssValue:self.oddCounts widthsLen:self.oddCountsLen maxWidth:oddWidest noNarrow:NO];
    int vEven = [ZXRSSUtils rssValue:self.evenCounts widthsLen:self.evenCountsLen maxWidth:evenWidest noNarrow:YES];
    int tEven = OUTSIDE_EVEN_TOTAL_SUBSET[group];
    int gSum = OUTSIDE_GSUM[group];
    return [[ZXDataCharacter alloc] initWithValue:vOdd * tEven + vEven + gSum checksumPortion:checksumPortion];
  } else {
    if ((evenSum & 0x01) != 0 || evenSum > 10 || evenSum < 4) {
      return nil;
    }
    int group = (10 - evenSum) / 2;
    int oddWidest = INSIDE_ODD_WIDEST[group];
    int evenWidest = 9 - oddWidest;
    int vOdd = [ZXRSSUtils rssValue:self.oddCounts widthsLen:self.oddCountsLen maxWidth:oddWidest noNarrow:YES];
    int vEven = [ZXRSSUtils rssValue:self.evenCounts widthsLen:self.evenCountsLen maxWidth:evenWidest noNarrow:NO];
    int tOdd = INSIDE_ODD_TOTAL_SUBSET[group];
    int gSum = INSIDE_GSUM[group];
    return [[ZXDataCharacter alloc] initWithValue:vEven * tOdd + vOdd + gSum checksumPortion:checksumPortion];
  }
}

- (NSArray *)findFinderPattern:(ZXBitArray *)row rowOffset:(int)rowOffset rightFinderPattern:(BOOL)rightFinderPattern {
  int countersLen = self.decodeFinderCountersLen;
  int *counters = self.decodeFinderCounters;
  counters[0] = 0;
  counters[1] = 0;
  counters[2] = 0;
  counters[3] = 0;

  int width = row.size;
  BOOL isWhite = NO;
  while (rowOffset < width) {
    isWhite = ![row get:rowOffset];
    if (rightFinderPattern == isWhite) {
      break;
    }
    rowOffset++;
  }

  int counterPosition = 0;
  int patternStart = rowOffset;
  for (int x = rowOffset; x < width; x++) {
    if ([row get:x] ^ isWhite) {
      counters[counterPosition]++;
    } else {
      if (counterPosition == 3) {
        if ([ZXAbstractRSSReader isFinderPattern:counters countersLen:countersLen]) {
          return @[@(patternStart), @(x)];
        }
        patternStart += counters[0] + counters[1];
        counters[0] = counters[2];
        counters[1] = counters[3];
        counters[2] = 0;
        counters[3] = 0;
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

- (ZXRSSFinderPattern *)parseFoundFinderPattern:(ZXBitArray *)row rowNumber:(int)rowNumber right:(BOOL)right startEnd:(NSArray *)startEnd {
  BOOL firstIsBlack = [row get:[startEnd[0] intValue]];
  int firstElementStart = [startEnd[0] intValue] - 1;

  while (firstElementStart >= 0 && firstIsBlack ^ [row get:firstElementStart]) {
    firstElementStart--;
  }

  firstElementStart++;
  int firstCounter = [startEnd[0] intValue] - firstElementStart;

  int countersLen = self.decodeFinderCountersLen;
  int *counters = self.decodeFinderCounters;
  for (int i = countersLen - 1; i > 0; i--) {
    counters[i] = counters[i-1];
  }
  counters[0] = firstCounter;
  int value = [ZXAbstractRSSReader parseFinderValue:counters countersSize:countersLen finderPatternType:RSS_PATTERNS_RSS14_PATTERNS];
  if (value == -1) {
    return nil;
  }
  int start = firstElementStart;
  int end = [startEnd[1] intValue];
  if (right) {
    start = [row size] - 1 - start;
    end = [row size] - 1 - end;
  }
  return [[ZXRSSFinderPattern alloc] initWithValue:value
                                           startEnd:[@[@(firstElementStart), startEnd[1]] mutableCopy]
                                              start:start
                                                end:end
                                          rowNumber:rowNumber];
}

- (BOOL)adjustOddEvenCounts:(BOOL)outsideChar numModules:(int)numModules {
  int oddSum = [ZXAbstractRSSReader count:self.oddCounts arrayLen:self.oddCountsLen];
  int evenSum = [ZXAbstractRSSReader count:self.evenCounts arrayLen:self.evenCountsLen];
  int mismatch = oddSum + evenSum - numModules;
  BOOL oddParityBad = (oddSum & 0x01) == (outsideChar ? 1 : 0);
  BOOL evenParityBad = (evenSum & 0x01) == 1;

  BOOL incrementOdd = NO;
  BOOL decrementOdd = NO;
  BOOL incrementEven = NO;
  BOOL decrementEven = NO;

  if (outsideChar) {
    if (oddSum > 12) {
      decrementOdd = YES;
    } else if (oddSum < 4) {
      incrementOdd = YES;
    }
    if (evenSum > 12) {
      decrementEven = YES;
    } else if (evenSum < 4) {
      incrementEven = YES;
    }
  } else {
    if (oddSum > 11) {
      decrementOdd = YES;
    } else if (oddSum < 5) {
      incrementOdd = YES;
    }
    if (evenSum > 10) {
      decrementEven = YES;
    } else if (evenSum < 4) {
      incrementEven = YES;
    }
  }

  if (mismatch == 1) {
    if (oddParityBad) {
      if (evenParityBad) {
        return NO;
      }
      decrementOdd = YES;
    } else {
      if (!evenParityBad) {
        return NO;
      }
      decrementEven = YES;
    }
  } else if (mismatch == -1) {
    if (oddParityBad) {
      if (evenParityBad) {
        return NO;
      }
      incrementOdd = YES;
    } else {
      if (!evenParityBad) {
        return NO;
      }
      incrementEven = YES;
    }
  } else if (mismatch == 0) {
    if (oddParityBad) {
      if (!evenParityBad) {
        return NO;
      }
      if (oddSum < evenSum) {
        incrementOdd = YES;
        decrementEven = YES;
      } else {
        decrementOdd = YES;
        incrementEven = YES;
      }
    } else {
      if (evenParityBad) {
        return NO;
      }
    }
  } else {
    return NO;
  }
  if (incrementOdd) {
    if (decrementOdd) {
      return NO;
    }
    [ZXAbstractRSSReader increment:self.oddCounts arrayLen:self.oddCountsLen errors:self.oddRoundingErrors];
  }
  if (decrementOdd) {
    [ZXAbstractRSSReader decrement:self.oddCounts arrayLen:self.oddCountsLen errors:self.oddRoundingErrors];
  }
  if (incrementEven) {
    if (decrementEven) {
      return NO;
    }
    [ZXAbstractRSSReader increment:self.evenCounts arrayLen:self.evenCountsLen errors:self.oddRoundingErrors];
  }
  if (decrementEven) {
    [ZXAbstractRSSReader decrement:self.evenCounts arrayLen:self.evenCountsLen errors:self.evenRoundingErrors];
  }
  return YES;
}

@end
