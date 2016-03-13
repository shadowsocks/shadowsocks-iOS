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
 * QR Codes can encode text as bits in one of several modes, and can use multiple modes
 * in one QR Code. This class decodes the bits back into text.
 * 
 * See ISO 18004:2006, 6.4.3 - 6.4.7
 */

@class ZXDecodeHints, ZXDecoderResult, ZXErrorCorrectionLevel, ZXQRCodeVersion;

@interface ZXQRCodeDecodedBitStreamParser : NSObject

+ (ZXDecoderResult *)decode:(int8_t *)bytes length:(unsigned int)length version:(ZXQRCodeVersion *)version
                    ecLevel:(ZXErrorCorrectionLevel *)ecLevel hints:(ZXDecodeHints *)hints error:(NSError **)error;

@end
