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

#import "ZXAlignmentPattern.h"
#import "ZXAlignmentPatternFinder.h"
#import "ZXBitMatrix.h"
#import "ZXErrors.h"
#import "ZXResultPointCallback.h"

@interface ZXAlignmentPatternFinder ()

@property (nonatomic, strong) ZXBitMatrix *image;
@property (nonatomic, strong) NSMutableArray *possibleCenters;
@property (nonatomic, assign) int startX;
@property (nonatomic, assign) int startY;
@property (nonatomic, assign) int width;
@property (nonatomic, assign) int height;
@property (nonatomic, assign) float moduleSize;
@property (nonatomic, assign) int *crossCheckStateCount;
@property (nonatomic, weak) id <ZXResultPointCallback> resultPointCallback;

@end

@implementation ZXAlignmentPatternFinder

/**
 * Creates a finder that will look in a portion of the whole image.
 */
- (id)initWithImage:(ZXBitMatrix *)image startX:(int)startX startY:(int)startY width:(int)width height:(int)height moduleSize:(float)moduleSize resultPointCallback:(id<ZXResultPointCallback>)resultPointCallback {
  if (self = [super init]) {
    _image = image;
    _possibleCenters = [NSMutableArray arrayWithCapacity:5];
    _startX = startX;
    _startY = startY;
    _width = width;
    _height = height;
    _moduleSize = moduleSize;
    _crossCheckStateCount = (int *)malloc(3 * sizeof(int));
    memset(_crossCheckStateCount, 0, 3 * sizeof(int));
    _resultPointCallback = resultPointCallback;
  }

  return self;
}

- (void)dealloc {
  if (_crossCheckStateCount != NULL) {
    free(_crossCheckStateCount);
    _crossCheckStateCount = NULL;
  }
}

/**
 * This method attempts to find the bottom-right alignment pattern in the image. It is a bit messy since
 * it's pretty performance-critical and so is written to be fast foremost.
 */
- (ZXAlignmentPattern *)findWithError:(NSError **)error {
  int maxJ = self.startX + self.width;
  int middleI = self.startY + (self.height >> 1);
  int stateCount[3];

  for (int iGen = 0; iGen < self.height; iGen++) {
    int i = middleI + ((iGen & 0x01) == 0 ? (iGen + 1) >> 1 : -((iGen + 1) >> 1));
    stateCount[0] = 0;
    stateCount[1] = 0;
    stateCount[2] = 0;
    int j = self.startX;

    while (j < maxJ && ![self.image getX:j y:i]) {
      j++;
    }

    int currentState = 0;

    while (j < maxJ) {
      if ([self.image getX:j y:i]) {
        if (currentState == 1) {
          stateCount[currentState]++;
        } else {
          if (currentState == 2) {
            if ([self foundPatternCross:stateCount]) {
              ZXAlignmentPattern *confirmed = [self handlePossibleCenter:stateCount i:i j:j];
              if (confirmed != nil) {
                return confirmed;
              }
            }
            stateCount[0] = stateCount[2];
            stateCount[1] = 1;
            stateCount[2] = 0;
            currentState = 1;
          } else {
            stateCount[++currentState]++;
          }
        }
      } else {
        if (currentState == 1) {
          currentState++;
        }
        stateCount[currentState]++;
      }
      j++;
    }

    if ([self foundPatternCross:stateCount]) {
      ZXAlignmentPattern *confirmed = [self handlePossibleCenter:stateCount i:i j:maxJ];
      if (confirmed != nil) {
        return confirmed;
      }
    }
  }

  if ([self.possibleCenters count] > 0) {
    return self.possibleCenters[0];
  }
  if (error) *error = NotFoundErrorInstance();
  return nil;
}

/**
 * Given a count of black/white/black pixels just seen and an end position,
 * figures the location of the center of this black/white/black run.
 */
- (float)centerFromEnd:(int *)stateCount end:(int)end {
  return (float)(end - stateCount[2]) - stateCount[1] / 2.0f;
}

- (BOOL)foundPatternCross:(int *)stateCount {
  float maxVariance = self.moduleSize / 2.0f;

  for (int i = 0; i < 3; i++) {
    if (fabsf(self.moduleSize - stateCount[i]) >= maxVariance) {
      return NO;
    }
  }

  return YES;
}

/**
 * After a horizontal scan finds a potential alignment pattern, this method
 * "cross-checks" by scanning down vertically through the center of the possible
 * alignment pattern to see if the same proportion is detected.
 */
- (float)crossCheckVertical:(int)startI centerJ:(int)centerJ maxCount:(int)maxCount originalStateCountTotal:(int)originalStateCountTotal {
  int maxI = self.image.height;
  int stateCount[3] = {0, 0, 0};
  int i = startI;

  while (i >= 0 && [self.image getX:centerJ y:i] && stateCount[1] <= maxCount) {
    stateCount[1]++;
    i--;
  }

  if (i < 0 || stateCount[1] > maxCount) {
    return NAN;
  }

  while (i >= 0 && ![self.image getX:centerJ y:i] && stateCount[0] <= maxCount) {
    stateCount[0]++;
    i--;
  }

  if (stateCount[0] > maxCount) {
    return NAN;
  }
  i = startI + 1;

  while (i < maxI && [self.image getX:centerJ y:i] && stateCount[1] <= maxCount) {
    stateCount[1]++;
    i++;
  }

  if (i == maxI || stateCount[1] > maxCount) {
    return NAN;
  }

  while (i < maxI && ![self.image getX:centerJ y:i] && stateCount[2] <= maxCount) {
    stateCount[2]++;
    i++;
  }

  if (stateCount[2] > maxCount) {
    return NAN;
  }
  int stateCountTotal = stateCount[0] + stateCount[1] + stateCount[2];
  if (5 * abs(stateCountTotal - originalStateCountTotal) >= 2 * originalStateCountTotal) {
    return NAN;
  }
  return [self foundPatternCross:stateCount] ? [self centerFromEnd:stateCount end:i] : NAN;
}

/**
 * This is called when a horizontal scan finds a possible alignment pattern. It will
 * cross check with a vertical scan, and if successful, will see if this pattern had been
 * found on a previous horizontal scan. If so, we consider it confirmed and conclude we have
 * found the alignment pattern.
 */
- (ZXAlignmentPattern *)handlePossibleCenter:(int *)stateCount i:(int)i j:(int)j {
  int stateCountTotal = stateCount[0] + stateCount[1] + stateCount[2];
  float centerJ = [self centerFromEnd:stateCount end:j];
  float centerI = [self crossCheckVertical:i centerJ:(int)centerJ maxCount:2 * stateCount[1] originalStateCountTotal:stateCountTotal];
  if (!isnan(centerI)) {
    float estimatedModuleSize = (float)(stateCount[0] + stateCount[1] + stateCount[2]) / 3.0f;
    int max = (int)self.possibleCenters.count;

    for (int index = 0; index < max; index++) {
      ZXAlignmentPattern *center = self.possibleCenters[index];
      // Look for about the same center and module size:
      if ([center aboutEquals:estimatedModuleSize i:centerI j:centerJ]) {
        return [center combineEstimateI:centerI j:centerJ newModuleSize:estimatedModuleSize];
      }
    }
    // Hadn't found this before; save it
    ZXResultPoint *point = [[ZXAlignmentPattern alloc] initWithPosX:centerJ posY:centerI estimatedModuleSize:estimatedModuleSize];
    [self.possibleCenters addObject:point];
    if (self.resultPointCallback != nil) {
      [self.resultPointCallback foundPossibleResultPoint:point];
    }
  }
  return nil;
}

@end
