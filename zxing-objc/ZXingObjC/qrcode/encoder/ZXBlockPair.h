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

@interface ZXBlockPair : NSObject

@property (nonatomic, assign, readonly) int8_t *dataBytes;
@property (nonatomic, assign, readonly) int8_t *errorCorrectionBytes;
@property (nonatomic, assign, readonly) int errorCorrectionLength;
@property (nonatomic, assign, readonly) int length;

- (id)initWithData:(int8_t *)data length:(unsigned int)length errorCorrection:(int8_t *)errorCorrection errorCorrectionLength:(unsigned int)errorCorrectionLength;

@end
