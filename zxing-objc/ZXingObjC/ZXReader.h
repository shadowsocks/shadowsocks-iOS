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
 * Implementations of this interface can decode an image of a barcode in some format into
 * the String it encodes. For example, ZXQRCodeReader can
 * decode a QR code. The decoder may optionally receive hints from the caller which may help
 * it decode more quickly or accurately.
 * 
 * See ZXMultiFormatReader, which attempts to determine what barcode
 * format is present within the image as well, and then decodes it accordingly.
 */

@class ZXBinaryBitmap, ZXDecodeHints, ZXResult;

@protocol ZXReader <NSObject>

- (ZXResult *)decode:(ZXBinaryBitmap *)image error:(NSError **)error;
- (ZXResult *)decode:(ZXBinaryBitmap *)image hints:(ZXDecodeHints *)hints error:(NSError **)error;
- (void)reset;

@end
