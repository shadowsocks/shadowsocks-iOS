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

#import "ZXAbstractRSSReader.h"

@class ZXDataCharacter, ZXExpandedPair, ZXResult, ZXRSSFinderPattern;

@interface ZXRSSExpandedReader : ZXAbstractRSSReader

@property (nonatomic, strong, readonly) NSMutableArray *rows;

- (ZXDataCharacter *)decodeDataCharacter:(ZXBitArray *)row pattern:(ZXRSSFinderPattern *)pattern isOddPattern:(BOOL)isOddPattern leftChar:(BOOL)leftChar;

// for tests
- (NSMutableArray *)decodeRow2pairs:(int)rowNumber row:(ZXBitArray *)row;
- (ZXResult *)constructResult:(NSMutableArray *)pairs error:(NSError **)error;
- (ZXExpandedPair *)retrieveNextPair:(ZXBitArray *)row previousPairs:(NSMutableArray *)previousPairs rowNumber:(int)rowNumber;

@end
