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
#import "ZXResultMetadataType.h"

/**
 * Encapsulates the result of decoding a barcode within an image.
 */

@interface ZXResult : NSObject

@property (nonatomic, copy, readonly) NSString *text;
@property (nonatomic, assign, readonly) int8_t *rawBytes;
@property (nonatomic, assign, readonly) int length;
@property (nonatomic, strong, readonly) NSMutableArray *resultPoints;
@property (nonatomic, assign, readonly) ZXBarcodeFormat barcodeFormat;
@property (nonatomic, strong, readonly) NSMutableDictionary *resultMetadata;
@property (nonatomic, assign, readonly) long timestamp;

- (id)initWithText:(NSString *)text rawBytes:(int8_t *)rawBytes length:(unsigned int)length resultPoints:(NSArray *)resultPoints format:(ZXBarcodeFormat)format;
- (id)initWithText:(NSString *)text rawBytes:(int8_t *)rawBytes length:(unsigned int)length resultPoints:(NSArray *)resultPoints format:(ZXBarcodeFormat)format timestamp:(long)timestamp;
+ (id)resultWithText:(NSString *)text rawBytes:(int8_t *)rawBytes length:(unsigned int)length resultPoints:(NSArray *)resultPoints format:(ZXBarcodeFormat)format;
+ (id)resultWithText:(NSString *)text rawBytes:(int8_t *)rawBytes length:(unsigned int)length resultPoints:(NSArray *)resultPoints format:(ZXBarcodeFormat)format timestamp:(long)timestamp;
- (void)putMetadata:(ZXResultMetadataType)type value:(id)value;
- (void)putAllMetadata:(NSMutableDictionary *)metadata;
- (void)addResultPoints:(NSArray *)newPoints;

@end
