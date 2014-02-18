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

extern int ZX_DEFAULT_AZTEC_EC_PERCENT;

@class ZXAztecCode, ZXBitArray, ZXGenericGF;

@interface ZXAztecEncoder : NSObject

+ (ZXAztecCode *)encode:(int8_t *)data len:(int)len;
+ (ZXAztecCode *)encode:(int8_t *)data len:(int)len minECCPercent:(int)minECCPercent;
+ (void)drawBullsEye:(ZXBitMatrix *)matrix center:(int)center size:(int)size;
+ (ZXBitArray *)generateModeMessageCompact:(BOOL)compact layers:(int)layers messageSizeInWords:(int)messageSizeInWords;
+ (void)drawModeMessage:(ZXBitMatrix *)matrix compact:(BOOL)compact matrixSize:(int)matrixSize modeMessage:(ZXBitArray *)modeMessage;
+ (ZXBitArray *)generateCheckWords:(ZXBitArray *)stuffedBits totalSymbolBits:(int)totalSymbolBits wordSize:(int)wordSize;
+ (void)bitsToWords:(ZXBitArray *)stuffedBits wordSize:(int)wordSize totalWords:(int)totalWords message:(int *)message;
+ (ZXGenericGF *)getGF:(int)wordSize;
+ (ZXBitArray *)stuffBits:(ZXBitArray *)bits wordSize:(int)wordSize;
+ (ZXBitArray *)highLevelEncode:(int8_t *)data len:(int)len;
+ (void)outputWord:(ZXBitArray *)bits mode:(int)mode value:(int)value;

@end
