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
 * A simple, fast array of bits, represented compactly by an array of ints internally.
 */

@interface ZXBitArray : NSObject

@property (nonatomic, readonly) int32_t *bits;
@property (nonatomic, readonly) int size;

- (id)initWithSize:(int)size;
- (int)sizeInBytes;
- (BOOL)get:(int)i;
- (void)set:(int)i;
- (void)flip:(int)i;
- (int)nextSet:(int)from;
- (int)nextUnset:(int)from;
- (void)setBulk:(int)i newBits:(int32_t)newBits;
- (void)setRange:(int)start end:(int)end;
- (void)clear;
- (BOOL)isRange:(int)start end:(int)end value:(BOOL)value;
- (void)appendBit:(BOOL)bit;
- (void)appendBits:(int32_t)value numBits:(int)numBits;
- (void)appendBitArray:(ZXBitArray *)other;
- (void)xor:(ZXBitArray *)other;
- (void)toBytes:(int)bitOffset array:(int8_t *)array offset:(int)offset numBytes:(int)numBytes;
- (void)reverse;

@end
