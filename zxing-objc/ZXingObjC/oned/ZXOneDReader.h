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

#import "ZXReader.h"

/**
 * Encapsulates functionality and implementation that is common to all families
 * of one-dimensional barcodes.
 */

extern int const INTEGER_MATH_SHIFT;
extern int const PATTERN_MATCH_RESULT_SCALE_FACTOR;

@class ZXBitArray, ZXDecodeHints, ZXResult;

@interface ZXOneDReader : NSObject <ZXReader>

+ (BOOL)recordPattern:(ZXBitArray *)row start:(int)start counters:(int[])counters countersSize:(int)countersSize;
+ (BOOL)recordPatternInReverse:(ZXBitArray *)row start:(int)start counters:(int[])counters countersSize:(int)countersSize;
+ (int)patternMatchVariance:(int[])counters countersSize:(int)countersSize pattern:(int[])pattern maxIndividualVariance:(int)maxIndividualVariance;
- (ZXResult *)decodeRow:(int)rowNumber row:(ZXBitArray *)row hints:(ZXDecodeHints *)hints error:(NSError **)error;

@end
