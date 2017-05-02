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
 * Encapsulates logic that can detect a PDF417 Code in an image, even if the
 * PDF417 Code is rotated or skewed, or partially obscured.
 */

@class ZXBinaryBitmap, ZXBitArray, ZXBitMatrix, ZXDecodeHints, ZXPDF417DetectorResult;

@interface ZXPDF417Detector : NSObject

+ (ZXPDF417DetectorResult *)detect:(ZXBinaryBitmap *)image hints:(ZXDecodeHints *)hints multiple:(BOOL)multiple error:(NSError **)error;
+ (void)rotate180:(ZXBitMatrix *)bitMatrix;
+ (ZXBitArray *)mirror:(ZXBitArray *)input result:(ZXBitArray *)result;

@end
