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

@class ZXBitArray, ZXByteMatrix, ZXErrorCorrectionLevel, ZXQRCodeVersion;

@interface ZXMatrixUtil : NSObject

+ (BOOL)buildMatrix:(ZXBitArray *)dataBits ecLevel:(ZXErrorCorrectionLevel *)ecLevel version:(ZXQRCodeVersion *)version maskPattern:(int)maskPattern matrix:(ZXByteMatrix *)matrix error:(NSError **)error;
+ (void)clearMatrix:(ZXByteMatrix *)matrix;
+ (BOOL)embedBasicPatterns:(ZXQRCodeVersion *)version matrix:(ZXByteMatrix *)matrix error:(NSError **)error;
+ (BOOL)embedTypeInfo:(ZXErrorCorrectionLevel *)ecLevel maskPattern:(int)maskPattern matrix:(ZXByteMatrix *)matrix error:(NSError **)error;
+ (BOOL)maybeEmbedVersionInfo:(ZXQRCodeVersion *)version matrix:(ZXByteMatrix *)matrix error:(NSError **)error;
+ (BOOL)embedDataBits:(ZXBitArray *)dataBits maskPattern:(int)maskPattern matrix:(ZXByteMatrix *)matrix error:(NSError **)error;
+ (int)findMSBSet:(int)value;
+ (int)calculateBCHCode:(int)value poly:(int)poly;
+ (BOOL)makeTypeInfoBits:(ZXErrorCorrectionLevel *)ecLevel maskPattern:(int)maskPattern bits:(ZXBitArray *)bits error:(NSError **)error;
+ (BOOL)makeVersionInfoBits:(ZXQRCodeVersion *)version bits:(ZXBitArray *)bits error:(NSError **)error;

@end
