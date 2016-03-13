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
#import "ZXDecodeHints.h"
#import "ZXErrors.h"
#import "ZXFinderPatternFinder.h"
#import "ZXFinderPatternInfo.h"
#import "ZXOneDReader.h"
#import "ZXQRCodeFinderPattern.h"
#import "ZXResultPoint.h"
#import "ZXResultPointCallback.h"

int const CENTER_QUORUM = 2;
int const FINDER_PATTERN_MIN_SKIP = 3;
int const FINDER_PATTERN_MAX_MODULES = 57;

@interface ZXFinderPatternFinder ()

NSInteger centerCompare(id center1, id center2, void *context);
NSInteger furthestFromAverageCompare(id center1, id center2, void *context);

@property (nonatomic, assign) BOOL hasSkipped;
@property (nonatomic, weak) id <ZXResultPointCallback> resultPointCallback;
@property (nonatomic, strong) NSMutableArray *possibleCenters;

@end

@implementation ZXFinderPatternFinder

/**
 * Creates a finder that will search the image for three finder patterns.
 */
- (id)initWithImage:(ZXBitMatrix *)image {
  return [self initWithImage:image resultPointCallback:nil];
}

- (id)initWithImage:(ZXBitMatrix *)image resultPointCallback:(id<ZXResultPointCallback>)resultPointCallback {
  if (self = [super init]) {
    _image = image;
    _possibleCenters = [NSMutableArray array];
    _resultPointCallback = resultPointCallback;
  }

  return self;
}

- (ZXFinderPatternInfo *)find:(ZXDecodeHints *)hints error:(NSError **)error {
  BOOL tryHarder = hints != nil && hints.tryHarder;
  int maxI = self.image.height;
  int maxJ = self.image.width;
  int iSkip = (3 * maxI) / (4 * FINDER_PATTERN_MAX_MODULES);
  if (iSkip < FINDER_PATTERN_MIN_SKIP || tryHarder) {
    iSkip = FINDER_PATTERN_MIN_SKIP;
  }

  BOOL done = NO;
  int stateCount[5];
  for (int i = iSkip - 1; i < maxI && !done; i += iSkip) {
    stateCount[0] = 0;
    stateCount[1] = 0;
    stateCount[2] = 0;
    stateCount[3] = 0;
    stateCount[4] = 0;
    int currentState = 0;

    for (int j = 0; j < maxJ; j++) {
      if ([self.image getX:j y:i]) {
        if ((currentState & 1) == 1) {
          currentState++;
        }
        stateCount[currentState]++;
      } else {
        if ((currentState & 1) == 0) {
          if (currentState == 4) {
            if ([ZXFinderPatternFinder foundPatternCross:stateCount]) {
              BOOL confirmed = [self handlePossibleCenter:stateCount i:i j:j];
              if (confirmed) {
                iSkip = 2;
                if (self.hasSkipped) {
                  done = [self haveMultiplyConfirmedCenters];
                } else {
                  int rowSkip = [self findRowSkip];
                  if (rowSkip > stateCount[2]) {
                    i += rowSkip - stateCount[2] - iSkip;
                    j = maxJ - 1;
                  }
                }
              } else {
                stateCount[0] = stateCount[2];
                stateCount[1] = stateCount[3];
                stateCount[2] = stateCount[4];
                stateCount[3] = 1;
                stateCount[4] = 0;
                currentState = 3;
                continue;
              }
              currentState = 0;
              stateCount[0] = 0;
              stateCount[1] = 0;
              stateCount[2] = 0;
              stateCount[3] = 0;
              stateCount[4] = 0;
            } else {
              stateCount[0] = stateCount[2];
              stateCount[1] = stateCount[3];
              stateCount[2] = stateCount[4];
              stateCount[3] = 1;
              stateCount[4] = 0;
              currentState = 3;
            }
          } else {
            stateCount[++currentState]++;
          }
        } else {
          stateCount[currentState]++;
        }
      }
    }

    if ([ZXFinderPatternFinder foundPatternCross:stateCount]) {
      BOOL confirmed = [self handlePossibleCenter:stateCount i:i j:maxJ];
      if (confirmed) {
        iSkip = stateCount[0];
        if (self.hasSkipped) {
          done = [self haveMultiplyConfirmedCenters];
        }
      }
    }
  }

  NSMutableArray *patternInfo = [self selectBestPatterns];
  if (!patternInfo) {
    if (error) *error = NotFoundErrorInstance();
    return nil;
  }
  [ZXResultPoint orderBestPatterns:patternInfo];
  return [[ZXFinderPatternInfo alloc] initWithPatternCenters:patternInfo];
}

/**
 * Given a count of black/white/black/white/black pixels just seen and an end position,
 * figures the location of the center of this run.
 */
- (float)centerFromEnd:(int *)stateCount end:(int)end {
  return (float)(end - stateCount[4] - stateCount[3]) - stateCount[2] / 2.0f;
}

+ (BOOL)foundPatternCross:(int[])stateCount {
  int totalModuleSize = 0;

  for (int i = 0; i < 5; i++) {
    int count = stateCount[i];
    if (count == 0) {
      return NO;
    }
    totalModuleSize += count;
  }

  if (totalModuleSize < 7) {
    return NO;
  }
  int moduleSize = (totalModuleSize << INTEGER_MATH_SHIFT) / 7;
  int maxVariance = moduleSize / 2;
  return abs(moduleSize - (stateCount[0] << INTEGER_MATH_SHIFT)) < maxVariance &&
    abs(moduleSize - (stateCount[1] << INTEGER_MATH_SHIFT)) < maxVariance &&
    abs(3 * moduleSize - (stateCount[2] << INTEGER_MATH_SHIFT)) < 3 * maxVariance &&
    abs(moduleSize - (stateCount[3] << INTEGER_MATH_SHIFT)) < maxVariance &&
    abs(moduleSize - (stateCount[4] << INTEGER_MATH_SHIFT)) < maxVariance;
}

/**
 * After a horizontal scan finds a potential finder pattern, this method
 * "cross-checks" by scanning down vertically through the center of the possible
 * finder pattern to see if the same proportion is detected.
 */
- (float)crossCheckVertical:(int)startI centerJ:(int)centerJ maxCount:(int)maxCount originalStateCountTotal:(int)originalStateCountTotal {
  int maxI = self.image.height;
  int stateCount[5] = {0, 0, 0, 0, 0};

  int i = startI;
  while (i >= 0 && [self.image getX:centerJ y:i]) {
    stateCount[2]++;
    i--;
  }
  if (i < 0) {
    return NAN;
  }
  while (i >= 0 && ![self.image getX:centerJ y:i] && stateCount[1] <= maxCount) {
    stateCount[1]++;
    i--;
  }
  if (i < 0 || stateCount[1] > maxCount) {
    return NAN;
  }
  while (i >= 0 && [self.image getX:centerJ y:i] && stateCount[0] <= maxCount) {
    stateCount[0]++;
    i--;
  }
  if (stateCount[0] > maxCount) {
    return NAN;
  }

  i = startI + 1;
  while (i < maxI && [self.image getX:centerJ y:i]) {
    stateCount[2]++;
    i++;
  }
  if (i == maxI) {
    return NAN;
  }
  while (i < maxI && ![self.image getX:centerJ y:i] && stateCount[3] < maxCount) {
    stateCount[3]++;
    i++;
  }
  if (i == maxI || stateCount[3] >= maxCount) {
    return NAN;
  }
  while (i < maxI && [self.image getX:centerJ y:i] && stateCount[4] < maxCount) {
    stateCount[4]++;
    i++;
  }
  if (stateCount[4] >= maxCount) {
    return NAN;
  }

  int stateCountTotal = stateCount[0] + stateCount[1] + stateCount[2] + stateCount[3] + stateCount[4];
  if (5 * abs(stateCountTotal - originalStateCountTotal) >= 2 * originalStateCountTotal) {
    return NAN;
  }
  return [ZXFinderPatternFinder foundPatternCross:stateCount] ? [self centerFromEnd:stateCount end:i] : NAN;
}

/**
 * Like crossCheckVertical, and in fact is basically identical,
 * except it reads horizontally instead of vertically. This is used to cross-cross
 * check a vertical cross check and locate the real center of the alignment pattern.
 */
- (float)crossCheckHorizontal:(int)startJ centerI:(int)centerI maxCount:(int)maxCount originalStateCountTotal:(int)originalStateCountTotal {
  int maxJ = self.image.width;
  int stateCount[5] = {0, 0, 0, 0, 0};

  int j = startJ;
  while (j >= 0 && [self.image getX:j y:centerI]) {
    stateCount[2]++;
    j--;
  }
  if (j < 0) {
    return NAN;
  }
  while (j >= 0 && ![self.image getX:j y:centerI] && stateCount[1] <= maxCount) {
    stateCount[1]++;
    j--;
  }
  if (j < 0 || stateCount[1] > maxCount) {
    return NAN;
  }
  while (j >= 0 && [self.image getX:j y:centerI] && stateCount[0] <= maxCount) {
    stateCount[0]++;
    j--;
  }
  if (stateCount[0] > maxCount) {
    return NAN;
  }

  j = startJ + 1;
  while (j < maxJ && [self.image getX:j y:centerI]) {
    stateCount[2]++;
    j++;
  }
  if (j == maxJ) {
    return NAN;
  }
  while (j < maxJ && ![self.image getX:j y:centerI] && stateCount[3] < maxCount) {
    stateCount[3]++;
    j++;
  }
  if (j == maxJ || stateCount[3] >= maxCount) {
    return NAN;
  }
  while (j < maxJ && [self.image getX:j y:centerI] && stateCount[4] < maxCount) {
    stateCount[4]++;
    j++;
  }
  if (stateCount[4] >= maxCount) {
    return NAN;
  }

  int stateCountTotal = stateCount[0] + stateCount[1] + stateCount[2] + stateCount[3] + stateCount[4];
  if (5 * abs(stateCountTotal - originalStateCountTotal) >= originalStateCountTotal) {
    return NAN;
  }

  return [ZXFinderPatternFinder foundPatternCross:stateCount] ? [self centerFromEnd:stateCount end:j] : NAN;
}


/**
 * This is called when a horizontal scan finds a possible alignment pattern. It will
 * cross check with a vertical scan, and if successful, will, ah, cross-cross-check
 * with another horizontal scan. This is needed primarily to locate the real horizontal
 * center of the pattern in cases of extreme skew.
 * 
 * If that succeeds the finder pattern location is added to a list that tracks
 * the number of times each location has been nearly-matched as a finder pattern.
 * Each additional find is more evidence that the location is in fact a finder
 * pattern center
 */
- (BOOL)handlePossibleCenter:(int *)stateCount i:(int)i j:(int)j {
  int stateCountTotal = stateCount[0] + stateCount[1] + stateCount[2] + stateCount[3] + stateCount[4];
  float centerJ = [self centerFromEnd:stateCount end:j];
  float centerI = [self crossCheckVertical:i centerJ:(int)centerJ maxCount:stateCount[2] originalStateCountTotal:stateCountTotal];
  if (!isnan(centerI)) {
    centerJ = [self crossCheckHorizontal:(int)centerJ centerI:(int)centerI maxCount:stateCount[2] originalStateCountTotal:stateCountTotal];
    if (!isnan(centerJ)) {
      float estimatedModuleSize = (float)stateCountTotal / 7.0f;
      BOOL found = NO;
      int max = (int)[self.possibleCenters count];
      for (int index = 0; index < max; index++) {
        ZXQRCodeFinderPattern *center = self.possibleCenters[index];
        if ([center aboutEquals:estimatedModuleSize i:centerI j:centerJ]) {
          self.possibleCenters[index] = [center combineEstimateI:centerI j:centerJ newModuleSize:estimatedModuleSize];
          found = YES;
          break;
        }
      }

      if (!found) {
        ZXResultPoint *point = [[ZXQRCodeFinderPattern alloc] initWithPosX:centerJ posY:centerI estimatedModuleSize:estimatedModuleSize];
        [self.possibleCenters addObject:point];
        if (self.resultPointCallback != nil) {
          [self.resultPointCallback foundPossibleResultPoint:point];
        }
      }
      return YES;
    }
  }
  return NO;
}


/**
 * @return number of rows we could safely skip during scanning, based on the first
 * two finder patterns that have been located. In some cases their position will
 * allow us to infer that the third pattern must lie below a certain point farther
 * down in the image.
 */
- (int) findRowSkip {
  int max = (int)[self.possibleCenters count];
  if (max <= 1) {
    return 0;
  }
  ZXQRCodeFinderPattern *firstConfirmedCenter = nil;
  for (int i = 0; i < max; i++) {
    ZXQRCodeFinderPattern *center = self.possibleCenters[i];
    if ([center count] >= CENTER_QUORUM) {
      if (firstConfirmedCenter == nil) {
        firstConfirmedCenter = center;
      } else {
        self.hasSkipped = YES;
        return (int)(fabsf([firstConfirmedCenter x] - [center x]) - fabsf([firstConfirmedCenter y] - [center y])) / 2;
      }
    }
  }
  return 0;
}


- (BOOL)haveMultiplyConfirmedCenters {
  int confirmedCount = 0;
  float totalModuleSize = 0.0f;
  int max = (int)[self.possibleCenters count];
  for (int i = 0; i < max; i++) {
    ZXQRCodeFinderPattern *pattern = self.possibleCenters[i];
    if ([pattern count] >= CENTER_QUORUM) {
      confirmedCount++;
      totalModuleSize += [pattern estimatedModuleSize];
    }
  }
  if (confirmedCount < 3) {
    return NO;
  }

  float average = totalModuleSize / (float)max;
  float totalDeviation = 0.0f;
  for (int i = 0; i < max; i++) {
    ZXQRCodeFinderPattern *pattern = self.possibleCenters[i];
    totalDeviation += fabsf([pattern estimatedModuleSize] - average);
  }
  return totalDeviation <= 0.05f * totalModuleSize;
}

/**
 * Orders by ZXFinderPattern count, descending.
 */
NSInteger centerCompare(id center1, id center2, void *context) {
  float average = [(__bridge NSNumber *)context floatValue];

  if ([((ZXQRCodeFinderPattern *)center2) count] == [((ZXQRCodeFinderPattern *)center1) count]) {
    float dA = fabsf([((ZXQRCodeFinderPattern *)center2) estimatedModuleSize] - average);
    float dB = fabsf([((ZXQRCodeFinderPattern *)center1) estimatedModuleSize] - average);
    return dA < dB ? 1 : dA == dB ? 0 : -1;
  } else {
    return [((ZXQRCodeFinderPattern *)center2) count] - [((ZXQRCodeFinderPattern *)center1) count];
  }
}

/**
 * Orders by furthest from average
 */
NSInteger furthestFromAverageCompare(id center1, id center2, void *context) {
  float average = [(__bridge NSNumber *)context floatValue];

  float dA = fabsf([((ZXQRCodeFinderPattern *)center2) estimatedModuleSize] - average);
  float dB = fabsf([((ZXQRCodeFinderPattern *)center1) estimatedModuleSize] - average);
  return dA < dB ? -1 : dA == dB ? 0 : 1;
}


/**
 * Returns the 3 best ZXFinderPatterns from our list of candidates. The "best" are
 * those that have been detected at least CENTER_QUORUM times, and whose module
 * size differs from the average among those patterns the least
 */
- (NSMutableArray *)selectBestPatterns {
  int startSize = (int)[self.possibleCenters count];
  if (startSize < 3) {
    return nil;
  }

  if (startSize > 3) {
    float totalModuleSize = 0.0f;
    float square = 0.0f;
    for (int i = 0; i < startSize; i++) {
      float size = [self.possibleCenters[i] estimatedModuleSize];
      totalModuleSize += size;
      square += size * size;
    }
    float average = totalModuleSize / (float)startSize;
    float stdDev = (float)sqrt(square / startSize - average * average);

    [self.possibleCenters sortUsingFunction: furthestFromAverageCompare context: (__bridge void *)@(average)];

    float limit = MAX(0.2f * average, stdDev);

    for (int i = 0; i < [self.possibleCenters count] && [self.possibleCenters count] > 3; i++) {
      ZXQRCodeFinderPattern *pattern = self.possibleCenters[i];
      if (fabsf([pattern estimatedModuleSize] - average) > limit) {
        [self.possibleCenters removeObjectAtIndex:i];
        i--;
      }
    }
  }

  if ([self.possibleCenters count] > 3) {
    float totalModuleSize = 0.0f;
    for (int i = 0; i < [self.possibleCenters count]; i++) {
      totalModuleSize += [self.possibleCenters[i] estimatedModuleSize];
    }

    float average = totalModuleSize / (float)[self.possibleCenters count];

    [self.possibleCenters sortUsingFunction:centerCompare context:(__bridge void *)(@(average))];

    self.possibleCenters = [[NSMutableArray alloc] initWithArray:[self.possibleCenters subarrayWithRange:NSMakeRange(0, 3)]];
  }

  return [@[self.possibleCenters[0], self.possibleCenters[1], self.possibleCenters[2]] mutableCopy];
}

@end
