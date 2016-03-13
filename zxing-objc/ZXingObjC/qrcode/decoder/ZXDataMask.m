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

#import "ZXBitMatrix.h"
#import "ZXDataMask.h"

/**
 * 000: mask bits for which (x + y) mod 2 == 0
 */

@interface ZXDataMask000 : ZXDataMask

@end

@implementation ZXDataMask000

- (BOOL)isMasked:(int)i j:(int)j {
  return ((i + j) & 0x01) == 0;
}

@end


/**
 * 001: mask bits for which x mod 2 == 0
 */

@interface ZXDataMask001 : ZXDataMask

@end

@implementation ZXDataMask001

- (BOOL)isMasked:(int)i j:(int)j {
  return (i & 0x01) == 0;
}

@end


/**
 * 010: mask bits for which y mod 3 == 0
 */

@interface ZXDataMask010 : ZXDataMask

@end

@implementation ZXDataMask010

- (BOOL)isMasked:(int)i j:(int)j {
  return j % 3 == 0;
}

@end


/**
 * 011: mask bits for which (x + y) mod 3 == 0
 */

@interface ZXDataMask011 : ZXDataMask

@end

@implementation ZXDataMask011

- (BOOL)isMasked:(int)i j:(int)j {
  return (i + j) % 3 == 0;
}

@end


/**
 * 100: mask bits for which (x/2 + y/3) mod 2 == 0
 */

@interface ZXDataMask100 : ZXDataMask

@end

@implementation ZXDataMask100

- (BOOL)isMasked:(int)i j:(int)j {
  return (((int)((unsigned int)i >> 1) + (j / 3)) & 0x01) == 0;
}

@end


/**
 * 101: mask bits for which xy mod 2 + xy mod 3 == 0
 */

@interface ZXDataMask101 : ZXDataMask

@end

@implementation ZXDataMask101

- (BOOL)isMasked:(int)i j:(int)j {
  int temp = i * j;
  return (temp & 0x01) + (temp % 3) == 0;
}

@end


/**
 * 110: mask bits for which (xy mod 2 + xy mod 3) mod 2 == 0
 */

@interface ZXDataMask110 : ZXDataMask

@end

@implementation ZXDataMask110

- (BOOL)isMasked:(int)i j:(int)j {
  int temp = i * j;
  return (((temp & 0x01) + (temp % 3)) & 0x01) == 0;
}

@end


/**
 * 111: mask bits for which ((x+y)mod 2 + xy mod 3) mod 2 == 0
 */

@interface ZXDataMask111 : ZXDataMask

@end

@implementation ZXDataMask111

- (BOOL)isMasked:(int)i j:(int)j {
  return ((((i + j) & 0x01) + ((i * j) % 3)) & 0x01) == 0;
}

@end


@implementation ZXDataMask

static NSArray *DATA_MASKS = nil;

/**
 * Implementations of this method reverse the data masking process applied to a QR Code and
 * make its bits ready to read.
 */
- (void)unmaskBitMatrix:(ZXBitMatrix *)bits dimension:(int)dimension {
  for (int i = 0; i < dimension; i++) {
    for (int j = 0; j < dimension; j++) {
      if ([self isMasked:i j:j]) {
        [bits flipX:j y:i];
      }
    }
  }
}

- (BOOL)isMasked:(int)i j:(int)j {
  @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                 reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                               userInfo:nil];
}


+ (ZXDataMask *)forReference:(int)reference {
  if (!DATA_MASKS) {
    /**
     * See ISO 18004:2006 6.8.1
     */
    DATA_MASKS = @[[[ZXDataMask000 alloc] init],
                   [[ZXDataMask001 alloc] init],
                   [[ZXDataMask010 alloc] init],
                   [[ZXDataMask011 alloc] init],
                   [[ZXDataMask100 alloc] init],
                   [[ZXDataMask101 alloc] init],
                   [[ZXDataMask110 alloc] init],
                   [[ZXDataMask111 alloc] init]];
  }

  if (reference < 0 || reference > 7) {
    [NSException raise:NSInvalidArgumentException  format:@"Invalid reference value"];
  }
  return DATA_MASKS[reference];
}

@end
