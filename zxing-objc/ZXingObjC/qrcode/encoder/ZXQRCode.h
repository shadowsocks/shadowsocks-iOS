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

extern int const NUM_MASK_PATTERNS;

@class ZXByteMatrix, ZXErrorCorrectionLevel, ZXMode, ZXQRCodeVersion;

@interface ZXQRCode : NSObject

@property (nonatomic, strong) ZXMode *mode;
@property (nonatomic, strong) ZXErrorCorrectionLevel *ecLevel;
@property (nonatomic, strong) ZXQRCodeVersion *version;
@property (nonatomic, assign) int maskPattern;
@property (nonatomic, strong) ZXByteMatrix *matrix;

+ (BOOL)isValidMaskPattern:(int)maskPattern;

@end
