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

/**
 * Encapsulates a block of data within a QR Code. QR Codes may split their data into
 * multiple blocks, each of which is a unit of data and error-correction codewords. Each
 * is represented by an instance of this class.
 */

@class ZXErrorCorrectionLevel, ZXQRCodeVersion;

@interface ZXQRCodeDataBlock : NSObject

@property (nonatomic, strong, readonly) NSMutableArray *codewords;
@property (nonatomic, assign, readonly) int numDataCodewords;

- (id)initWithNumDataCodewords:(int)numDataCodewords codewords:(NSMutableArray *)codewords;
+ (NSArray *)dataBlocks:(NSArray *)rawCodewords version:(ZXQRCodeVersion *)version ecLevel:(ZXErrorCorrectionLevel *)ecLevel;

@end
