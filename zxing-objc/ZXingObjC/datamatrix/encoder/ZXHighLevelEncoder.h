/*
 * Copyright 2013 ZXing authors
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
 * DataMatrix ECC 200 data encoder following the algorithm described in ISO/IEC 16022:200(E) in
 * annex S.
 */

@class ZXDimension, ZXSymbolShapeHint;

@interface ZXHighLevelEncoder : NSObject

/**
 * mode latch to C40 encodation mode
 */
+ (unichar)latchToC40;

/**
 * mode latch to Base 256 encodation mode
 */
+ (unichar)latchToBase256;

/**
 * Upper Shift
 */
+ (unichar)upperShift;

/**
 * 05 Macro
 */
+ (unichar)macro05;

/**
 * 06 Macro
 */
+ (unichar)macro06;

/**
 * mode latch to ANSI X.12 encodation mode
 */
+ (unichar)latchToAnsiX12;

/**
 * mode latch to Text encodation mode
 */

+ (unichar)latchToText;

/**
 * mode latch to EDIFACT encodation mode
 */
+ (unichar)latchToEdifact;

/**
 * Unlatch from C40 encodation
 */
+ (unichar)c40Unlatch;

/**
 * Unlatch from X12 encodation
 */
+ (unichar)x12Unlatch;

+ (int)asciiEncodation;
+ (int)c40Encodation;
+ (int)textEncodation;
+ (int)x12Encodation;
+ (int)edifactEncodation;
+ (int)base256Encodation;

/**
 * Converts the message to a byte array using the default encoding (cp437) as defined by the
 * specification
 */
+ (int8_t *)bytesForMessage:(NSString *)msg;

/**
 * Performs message encoding of a DataMatrix message using the algorithm described in annex P
 * of ISO/IEC 16022:2000(E).
 */
+ (NSString *)encodeHighLevel:(NSString *)msg;

/**
 * Performs message encoding of a DataMatrix message using the algorithm described in annex P
 * of ISO/IEC 16022:2000(E).
 */
+ (NSString *)encodeHighLevel:(NSString *)msg shape:(ZXSymbolShapeHint *)shape
                      minSize:(ZXDimension *)minSize maxSize:(ZXDimension *)maxSize;

+ (int)lookAheadTest:(NSString *)msg startpos:(int)startpos currentMode:(int)currentMode;

/**
 * Determines the number of consecutive characters that are encodable using numeric compaction.
 */
+ (int)determineConsecutiveDigitCount:(NSString *)msg startpos:(int)startpos;

+ (BOOL)isDigit:(unichar)ch;
+ (BOOL)isExtendedASCII:(unichar)ch;

+ (void)illegalCharacter:(unichar)c;

@end
