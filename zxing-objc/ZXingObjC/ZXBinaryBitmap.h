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
 * This class is the core bitmap class used by ZXing to represent 1 bit data. Reader objects
 * accept a BinaryBitmap and attempt to decode it.
 */

@class ZXBinarizer, ZXBitArray, ZXBitMatrix;

@interface ZXBinaryBitmap : NSObject

@property (nonatomic, readonly) int width;
@property (nonatomic, readonly) int height;
@property (nonatomic, readonly) BOOL cropSupported;
@property (nonatomic, readonly) BOOL rotateSupported;

- (id)initWithBinarizer:(ZXBinarizer *)binarizer;
+ (id)binaryBitmapWithBinarizer:(ZXBinarizer *)binarizer;
- (ZXBitArray *)blackRow:(int)y row:(ZXBitArray *)row error:(NSError **)error;
- (ZXBitMatrix *)blackMatrixWithError:(NSError **)error;
- (ZXBinaryBitmap *)crop:(int)left top:(int)top width:(int)width height:(int)height;
- (ZXBinaryBitmap *)rotateCounterClockwise;
- (ZXBinaryBitmap *)rotateCounterClockwise45;

@end
