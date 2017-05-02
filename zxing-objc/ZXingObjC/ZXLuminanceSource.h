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
 * The purpose of this class hierarchy is to abstract different bitmap implementations across
 * platforms into a standard interface for requesting greyscale luminance values. The interface
 * only provides immutable methods; therefore crop and rotation create copies. This is to ensure
 * that one Reader does not modify the original luminance source and leave it in an unknown state
 * for other Readers in the chain.
 */

@interface ZXLuminanceSource : NSObject

@property (nonatomic, assign, readonly) int width;
@property (nonatomic, assign, readonly) int height;
@property (nonatomic, assign, readonly) BOOL cropSupported;
@property (nonatomic, assign, readonly) BOOL rotateSupported;

- (id)initWithWidth:(int)width height:(int)height;
- (int8_t *)row:(int)y;
- (int8_t *)matrix;
- (ZXLuminanceSource *)crop:(int)left top:(int)top width:(int)width height:(int)height;
- (ZXLuminanceSource *)invert;
- (ZXLuminanceSource *)rotateCounterClockwise;
- (ZXLuminanceSource *)rotateCounterClockwise45;

@end
