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

#import "ZXMode.h"
#import "ZXQRCodeVersion.h"

@interface ZXMode ()

@property (nonatomic, strong) NSArray *characterCountBitsForVersions;

@end

@implementation ZXMode

- (id)initWithCharacterCountBitsForVersions:(NSArray *)characterCountBitsForVersions bits:(int)bits name:(NSString *)name {
  if (self = [super init]) {
    _characterCountBitsForVersions = characterCountBitsForVersions;
    _bits = bits;
    _name = name;
  }

  return self;
}

+ (ZXMode *)forBits:(int)bits {
  switch (bits) {
    case 0x0:
      return [ZXMode terminatorMode];
    case 0x1:
      return [ZXMode numericMode];
    case 0x2:
      return [ZXMode alphanumericMode];
    case 0x3:
      return [ZXMode structuredAppendMode];
    case 0x4:
      return [ZXMode byteMode];
    case 0x5:
      return [ZXMode fnc1FirstPositionMode];
    case 0x7:
      return [ZXMode eciMode];
    case 0x8:
      return [ZXMode kanjiMode];
    case 0x9:
      return [ZXMode fnc1SecondPositionMode];
    case 0xD:
      return [ZXMode hanziMode];
    default:
      return nil;
  }
}

- (int)characterCountBits:(ZXQRCodeVersion *)version {
  int number = version.versionNumber;
  int offset;
  if (number <= 9) {
    offset = 0;
  } else if (number <= 26) {
    offset = 1;
  } else {
    offset = 2;
  }
  return [self.characterCountBitsForVersions[offset] intValue];
}

- (NSString *)description {
  return self.name;
}

+ (ZXMode *)terminatorMode {
  static ZXMode *thisMode = nil;
  if (!thisMode) {
    thisMode = [[ZXMode alloc] initWithCharacterCountBitsForVersions:@[@0, @0, @0] bits:0x00 name:@"TERMINATOR"];
  }
  return thisMode;
}

+ (ZXMode *)numericMode {
  static ZXMode *thisMode = nil;
  if (!thisMode) {
    thisMode = [[ZXMode alloc] initWithCharacterCountBitsForVersions:@[@10, @12, @14] bits:0x01 name:@"NUMERIC"];
  }
  return thisMode;
}

+ (ZXMode *)alphanumericMode {
  static ZXMode *thisMode = nil;
  if (!thisMode) {
    thisMode = [[ZXMode alloc] initWithCharacterCountBitsForVersions:@[@9, @11, @13] bits:0x02 name:@"ALPHANUMERIC"];
  }
  return thisMode;
}

+ (ZXMode *)structuredAppendMode {
  static ZXMode *thisMode = nil;
  if (!thisMode) {
    thisMode = [[ZXMode alloc] initWithCharacterCountBitsForVersions:@[@0, @0, @0] bits:0x03 name:@"STRUCTURED_APPEND"];
  }
  return thisMode;
}

+ (ZXMode *)byteMode {
  static ZXMode *thisMode = nil;
  if (!thisMode) {
    thisMode = [[ZXMode alloc] initWithCharacterCountBitsForVersions:@[@8, @16, @16] bits:0x04 name:@"BYTE"];
  }
  return thisMode;
}

+ (ZXMode *)eciMode {
  static ZXMode *thisMode = nil;
  if (!thisMode) {
    thisMode = [[ZXMode alloc] initWithCharacterCountBitsForVersions:@[@0, @0, @0] bits:0x07 name:@"ECI"];
  }
  return thisMode;
}

+ (ZXMode *)kanjiMode {
  static ZXMode *thisMode = nil;
  if (!thisMode) {
    thisMode = [[ZXMode alloc] initWithCharacterCountBitsForVersions:@[@8, @10, @12] bits:0x08 name:@"KANJI"];
  }
  return thisMode;
}

+ (ZXMode *)fnc1FirstPositionMode {
  static ZXMode *thisMode = nil;
  if (!thisMode) {
    thisMode = [[ZXMode alloc] initWithCharacterCountBitsForVersions:@[@0, @0, @0] bits:0x05 name:@"FNC1_FIRST_POSITION"];
  }
  return thisMode;
}

+ (ZXMode *)fnc1SecondPositionMode {
  static ZXMode *thisMode = nil;
  if (!thisMode) {
    thisMode = [[ZXMode alloc] initWithCharacterCountBitsForVersions:@[@0, @0, @0] bits:0x09 name:@"FNC1_SECOND_POSITION"];
  }
  return thisMode;
}

/**
 * See GBT 18284-2000; "Hanzi" is a transliteration of this mode name.
 */
+ (ZXMode *)hanziMode {
  static ZXMode *thisMode = nil;
  if (!thisMode) {
    thisMode = [[ZXMode alloc] initWithCharacterCountBitsForVersions:@[@8, @10, @12] bits:0x0D name:@"HANZI"];
  }
  return thisMode;
}

@end
