/*
 * Copyright 2006 Jeremias Maerki in part, and ZXing Authors in part
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "ZXCompaction.h"

@class ZXBarcodeMatrix;

/*
 * This file has been modified from its original form in Barcode4J.
 */
@interface ZXPDF417 : NSObject

@property (nonatomic, strong, readonly) ZXBarcodeMatrix *barcodeMatrix;
@property (nonatomic, assign) BOOL compact;
@property (nonatomic, assign) ZXCompaction compaction;

- (id)initWithCompact:(BOOL)compact;
- (BOOL)generateBarcodeLogic:(NSString *)msg errorCorrectionLevel:(int)errorCorrectionLevel error:(NSError **)error;
- (BOOL)determineDimensions:(int *)dimension sourceCodeWords:(int)sourceCodeWords errorCorrectionCodeWords:(int)errorCorrectionCodeWords error:(NSError **)error;
- (void)setDimensionsWithMaxCols:(int)maxCols minCols:(int)minCols maxRows:(int)maxRows minRows:(int)minRows;

@end
