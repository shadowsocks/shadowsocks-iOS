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
 * See ISO 18004:2006, 6.5.1. This enum encapsulates the four error correction levels
 * defined by the QR code standard.
 */

@interface ZXErrorCorrectionLevel : NSObject

@property (nonatomic, assign, readonly) int bits;
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, assign, readonly) int ordinal;

- (id)initWithOrdinal:(int)anOrdinal bits:(int)bits name:(NSString *)name;
+ (ZXErrorCorrectionLevel *)forBits:(int)bits;

/**
 * L = ~7% correction
 */
+ (ZXErrorCorrectionLevel *)errorCorrectionLevelL;

/**
 * M = ~15% correction
 */
+ (ZXErrorCorrectionLevel *)errorCorrectionLevelM;

/**
 * Q = ~25% correction
 */
+ (ZXErrorCorrectionLevel *)errorCorrectionLevelQ;

/**
 * H = ~30% correction
 */
+ (ZXErrorCorrectionLevel *)errorCorrectionLevelH;

@end
