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

#if TARGET_OS_EMBEDDED || TARGET_IPHONE_SIMULATOR
#include <ImageIO/ImageIO.h>
#else
#import <QuartzCore/QuartzCore.h>
#endif

#import "ZXBitArray.h"
#import "ZXBitMatrix.h"
#import "ZXLuminanceSource.h"

/**
 * This class hierarchy provides a set of methods to convert luminance data to 1 bit data.
 * It allows the algorithm to vary polymorphically, for example allowing a very expensive
 * thresholding technique for servers and a fast one for mobile. It also permits the implementation
 * to vary, e.g. a JNI version for Android and a Java fallback version for other platforms.
 */

@interface ZXBinarizer : NSObject

@property (nonatomic, strong, readonly) ZXLuminanceSource *luminanceSource;
@property (nonatomic, assign, readonly) int width;
@property (nonatomic, assign, readonly) int height;

- (id)initWithSource:(ZXLuminanceSource *)source;
+ (id)binarizerWithSource:(ZXLuminanceSource *)source;
- (ZXBitMatrix *)blackMatrixWithError:(NSError **)error;
- (ZXBitArray *)blackRow:(int)y row:(ZXBitArray *)row error:(NSError **)error;
- (ZXBinarizer *)createBinarizer:(ZXLuminanceSource *)source;
- (CGImageRef)createImage CF_RETURNS_RETAINED;

@end
