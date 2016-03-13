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

#import "ZXBitArray.h"
#import "ZXBlockParsedResult.h"
#import "ZXCurrentParsingState.h"
#import "ZXDecodedChar.h"
#import "ZXDecodedInformation.h"
#import "ZXDecodedNumeric.h"
#import "ZXFieldParser.h"
#import "ZXGeneralAppIdDecoder.h"

@interface ZXGeneralAppIdDecoder ()

@property (nonatomic, strong) ZXBitArray *information;
@property (nonatomic, strong) ZXCurrentParsingState *current;
@property (nonatomic, strong) NSMutableString *buffer;

@end

@implementation ZXGeneralAppIdDecoder

- (id)initWithInformation:(ZXBitArray *)information {
  if (self = [super init]) {
    _current = [[ZXCurrentParsingState alloc] init];
    _buffer = [NSMutableString string];
    _information = information;
  }

  return self;
}

- (NSString *)decodeAllCodes:(NSMutableString *)buff initialPosition:(int)initialPosition error:(NSError **)error {
  int currentPosition = initialPosition;
  NSString *remaining = nil;
  do {
    ZXDecodedInformation *info = [self decodeGeneralPurposeField:currentPosition remaining:remaining];
    NSString *parsedFields = [ZXFieldParser parseFieldsInGeneralPurpose:[info theNewString] error:error];
    if (!parsedFields) {
      return nil;
    } else if (parsedFields.length > 0) {
      [buff appendString:parsedFields];
    }

    if ([info remaining]) {
      remaining = [@([info remainingValue]) stringValue];
    } else {
      remaining = nil;
    }

    if (currentPosition == [info theNewPosition]) {
      break;
    }
    currentPosition = [info theNewPosition];
  } while (YES);

  return buff;
}

- (BOOL)isStillNumeric:(int)pos {
  if (pos + 7 > self.information.size) {
    return pos + 4 <= self.information.size;
  }

  for (int i = pos; i < pos + 3; ++i) {
    if ([self.information get:i]) {
      return YES;
    }
  }

  return [self.information get:pos + 3];
}

- (ZXDecodedNumeric *)decodeNumeric:(int)pos {
  if (pos + 7 > self.information.size) {
    int numeric = [self extractNumericValueFromBitArray:pos bits:4];
    if (numeric == 0) {
      return [[ZXDecodedNumeric alloc] initWithNewPosition:self.information.size
                                                 firstDigit:FNC1
                                                secondDigit:FNC1];
    }
    return [[ZXDecodedNumeric alloc] initWithNewPosition:self.information.size
                                               firstDigit:numeric - 1
                                              secondDigit:FNC1];
  }
  int numeric = [self extractNumericValueFromBitArray:pos bits:7];

  int digit1 = (numeric - 8) / 11;
  int digit2 = (numeric - 8) % 11;

  return [[ZXDecodedNumeric alloc] initWithNewPosition:pos + 7
                                             firstDigit:digit1
                                            secondDigit:digit2];
}

- (int)extractNumericValueFromBitArray:(int)pos bits:(int)bits {
  return [ZXGeneralAppIdDecoder extractNumericValueFromBitArray:self.information pos:pos bits:bits];
}

+ (int)extractNumericValueFromBitArray:(ZXBitArray *)information pos:(int)pos bits:(int)bits {
  if (bits > 32) {
    [NSException raise:NSInvalidArgumentException format:@"extractNumberValueFromBitArray can't handle more than 32 bits"];
  }

  int value = 0;
  for (int i = 0; i < bits; ++i) {
    if ([information get:pos + i]) {
      value |= 1 << (bits - i - 1);
    }
  }

  return value;
}

- (ZXDecodedInformation *)decodeGeneralPurposeField:(int)pos remaining:(NSString *)remaining {
  [self.buffer setString:@""];

  if (remaining != nil) {
    [self.buffer appendString:remaining];
  }

  self.current.position = pos;

  ZXDecodedInformation *lastDecoded = [self parseBlocks];
  if (lastDecoded != nil && [lastDecoded remaining]) {
    return [[ZXDecodedInformation alloc] initWithNewPosition:self.current.position
                                                    newString:self.buffer
                                               remainingValue:lastDecoded.remainingValue];
  }
  return [[ZXDecodedInformation alloc] initWithNewPosition:self.current.position newString:self.buffer];
}

- (ZXDecodedInformation *)parseBlocks {
  BOOL isFinished;
  ZXBlockParsedResult *result;
  do {
    int initialPosition = self.current.position;

    if (self.current.alpha) {
      result = [self parseAlphaBlock];
      isFinished = result.finished;
    } else if (self.current.isoIec646) {
      result = [self parseIsoIec646Block];
      isFinished = result.finished;
    } else {
      result = [self parseNumericBlock];
      isFinished = result.finished;
    }

    BOOL positionChanged = initialPosition != self.current.position;
    if (!positionChanged && !isFinished) {
      break;
    }
  } while (!isFinished);
  return result.decodedInformation;
}

- (ZXBlockParsedResult *)parseNumericBlock {
  while ([self isStillNumeric:self.current.position]) {
    ZXDecodedNumeric *numeric = [self decodeNumeric:self.current.position];
    self.current.position = numeric.theNewPosition;

    if ([numeric firstDigitFNC1]) {
      ZXDecodedInformation *information;
      if ([numeric secondDigitFNC1]) {
        information = [[ZXDecodedInformation alloc] initWithNewPosition:self.current.position
                                                              newString:self.buffer];
      } else {
        information = [[ZXDecodedInformation alloc] initWithNewPosition:self.current.position
                                                              newString:self.buffer
                                                         remainingValue:numeric.secondDigit];
      }
      return [[ZXBlockParsedResult alloc] initWithInformation:information finished:YES];
    }
    [self.buffer appendFormat:@"%d", numeric.firstDigit];

    if (numeric.secondDigitFNC1) {
      ZXDecodedInformation *information = [[ZXDecodedInformation alloc] initWithNewPosition:self.current.position
                                                                                  newString:self.buffer];
      return [[ZXBlockParsedResult alloc] initWithInformation:information finished:YES];
    }
    [self.buffer appendFormat:@"%d", numeric.secondDigit];
  }

  if ([self isNumericToAlphaNumericLatch:self.current.position]) {
    [self.current setAlpha];
    self.current.position += 4;
  }
  return [[ZXBlockParsedResult alloc] initWithFinished:NO];
}

- (ZXBlockParsedResult *)parseIsoIec646Block {
  while ([self isStillIsoIec646:self.current.position]) {
    ZXDecodedChar *iso = [self decodeIsoIec646:self.current.position];
    self.current.position = iso.theNewPosition;

    if (iso.fnc1) {
      ZXDecodedInformation *information = [[ZXDecodedInformation alloc] initWithNewPosition:self.current.position
                                                                                  newString:self.buffer];
      return [[ZXBlockParsedResult alloc] initWithInformation:information finished:YES];
    }
    [self.buffer appendFormat:@"%C", iso.value];
  }

  if ([self isAlphaOr646ToNumericLatch:self.current.position]) {
    self.current.position += 3;
    [self.current setNumeric];
  } else if ([self isAlphaTo646ToAlphaLatch:self.current.position]) {
    if (self.current.position + 5 < self.information.size) {
      self.current.position += 5;
    } else {
      self.current.position = self.information.size;
    }

    [self.current setAlpha];
  }
  return [[ZXBlockParsedResult alloc] initWithFinished:NO];
}

- (ZXBlockParsedResult *)parseAlphaBlock {
  while ([self isStillAlpha:self.current.position]) {
    ZXDecodedChar *alpha = [self decodeAlphanumeric:self.current.position];
    self.current.position = alpha.theNewPosition;

    if (alpha.fnc1) {
      ZXDecodedInformation *information = [[ZXDecodedInformation alloc] initWithNewPosition:self.current.position
                                                                                  newString:self.buffer];
      return [[ZXBlockParsedResult alloc] initWithInformation:information finished:YES];
    }

    [self.buffer appendFormat:@"%C", alpha.value];
  }

  if ([self isAlphaOr646ToNumericLatch:self.current.position]) {
    self.current.position += 3;
    [self.current setNumeric];
  } else if ([self isAlphaTo646ToAlphaLatch:self.current.position]) {
    if (self.current.position + 5 < self.information.size) {
      self.current.position += 5;
    } else {
      self.current.position = self.information.size;
    }

    [self.current setIsoIec646];
  }
  return [[ZXBlockParsedResult alloc] initWithFinished:NO];
}

- (BOOL)isStillIsoIec646:(int)pos {
  if (pos + 5 > self.information.size) {
    return NO;
  }

  int fiveBitValue = [self extractNumericValueFromBitArray:pos bits:5];
  if (fiveBitValue >= 5 && fiveBitValue < 16) {
    return YES;
  }

  if (pos + 7 > self.information.size) {
    return NO;
  }

  int sevenBitValue = [self extractNumericValueFromBitArray:pos bits:7];
  if (sevenBitValue >= 64 && sevenBitValue < 116) {
    return YES;
  }

  if (pos + 8 > self.information.size) {
    return NO;
  }

  int eightBitValue = [self extractNumericValueFromBitArray:pos bits:8];
  return eightBitValue >= 232 && eightBitValue < 253;
}

- (ZXDecodedChar *)decodeIsoIec646:(int)pos {
  int fiveBitValue = [self extractNumericValueFromBitArray:pos bits:5];
  if (fiveBitValue == 15) {
    return [[ZXDecodedChar alloc] initWithNewPosition:pos + 5 value:FNC1char];
  }

  if (fiveBitValue >= 5 && fiveBitValue < 15) {
    return [[ZXDecodedChar alloc] initWithNewPosition:pos + 5 value:(unichar)('0' + fiveBitValue - 5)];
  }

  int sevenBitValue = [self extractNumericValueFromBitArray:pos bits:7];

  if (sevenBitValue >= 64 && sevenBitValue < 90) {
    return [[ZXDecodedChar alloc] initWithNewPosition:pos + 7 value:(unichar)(sevenBitValue + 1)];
  }

  if (sevenBitValue >= 90 && sevenBitValue < 116) {
    return [[ZXDecodedChar alloc] initWithNewPosition:pos + 7 value:(unichar)(sevenBitValue + 7)];
  }

  int eightBitValue = [self extractNumericValueFromBitArray:pos bits:8];
  unichar c;
  switch (eightBitValue) {
    case 232:
      c = '!';
      break;
    case 233:
      c = '"';
      break;
    case 234:
      c ='%';
      break;
    case 235:
      c = '&';
      break;
    case 236:
      c = '\'';
      break;
    case 237:
      c = '(';
      break;
    case 238:
      c = ')';
      break;
    case 239:
      c = '*';
      break;
    case 240:
      c = '+';
      break;
    case 241:
      c = ',';
      break;
    case 242:
      c = '-';
      break;
    case 243:
      c = '.';
      break;
    case 244:
      c = '/';
      break;
    case 245:
      c = ':';
      break;
    case 246:
      c = ';';
      break;
    case 247:
      c = '<';
      break;
    case 248:
      c = '=';
      break;
    case 249:
      c = '>';
      break;
    case 250:
      c = '?';
      break;
    case 251:
      c = '_';
      break;
    case 252:
      c = ' ';
      break;
    default:
      @throw [NSException exceptionWithName:@"RuntimeException"
                                     reason:[NSString stringWithFormat:@"Decoding invalid ISO/IEC 646 value: %d", eightBitValue]
                                   userInfo:nil];
  }
  return [[ZXDecodedChar alloc] initWithNewPosition:pos + 8 value:c];
}

- (BOOL)isStillAlpha:(int)pos {
  if (pos + 5 > self.information.size) {
    return NO;
  }

  int fiveBitValue = [self extractNumericValueFromBitArray:pos bits:5];
  if (fiveBitValue >= 5 && fiveBitValue < 16) {
    return YES;
  }

  if (pos + 6 > self.information.size) {
    return NO;
  }

  int sixBitValue = [self extractNumericValueFromBitArray:pos bits:6];
  return sixBitValue >= 16 && sixBitValue < 63;
}

- (ZXDecodedChar *)decodeAlphanumeric:(int)pos {
  int fiveBitValue = [self extractNumericValueFromBitArray:pos bits:5];
  if (fiveBitValue == 15) {
    return [[ZXDecodedChar alloc] initWithNewPosition:pos + 5 value:FNC1char];
  }

  if (fiveBitValue >= 5 && fiveBitValue < 15) {
    return [[ZXDecodedChar alloc] initWithNewPosition:pos + 5 value:(unichar)('0' + fiveBitValue - 5)];
  }

  int sixBitValue = [self extractNumericValueFromBitArray:pos bits:6];

  if (sixBitValue >= 32 && sixBitValue < 58) {
    return [[ZXDecodedChar alloc] initWithNewPosition:pos + 6 value:(unichar)(sixBitValue + 33)];
  }

  unichar c;
  switch (sixBitValue){
    case 58:
      c = '*';
      break;
    case 59:
      c = ',';
      break;
    case 60:
      c = '-';
      break;
    case 61:
      c = '.';
      break;
    case 62:
      c = '/';
      break;
    default:
      @throw [NSException exceptionWithName:@"RuntimeException"
                                     reason:[NSString stringWithFormat:@"Decoding invalid alphanumeric value: %d", sixBitValue]
                                   userInfo:nil];
  }

  return [[ZXDecodedChar alloc] initWithNewPosition:pos + 6 value:c];
}

- (BOOL)isAlphaTo646ToAlphaLatch:(int)pos {
  if (pos + 1 > self.information.size) {
    return NO;
  }

  for (int i = 0; i < 5 && i + pos < self.information.size; ++i) {
    if (i == 2) {
      if (![self.information get:pos + 2]) {
        return NO;
      }
    } else if ([self.information get:pos + i]) {
      return NO;
    }
  }

  return YES;
}

- (BOOL)isAlphaOr646ToNumericLatch:(int)pos {
  if (pos + 3 > self.information.size) {
    return NO;
  }

  for (int i = pos; i < pos + 3; ++i) {
    if ([self.information get:i]) {
      return NO;
    }
  }

  return YES;
}

- (BOOL)isNumericToAlphaNumericLatch:(int)pos {
  if (pos + 1 > self.information.size) {
    return NO;
  }

  for (int i = 0; i < 4 && i + pos < self.information.size; ++i) {
    if ([self.information get:pos + i]) {
      return NO;
    }
  }

  return YES;
}

@end
