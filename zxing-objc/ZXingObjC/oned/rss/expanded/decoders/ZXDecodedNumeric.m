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

#import "ZXDecodedNumeric.h"

const int FNC1 = 10;

@implementation ZXDecodedNumeric

- (id)initWithNewPosition:(int)newPosition firstDigit:(int)aFirstDigit secondDigit:(int)aSecondDigit {
  if (self = [super initWithNewPosition:newPosition]) {
    _firstDigit = aFirstDigit;
    _secondDigit = aSecondDigit;

    if (_firstDigit < 0 || _firstDigit > 10) {
      [NSException raise:NSInvalidArgumentException format:@"Invalid firstDigit: %d", _firstDigit];
    }

    if (_secondDigit < 0 || _secondDigit > 10) {
      [NSException raise:NSInvalidArgumentException format:@"Invalid secondDigit: %d", _secondDigit];
    }
  }

  return self;
}

- (int)value {
  return self.firstDigit * 10 + self.secondDigit;
}

- (BOOL)firstDigitFNC1 {
  return self.firstDigit == FNC1;
}

- (BOOL)secondDigitFNC1 {
  return self.secondDigit == FNC1;
}

- (BOOL)anyFNC1 {
  return self.firstDigit == FNC1 || self.secondDigit == FNC1;
}

@end
