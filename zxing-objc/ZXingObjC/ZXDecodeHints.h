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

#import "ZXBarcodeFormat.h"

@protocol ZXResultPointCallback;

/**
 * Encapsulates hints that a caller may pass to a barcode reader to help it
 * more quickly or accurately decode it. It is up to implementations to decide what,
 * if anything, to do with the information that is supplied.
 */
@interface ZXDecodeHints : NSObject <NSCopying>

+ (id)hints;

/**
 * Assume Code 39 codes employ a check digit. Maps to {@link Boolean}.
 */
@property (nonatomic, assign) BOOL assumeCode39CheckDigit;

/**
 * Assume the barcode is being processed as a GS1 barcode, and modify behavior as needed.
 * For example this affects FNC1 handling for Code 128 (aka GS1-128).
 */
@property (nonatomic, assign) BOOL assumeGS1;

/**
 * Allowed lengths of encoded data -- reject anything else. Maps to an int[].
 */
@property (nonatomic, strong) NSArray *allowedLengths;

/**
 * Specifies what character encoding to use when decoding, where applicable (type String)
 */
@property (nonatomic, assign) NSStringEncoding encoding;

/**
 * Unspecified, application-specific hint.
 */
@property (nonatomic, strong) id other;

/**
 * Image is a pure monochrome image of a barcode.
 */
@property (nonatomic, assign) BOOL pureBarcode;

/**
 * The caller needs to be notified via callback when a possible {@link ResultPoint}
 * is found. Maps to a {@link ResultPointCallback}.
 */
@property (nonatomic, strong) id <ZXResultPointCallback> resultPointCallback;

/**
 * Spend more time to try to find a barcode; optimize for accuracy, not speed.
 */
@property (nonatomic, assign) BOOL tryHarder;

/**
 * Image is known to be of one of a few possible formats.
 */
- (void)addPossibleFormat:(ZXBarcodeFormat)format;
- (BOOL)containsFormat:(ZXBarcodeFormat)format;
- (int)numberOfPossibleFormats;
- (void)removePossibleFormat:(ZXBarcodeFormat)format;

@end