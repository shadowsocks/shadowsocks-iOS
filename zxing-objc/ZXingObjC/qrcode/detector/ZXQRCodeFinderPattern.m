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

#import "ZXQRCodeFinderPattern.h"

@interface ZXQRCodeFinderPattern ()

@property (nonatomic, assign) int count;

@end

@implementation ZXQRCodeFinderPattern

- (id)initWithPosX:(float)posX posY:(float)posY estimatedModuleSize:(float)estimatedModuleSize {
  return [self initWithPosX:posX posY:posY estimatedModuleSize:estimatedModuleSize count:1];
}

- (id)initWithPosX:(float)posX posY:(float)posY estimatedModuleSize:(float)estimatedModuleSize count:(int)count {
  if (self = [super initWithX:posX y:posY]) {
    _estimatedModuleSize = estimatedModuleSize;
    _count = count;
  }

  return self;
}

- (void)incrementCount {
  self.count++;
}

/**
 * Determines if this finder pattern "about equals" a finder pattern at the stated
 * position and size -- meaning, it is at nearly the same center with nearly the same size.
 */
- (BOOL)aboutEquals:(float)moduleSize i:(float)i j:(float)j {
  if (fabsf(i - [self y]) <= moduleSize && fabsf(j - [self x]) <= moduleSize) {
    float moduleSizeDiff = fabsf(moduleSize - self.estimatedModuleSize);
    return moduleSizeDiff <= 1.0f || moduleSizeDiff <= self.estimatedModuleSize;
  }
  return NO;
}

/**
 * Combines this object's current estimate of a finder pattern position and module size
 * with a new estimate. It returns a new ZXQRCodeFinderPattern containing a weighted average
 * based on count.
 */
- (ZXQRCodeFinderPattern *)combineEstimateI:(float)i j:(float)j newModuleSize:(float)newModuleSize {
  int combinedCount = self.count + 1;
  float combinedX = (self.count * self.x + j) / combinedCount;
  float combinedY = (self.count * self.y + i) / combinedCount;
  float combinedModuleSize = (self.count * self.estimatedModuleSize + newModuleSize) / combinedCount;
  return [[ZXQRCodeFinderPattern alloc] initWithPosX:combinedX
                                                 posY:combinedY
                                  estimatedModuleSize:combinedModuleSize
                                                count:combinedCount];
}

@end
