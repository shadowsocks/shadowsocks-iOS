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

#import "ZXModulusGF.h"
#import "ZXModulusPoly.h"
#import "ZXPDF417Common.h"

@interface ZXModulusGF ()

@property (nonatomic, strong) NSMutableArray *expTable;
@property (nonatomic, strong) NSMutableArray *logTable;
@property (nonatomic, assign) int modulus;

@end

@implementation ZXModulusGF

+ (ZXModulusGF *)PDF417_GF {
  return [[ZXModulusGF alloc] initWithModulus:ZXPDF417_NUMBER_OF_CODEWORDS generator:3];
}

- (id)initWithModulus:(int)modulus generator:(int)generator {
  if (self = [super init]) {
    _modulus = modulus;
    _expTable = [NSMutableArray arrayWithCapacity:self.modulus];
    _logTable = [NSMutableArray arrayWithCapacity:self.modulus];
    int x = 1;
    for (int i = 0; i < modulus; i++) {
      [_expTable addObject:@(x)];
      x = (x * generator) % modulus;
    }

    for (int i = 0; i < self.size; i++) {
      [_logTable addObject:@0];
    }

    for (int i = 0; i < self.size - 1; i++) {
      _logTable[[_expTable[i] intValue]] = @(i);
    }
    // logTable[0] == 0 but this should never be used
    int zeroInt = 0;
    _zero = [[ZXModulusPoly alloc] initWithField:self coefficients:&zeroInt coefficientsLen:1];

    int oneInt = 1;
    _one = [[ZXModulusPoly alloc] initWithField:self coefficients:&oneInt coefficientsLen:1];
  }

  return self;
}

- (ZXModulusPoly *)buildMonomial:(int)degree coefficient:(int)coefficient {
  if (degree < 0) {
    [NSException raise:NSInvalidArgumentException format:@"Degree must be greater than 0."];
  }
  if (coefficient == 0) {
    return self.zero;
  }

  int coefficientsLen = degree + 1;
  int coefficients[coefficientsLen];
  coefficients[0] = coefficient;
  for (int i = 1; i < coefficientsLen; i++) {
    coefficients[i] = 0;
  }
  return [[ZXModulusPoly alloc] initWithField:self coefficients:coefficients coefficientsLen:coefficientsLen];
}

- (int)add:(int)a b:(int)b {
  return (a + b) % self.modulus;
}

- (int)subtract:(int)a b:(int)b {
  return (self.modulus + a - b) % self.modulus;
}

- (int)exp:(int)a {
  return [self.expTable[a] intValue];
}

- (int)log:(int)a {
  if (a == 0) {
    [NSException raise:NSInvalidArgumentException format:@"Argument must be non-zero."];
  }
  return [self.logTable[a] intValue];
}

- (int)inverse:(int)a {
  if (a == 0) {
    [NSException raise:NSInvalidArgumentException format:@"Argument must be non-zero."];
  }
  return [self.expTable[self.size - [self.logTable[a] intValue] - 1] intValue];
}

- (int)multiply:(int)a b:(int)b {
  if (a == 0 || b == 0) {
    return 0;
  }

  int logSum = [self.logTable[a] intValue] + [self.logTable[b] intValue];
  return [self.expTable[logSum % (self.modulus - 1)] intValue];
}

- (int)size {
  return self.modulus;
}

@end
