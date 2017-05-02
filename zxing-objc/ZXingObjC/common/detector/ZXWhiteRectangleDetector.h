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
#import "ZXBitMatrix.h"

/**
 * Detects a candidate barcode-like rectangular region within an image. It
 * starts around the center of the image, increases the size of the candidate
 * region until it finds a white rectangular region. By keeping track of the
 * last black points it encountered, it determines the corners of the barcode.
 */

@interface ZXWhiteRectangleDetector : NSObject 

- (id)initWithImage:(ZXBitMatrix *)image error:(NSError **)error;
- (id)initWithImage:(ZXBitMatrix *)image initSize:(int)initSize x:(int)x y:(int)y error:(NSError **)error;
- (NSArray *)detectWithError:(NSError **)error;

@end
