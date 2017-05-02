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
 * Encapsulates logic that can detect a QR Code in an image, even if the QR Code
 * is rotated or skewed, or partially obscured.
 */

@class ZXAlignmentPattern, ZXBitMatrix, ZXDecodeHints, ZXDetectorResult, ZXFinderPatternInfo, ZXPerspectiveTransform, ZXResultPoint;
@protocol ZXResultPointCallback;

@interface ZXQRCodeDetector : NSObject

@property (nonatomic, strong, readonly) ZXBitMatrix *image;
@property (nonatomic, weak, readonly) id <ZXResultPointCallback> resultPointCallback;

- (id)initWithImage:(ZXBitMatrix *)image;
- (ZXDetectorResult *)detectWithError:(NSError **)error;
- (ZXDetectorResult *)detect:(ZXDecodeHints *)hints error:(NSError **)error;
- (ZXDetectorResult *)processFinderPatternInfo:(ZXFinderPatternInfo *)info error:(NSError **)error;
+ (int)computeDimension:(ZXResultPoint *)topLeft topRight:(ZXResultPoint *)topRight bottomLeft:(ZXResultPoint *)bottomLeft moduleSize:(float)moduleSize error:(NSError **)error;
- (float)calculateModuleSize:(ZXResultPoint *)topLeft topRight:(ZXResultPoint *)topRight bottomLeft:(ZXResultPoint *)bottomLeft;
- (ZXAlignmentPattern *)findAlignmentInRegion:(float)overallEstModuleSize estAlignmentX:(int)estAlignmentX estAlignmentY:(int)estAlignmentY allowanceFactor:(float)allowanceFactor error:(NSError **)error;

@end
