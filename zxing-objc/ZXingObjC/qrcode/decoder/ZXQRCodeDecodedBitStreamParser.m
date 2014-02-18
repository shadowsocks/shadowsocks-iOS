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
#import "ZXCharacterSetECI.h"
#import "ZXDecoderResult.h"
#import "ZXErrors.h"
#import "ZXErrorCorrectionLevel.h"
#import "ZXMode.h"
#import "ZXQRCodeDecodedBitStreamParser.h"
#import "ZXQRCodeVersion.h"
#import "ZXStringUtils.h"


/**
 * See ISO 18004:2006, 6.4.4 Table 5
 */
char const ALPHANUMERIC_CHARS[45] = {
  '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B',
  'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N',
  'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
  ' ', '$', '%', '*', '+', '-', '.', '/', ':'
};

int const GB2312_SUBSET = 1;

@implementation ZXQRCodeDecodedBitStreamParser

+ (ZXDecoderResult *)decode:(int8_t *)bytes length:(unsigned int)length version:(ZXQRCodeVersion *)version
                    ecLevel:(ZXErrorCorrectionLevel *)ecLevel hints:(ZXDecodeHints *)hints error:(NSError **)error {
  ZXBitSource *bits = [[ZXBitSource alloc] initWithBytes:bytes length:length];
  NSMutableString *result = [NSMutableString stringWithCapacity:50];
  ZXCharacterSetECI *currentCharacterSetECI = nil;
  BOOL fc1InEffect = NO;
  NSMutableArray *byteSegments = [NSMutableArray arrayWithCapacity:1];
  ZXMode *mode;

  do {
    if ([bits available] < 4) {
      mode = [ZXMode terminatorMode];
    } else {
      mode = [ZXMode forBits:[bits readBits:4]];
      if (!mode) {
        if (error) *error = FormatErrorInstance();
        return nil;
      }
    }
    if (![mode isEqual:[ZXMode terminatorMode]]) {
      if ([mode isEqual:[ZXMode fnc1FirstPositionMode]] || [mode isEqual:[ZXMode fnc1SecondPositionMode]]) {
        fc1InEffect = YES;
      } else if ([mode isEqual:[ZXMode structuredAppendMode]]) {
        if (bits.available < 16) {
          if (error) *error = FormatErrorInstance();
          return nil;
        }
        [bits readBits:16];
      } else if ([mode isEqual:[ZXMode eciMode]]) {
        int value = [self parseECIValue:bits];
        currentCharacterSetECI = [ZXCharacterSetECI characterSetECIByValue:value];
        if (currentCharacterSetECI == nil) {
          if (error) *error = FormatErrorInstance();
          return nil;
        }
      } else {
        if ([mode isEqual:[ZXMode hanziMode]]) {
          int subset = [bits readBits:4];
          int countHanzi = [bits readBits:[mode characterCountBits:version]];
          if (subset == GB2312_SUBSET) {
            if (![self decodeHanziSegment:bits result:result count:countHanzi]) {
              if (error) *error = FormatErrorInstance();
              return nil;
            }
          }
        } else {
          int count = [bits readBits:[mode characterCountBits:version]];
          if ([mode isEqual:[ZXMode numericMode]]) {
            if (![self decodeNumericSegment:bits result:result count:count]) {
              if (error) *error = FormatErrorInstance();
              return nil;
            }
          } else if ([mode isEqual:[ZXMode alphanumericMode]]) {
            if (![self decodeAlphanumericSegment:bits result:result count:count fc1InEffect:fc1InEffect]) {
              if (error) *error = FormatErrorInstance();
              return nil;
            }
          } else if ([mode isEqual:[ZXMode byteMode]]) {
            if (![self decodeByteSegment:bits result:result count:count currentCharacterSetECI:currentCharacterSetECI byteSegments:byteSegments hints:hints]) {
              if (error) *error = FormatErrorInstance();
              return nil;
            }
          } else if ([mode isEqual:[ZXMode kanjiMode]]) {
            if (![self decodeKanjiSegment:bits result:result count:count]) {
              if (error) *error = FormatErrorInstance();
              return nil;
            }
          } else {
            if (error) *error = FormatErrorInstance();
            return nil;
          }
        }
      }
    }
  } while (![mode isEqual:[ZXMode terminatorMode]]);
  return [[ZXDecoderResult alloc] initWithRawBytes:bytes
                                             length:length
                                               text:result.description
                                       byteSegments:byteSegments.count == 0 ? nil : byteSegments
                                            ecLevel:ecLevel == nil ? nil : ecLevel.description];
}


/**
 * See specification GBT 18284-2000
 */
+ (BOOL)decodeHanziSegment:(ZXBitSource *)bits result:(NSMutableString *)result count:(int)count {
  if (count * 13 > bits.available) {
    return NO;
  }

  NSMutableData *buffer = [NSMutableData dataWithCapacity:2 * count];
  while (count > 0) {
    int twoBytes = [bits readBits:13];
    int assembledTwoBytes = ((twoBytes / 0x060) << 8) | (twoBytes % 0x060);
    if (assembledTwoBytes < 0x003BF) {
      assembledTwoBytes += 0x0A1A1;
    } else {
      assembledTwoBytes += 0x0A6A1;
    }
    char bytes[2];
    bytes[0] = (char)((assembledTwoBytes >> 8) & 0xFF);
    bytes[1] = (char)(assembledTwoBytes & 0xFF);

    [buffer appendBytes:bytes length:2];

    count--;
  }

  NSString *string = [[NSString alloc] initWithData:buffer encoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)];
  if (string) {
    [result appendString:string];
  }
  return YES;
}

+ (BOOL)decodeKanjiSegment:(ZXBitSource *)bits result:(NSMutableString *)result count:(int)count {
  if (count * 13 > bits.available) {
    return NO;
  }

  NSMutableData *buffer = [NSMutableData dataWithCapacity:2 * count];
  while (count > 0) {
    int twoBytes = [bits readBits:13];
    int assembledTwoBytes = ((twoBytes / 0x0C0) << 8) | (twoBytes % 0x0C0);
    if (assembledTwoBytes < 0x01F00) {
      assembledTwoBytes += 0x08140;
    } else {
      assembledTwoBytes += 0x0C140;
    }
    char bytes[2];
    bytes[0] = (char)(assembledTwoBytes >> 8);
    bytes[1] = (char)assembledTwoBytes;
    
    [buffer appendBytes:bytes length:2];

    count--;
  }

  NSString *string = [[NSString alloc] initWithData:buffer encoding:NSShiftJISStringEncoding];
  if (string) {
    [result appendString:string];
  }
  return YES;
}

+ (BOOL)decodeByteSegment:(ZXBitSource *)bits result:(NSMutableString *)result count:(int)count currentCharacterSetECI:(ZXCharacterSetECI *)currentCharacterSetECI byteSegments:(NSMutableArray *)byteSegments hints:(ZXDecodeHints *)hints {
  if (count << 3 > bits.available) {
    return NO;
  }
  int8_t readBytes[count];
  NSMutableArray *readBytesArray = [NSMutableArray arrayWithCapacity:count];

  for (int i = 0; i < count; i++) {
    readBytes[i] = (char)[bits readBits:8];
    [readBytesArray addObject:[NSNumber numberWithChar:readBytes[i]]];
  }

  NSStringEncoding encoding;
  if (currentCharacterSetECI == nil) {
    encoding = [ZXStringUtils guessEncoding:readBytes length:count hints:hints];
  } else {
    encoding = [currentCharacterSetECI encoding];
  }

  NSString *string = [[NSString alloc] initWithBytes:readBytes length:count encoding:encoding];
  if (string) {
    [result appendString:string];
  }
  
  [byteSegments addObject:readBytesArray];
  return YES;
}

+ (unichar)toAlphaNumericChar:(int)value {
  if (value >= 45) {
    return -1;
  }
  return ALPHANUMERIC_CHARS[value];
}

+ (BOOL)decodeAlphanumericSegment:(ZXBitSource *)bits result:(NSMutableString *)result count:(int)count fc1InEffect:(BOOL)fc1InEffect {
  int start = (int)result.length;

  while (count > 1) {
    if ([bits available] < 11) {
      return NO;
    }
    int nextTwoCharsBits = [bits readBits:11];
    unichar next1 = [self toAlphaNumericChar:nextTwoCharsBits / 45];
    unichar next2 = [self toAlphaNumericChar:nextTwoCharsBits % 45];

    [result appendFormat:@"%C%C", next1, next2];
    count -= 2;
  }

  if (count == 1) {
    if ([bits available] < 6) {
      return NO;
    }
    unichar next1 = [self toAlphaNumericChar:[bits readBits:6]];
    [result appendFormat:@"%C", next1];
  }
  if (fc1InEffect) {
    for (int i = start; i < [result length]; i++) {
      if ([result characterAtIndex:i] == '%') {
        if (i < [result length] - 1 && [result characterAtIndex:i + 1] == '%') {
          [result deleteCharactersInRange:NSMakeRange(i + 1, 1)];
        } else {
          [result insertString:[NSString stringWithFormat:@"%C", (unichar)0x1D]
                       atIndex:i];
        }
      }
    }
  }
  return YES;
}

+ (BOOL)decodeNumericSegment:(ZXBitSource *)bits result:(NSMutableString *)result count:(int)count {
  // Read three digits at a time
  while (count >= 3) {
    // Each 10 bits encodes three digits
    if (bits.available < 10) {
      return NO;
    }
    int threeDigitsBits = [bits readBits:10];
    if (threeDigitsBits >= 1000) {
      return NO;
    }
    unichar next1 = [self toAlphaNumericChar:threeDigitsBits / 100];
    unichar next2 = [self toAlphaNumericChar:(threeDigitsBits / 10) % 10];
    unichar next3 = [self toAlphaNumericChar:threeDigitsBits % 10];

    [result appendFormat:@"%C%C%C", next1, next2, next3];
    count -= 3;
  }

  if (count == 2) {
    // Two digits left over to read, encoded in 7 bits
    if (bits.available < 7) {
      return NO;
    }
    int twoDigitsBits = [bits readBits:7];
    if (twoDigitsBits >= 100) {
      return NO;
    }
    unichar next1 = [self toAlphaNumericChar:twoDigitsBits / 10];
    unichar next2 = [self toAlphaNumericChar:twoDigitsBits % 10];
    [result appendFormat:@"%C%C", next1, next2];
  } else if (count == 1) {
    // One digit left over to read
    if (bits.available < 4) {
      return NO;
    }
    int digitBits = [bits readBits:4];
    if (digitBits >= 10) {
      return NO;
    }
    unichar next1 = [self toAlphaNumericChar:digitBits];
    [result appendFormat:@"%C", next1];
  }
  return YES;
}

+ (int)parseECIValue:(ZXBitSource *)bits {
  int firstByte = [bits readBits:8];
  if ((firstByte & 0x80) == 0) {
    return firstByte & 0x7F;
  }
  if ((firstByte & 0xC0) == 0x80) {
    int secondByte = [bits readBits:8];
    return ((firstByte & 0x3F) << 8) | secondByte;
  }
  if ((firstByte & 0xE0) == 0xC0) {
    int secondThirdBytes = [bits readBits:16];
    return ((firstByte & 0x1F) << 16) | secondThirdBytes;
  }
  return -1;
}

@end
