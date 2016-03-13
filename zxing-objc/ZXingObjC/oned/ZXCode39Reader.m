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
#import "ZXCode39Reader.h"
#import "ZXErrors.h"
#import "ZXResult.h"
#import "ZXResultPoint.h"

char CODE39_ALPHABET[] = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ-. *$/+%";
NSString *CODE39_ALPHABET_STRING = @"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ-. *$/+%";

/**
 * These represent the encodings of characters, as patterns of wide and narrow bars.
 * The 9 least-significant bits of each int correspond to the pattern of wide and narrow,
 * with 1s representing "wide" and 0s representing narrow.
 */
int CODE39_CHARACTER_ENCODINGS[44] = {
  0x034, 0x121, 0x061, 0x160, 0x031, 0x130, 0x070, 0x025, 0x124, 0x064, // 0-9
  0x109, 0x049, 0x148, 0x019, 0x118, 0x058, 0x00D, 0x10C, 0x04C, 0x01C, // A-J
  0x103, 0x043, 0x142, 0x013, 0x112, 0x052, 0x007, 0x106, 0x046, 0x016, // K-T
  0x181, 0x0C1, 0x1C0, 0x091, 0x190, 0x0D0, 0x085, 0x184, 0x0C4, 0x094, // U-*
  0x0A8, 0x0A2, 0x08A, 0x02A // $-%
};

int const CODE39_ASTERISK_ENCODING = 0x094;

@interface ZXCode39Reader ()

@property (nonatomic, assign) BOOL extendedMode;
@property (nonatomic, assign) BOOL usingCheckDigit;

@end

@implementation ZXCode39Reader

/**
 * Creates a reader that assumes all encoded data is data, and does not treat the final
 * character as a check digit. It will not decoded "extended Code 39" sequences.
 */
- (id)init {
  return [self initUsingCheckDigit:NO extendedMode:NO];
}


/**
 * Creates a reader that can be configured to check the last character as a check digit.
 * It will not decoded "extended Code 39" sequences.
 */
- (id)initUsingCheckDigit:(BOOL)isUsingCheckDigit {  
  return [self initUsingCheckDigit:isUsingCheckDigit extendedMode:NO];
}


/**
 * Creates a reader that can be configured to check the last character as a check digit,
 * or optionally attempt to decode "extended Code 39" sequences that are used to encode
 * the full ASCII character set.
 */
- (id)initUsingCheckDigit:(BOOL)usingCheckDigit extendedMode:(BOOL)extendedMode {
  if (self = [super init]) {
    _usingCheckDigit = usingCheckDigit;
    _extendedMode = extendedMode;
  }

  return self;
}

- (ZXResult *)decodeRow:(int)rowNumber row:(ZXBitArray *)row hints:(ZXDecodeHints *)hints error:(NSError **)error {
  const int countersLen = 9;
  int counters[countersLen];
  memset(counters, 0, countersLen * sizeof(int));

  int start[2] = {0};
  if (![self findAsteriskPattern:row a:&start[0] b:&start[1] counters:counters countersLen:countersLen]) {
    if (error) *error = NotFoundErrorInstance();
    return nil;
  }
  // Read off white space
  int nextStart = [row nextSet:start[1]];
  int end = [row size];

  NSMutableString *result = [NSMutableString stringWithCapacity:20];
  unichar decodedChar;
  int lastStart;
  do {
    if (![ZXOneDReader recordPattern:row start:nextStart counters:counters countersSize:countersLen]) {
      if (error) *error = NotFoundErrorInstance();
      return nil;
    }
    int pattern = [self toNarrowWidePattern:(int *)counters countersLen:countersLen];
    if (pattern < 0) {
      if (error) *error = NotFoundErrorInstance();
      return nil;
    }
    decodedChar = [self patternToChar:pattern];
    if (decodedChar == 0) {
      if (error) *error = NotFoundErrorInstance();
      return nil;
    }
    [result appendFormat:@"%C", decodedChar];
    lastStart = nextStart;
    for (int i = 0; i < sizeof(counters) / sizeof(int); i++) {
      nextStart += counters[i];
    }
    // Read off white space
    nextStart = [row nextSet:nextStart];
  } while (decodedChar != '*');
  [result deleteCharactersInRange:NSMakeRange([result length] - 1, 1)];

  int lastPatternSize = 0;
  for (int i = 0; i < sizeof(counters) / sizeof(int); i++) {
    lastPatternSize += counters[i];
  }
  int whiteSpaceAfterEnd = nextStart - lastStart - lastPatternSize;
  if (nextStart != end && (whiteSpaceAfterEnd >> 1) < lastPatternSize) {
    if (error) *error = NotFoundErrorInstance();
    return nil;
  }

  if (self.usingCheckDigit) {
    int max = (int)[result length] - 1;
    int total = 0;
    for (int i = 0; i < max; i++) {
      total += [CODE39_ALPHABET_STRING rangeOfString:[result substringWithRange:NSMakeRange(i, 1)]].location;
    }
    if ([result characterAtIndex:max] != CODE39_ALPHABET[total % 43]) {
      if (error) *error = ChecksumErrorInstance();
      return nil;
    }
    [result deleteCharactersInRange:NSMakeRange(max, 1)];
  }

  if ([result length] == 0) {
    // false positive
    if (error) *error = NotFoundErrorInstance();
    return nil;
  }

  NSString *resultString;
  if (self.extendedMode) {
    resultString = [self decodeExtended:result];
    if (!resultString) {
      if (error) *error = FormatErrorInstance();
      return nil;
    }
  } else {
    resultString = result;
  }

  float left = (float) (start[1] + start[0]) / 2.0f;
  float right = (float)(nextStart + lastStart) / 2.0f;

  return [ZXResult resultWithText:resultString
                         rawBytes:nil
                           length:0
                     resultPoints:@[[[ZXResultPoint alloc] initWithX:left y:(float)rowNumber],
                                   [[ZXResultPoint alloc] initWithX:right y:(float)rowNumber]]
                           format:kBarcodeFormatCode39];
}

- (BOOL)findAsteriskPattern:(ZXBitArray *)row a:(int *)a b:(int *)b counters:(int *)counters countersLen:(int)countersLen {
  int width = row.size;
  int rowOffset = [row nextSet:0];

  int counterPosition = 0;
  int patternStart = rowOffset;
  BOOL isWhite = NO;

  for (int i = rowOffset; i < width; i++) {
    if ([row get:i] ^ isWhite) {
      counters[counterPosition]++;
    } else {
      if (counterPosition == countersLen - 1) {
        if ([self toNarrowWidePattern:counters countersLen:countersLen] == CODE39_ASTERISK_ENCODING &&
            [row isRange:MAX(0, patternStart - ((i - patternStart) >> 1)) end:patternStart value:NO]) {
          if (a) *a = patternStart;
          if (b) *b = i;
          return YES;
        }
        patternStart += counters[0] + counters[1];
        for (int y = 2; y < countersLen; y++) {
          counters[y - 2] = counters[y];
        }
        counters[countersLen - 2] = 0;
        counters[countersLen - 1] = 0;
        counterPosition--;
      } else {
        counterPosition++;
      }
      counters[counterPosition] = 1;
      isWhite = !isWhite;
    }
  }

  return NO;
}

- (int)toNarrowWidePattern:(int *)counters countersLen:(unsigned int)countersLen {
  int numCounters = countersLen;
  int maxNarrowCounter = 0;
  int wideCounters;
  do {
    int minCounter = INT_MAX;
    for (int i = 0; i < numCounters; i++) {
      int counter = counters[i];
      if (counter < minCounter && counter > maxNarrowCounter) {
        minCounter = counter;
      }
    }
    maxNarrowCounter = minCounter;
    wideCounters = 0;
    int totalWideCountersWidth = 0;
    int pattern = 0;
    for (int i = 0; i < numCounters; i++) {
      int counter = counters[i];
      if (counters[i] > maxNarrowCounter) {
        pattern |= 1 << (numCounters - 1 - i);
        wideCounters++;
        totalWideCountersWidth += counter;
      }
    }
    if (wideCounters == 3) {
      for (int i = 0; i < numCounters && wideCounters > 0; i++) {
        int counter = counters[i];
        if (counters[i] > maxNarrowCounter) {
          wideCounters--;
          if ((counter << 1) >= totalWideCountersWidth) {
            return -1;
          }
        }
      }
      return pattern;
    }
  } while (wideCounters > 3);
  return -1;
}

- (unichar)patternToChar:(int)pattern {
  for (int i = 0; i < sizeof(CODE39_CHARACTER_ENCODINGS) / sizeof(int); i++) {
    if (CODE39_CHARACTER_ENCODINGS[i] == pattern) {
      return CODE39_ALPHABET[i];
    }
  }
  return 0;
}

- (NSString *)decodeExtended:(NSMutableString *)encoded {
  NSUInteger length = [encoded length];
  NSMutableString *decoded = [NSMutableString stringWithCapacity:length];

  for (int i = 0; i < length; i++) {
    unichar c = [encoded characterAtIndex:i];
    if (c == '+' || c == '$' || c == '%' || c == '/') {
      unichar next = [encoded characterAtIndex:i + 1];
      unichar decodedChar = '\0';

      switch (c) {
      case '+':
        if (next >= 'A' && next <= 'Z') {
          decodedChar = (unichar)(next + 32);
        } else {
          return nil;
        }
        break;
      case '$':
        if (next >= 'A' && next <= 'Z') {
          decodedChar = (unichar)(next - 64);
        } else {
          return nil;
        }
        break;
      case '%':
        if (next >= 'A' && next <= 'E') {
          decodedChar = (unichar)(next - 38);
        } else if (next >= 'F' && next <= 'W') {
          decodedChar = (unichar)(next - 11);
        } else {
          return nil;
        }
        break;
      case '/':
        if (next >= 'A' && next <= 'O') {
          decodedChar = (unichar)(next - 32);
        } else if (next == 'Z') {
          decodedChar = ':';
        } else {
          return nil;
        }
        break;
      }
      [decoded appendFormat:@"%C", decodedChar];
      i++;
    } else {
      [decoded appendFormat:@"%C", c];
    }
  }

  return decoded;
}

@end
