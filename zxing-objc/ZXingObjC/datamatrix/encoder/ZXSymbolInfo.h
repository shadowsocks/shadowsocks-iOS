/*
 * Copyright 2013 ZXing authors
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

/**
 * Symbol info table for DataMatrix.
 */

@class ZXDimension, ZXSymbolShapeHint;

@interface ZXSymbolInfo : NSObject

@property (nonatomic, assign) BOOL rectangular;
@property (nonatomic, assign) int errorCodewords;
@property (nonatomic, assign) int dataCapacity;
@property (nonatomic, assign) int dataRegions;
@property (nonatomic, assign) int matrixWidth;
@property (nonatomic, assign) int matrixHeight;
@property (nonatomic, assign) int rsBlockData;
@property (nonatomic, assign) int rsBlockError;

/**
 * Overrides the symbol info set used by this class. Used for testing purposes.
 */
+ (void)overrideSymbolSet:(NSArray *)override;
+ (NSArray *)prodSymbols;
- (id)initWithRectangular:(BOOL)rectangular dataCapacity:(int)dataCapacity errorCodewords:(int)errorCodewords
              matrixWidth:(int)matrixWidth matrixHeight:(int)matrixHeight dataRegions:(int)dataRegions;
- (id)initWithRectangular:(BOOL)rectangular dataCapacity:(int)dataCapacity errorCodewords:(int)errorCodewords
              matrixWidth:(int)matrixWidth matrixHeight:(int)matrixHeight dataRegions:(int)dataRegions
              rsBlockData:(int)rsBlockData rsBlockError:(int)rsBlockError;
+ (ZXSymbolInfo *)lookup:(int)dataCodewords;
+ (ZXSymbolInfo *)lookup:(int)dataCodewords shape:(ZXSymbolShapeHint *)shape;
+ (ZXSymbolInfo *)lookup:(int)dataCodewords allowRectangular:(BOOL)allowRectangular fail:(BOOL)fail;
+ (ZXSymbolInfo *)lookup:(int)dataCodewords shape:(ZXSymbolShapeHint *)shape fail:(BOOL)fail;
+ (ZXSymbolInfo *)lookup:(int)dataCodewords shape:(ZXSymbolShapeHint *)shape minSize:(ZXDimension *)minSize
                 maxSize:(ZXDimension *)maxSize fail:(BOOL)fail;
- (int)horizontalDataRegions;
- (int)verticalDataRegions;
- (int)symbolDataWidth;
- (int)symbolDataHeight;
- (int)symbolWidth;
- (int)symbolHeight;
- (int)codewordCount;
- (int)interleavedBlockCount;
- (int)dataLengthForInterleavedBlock:(int)index;
- (int)errorLengthForInterleavedBlock:(int)index;

@end
