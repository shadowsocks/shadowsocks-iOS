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

#import "ZXResultPoint.h"

/**
 * Encapsulates an alignment pattern, which are the smaller square patterns found in
 * all but the simplest QR Codes.
 */

@interface ZXAlignmentPattern : ZXResultPoint

- (id)initWithPosX:(float)posX posY:(float)posY estimatedModuleSize:(float)estimatedModuleSize;
- (BOOL)aboutEquals:(float)moduleSize i:(float)i j:(float)j;
- (ZXAlignmentPattern *)combineEstimateI:(float)i j:(float)j newModuleSize:(float)newModuleSize;

@end
