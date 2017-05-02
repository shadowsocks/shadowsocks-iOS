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

@interface ZXAlignmentPattern ()

@property (nonatomic, assign) float estimatedModuleSize;

@end

@implementation ZXAlignmentPattern

- (id)initWithPosX:(float)posX posY:(float)posY estimatedModuleSize:(float)estimatedModuleSize {
  if (self = [super initWithX:posX y:posY]) {
    _estimatedModuleSize = estimatedModuleSize;
  }

  return self;
}

/**
 * Determines if this alignment pattern "about equals" an alignment pattern at the stated
 * position and size -- meaning, it is at nearly the same center with nearly the same size.
 */
- (BOOL)aboutEquals:(float)moduleSize i:(float)i j:(float)j {
  if (fabsf(i - self.y) <= moduleSize && fabsf(j - self.x) <= moduleSize) {
    float moduleSizeDiff = fabsf(moduleSize - self.estimatedModuleSize);
    return moduleSizeDiff <= 1.0f || moduleSizeDiff <= self.estimatedModuleSize;
  }

  return NO;
}

/**
 * Combines this object's current estimate of a finder pattern position and module size
 * with a new estimate. It returns a new FinderPattern containing an average of the two.
 */
- (ZXAlignmentPattern *)combineEstimateI:(float)i j:(float)j newModuleSize:(float)newModuleSize {
  float combinedX = (self.x + j) / 2.0f;
  float combinedY = (self.y + i) / 2.0f;
  float combinedModuleSize = (self.estimatedModuleSize + newModuleSize) / 2.0f;
  return [[ZXAlignmentPattern alloc] initWithPosX:combinedX posY:combinedY estimatedModuleSize:combinedModuleSize];
}

@end
