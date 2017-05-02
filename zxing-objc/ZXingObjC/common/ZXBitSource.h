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
 * This provides an easy abstraction to read bits at a time from a sequence of bytes, where the
 * number of bits read is not often a multiple of 8.
 * 
 * This class is thread-safe but not reentrant -- unless the caller modifies the bytes array
 * it passed in, in which case all bets are off.
 */

@interface ZXBitSource : NSObject

@property (nonatomic, assign, readonly) int bitOffset;
@property (nonatomic, assign, readonly) int byteOffset;

- (id)initWithBytes:(int8_t *)bytes length:(unsigned int)length;
- (int)readBits:(int)numBits;
- (int)available;

@end
