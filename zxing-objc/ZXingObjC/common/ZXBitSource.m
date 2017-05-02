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

#import "ZXBitSource.h"

@interface ZXBitSource ()

@property (nonatomic, assign) int8_t *bytes;
@property (nonatomic, assign) int byteOffset;
@property (nonatomic, assign) int bitOffset;
@property (nonatomic, assign) int length;

@end

@implementation ZXBitSource

/**
 * bytes is the bytes from which this will read bits. Bits will be read from the first byte first.
 * Bits are read within a byte from most-significant to least-significant bit.
 */
- (id)initWithBytes:(int8_t *)bytes length:(unsigned int)length {
  if (self = [super init]) {
    _bytes = bytes;
    _length = length;
  }
  return self;
}


- (int)readBits:(int)numBits {
  if (numBits < 1 || numBits > 32 || numBits > self.available) {
    [NSException raise:NSInvalidArgumentException 
                format:@"Invalid number of bits: %d", numBits];
  }
  int result = 0;
  if (self.bitOffset > 0) {
    int bitsLeft = 8 - self.bitOffset;
    int toRead = numBits < bitsLeft ? numBits : bitsLeft;
    int bitsToNotRead = bitsLeft - toRead;
    int mask = (0xFF >> (8 - toRead)) << bitsToNotRead;
    result = (self.bytes[self.byteOffset] & mask) >> bitsToNotRead;
    numBits -= toRead;
    self.bitOffset += toRead;
    if (self.bitOffset == 8) {
      self.bitOffset = 0;
      self.byteOffset++;
    }
  }

  if (numBits > 0) {
    while (numBits >= 8) {
      result = (result << 8) | (self.bytes[self.byteOffset] & 0xFF);
      self.byteOffset++;
      numBits -= 8;
    }

    if (numBits > 0) {
      int bitsToNotRead = 8 - numBits;
      int mask = (0xFF >> bitsToNotRead) << bitsToNotRead;
      result = (result << numBits) | ((self.bytes[self.byteOffset] & mask) >> bitsToNotRead);
      self.bitOffset += numBits;
    }
  }
  return result;
}

- (int)available {
  return 8 * (self.length - self.byteOffset) - self.bitOffset;
}

@end
