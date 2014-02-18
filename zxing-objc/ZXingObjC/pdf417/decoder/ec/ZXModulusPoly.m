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

@interface ZXModulusPoly ()

@property (nonatomic, assign) int *coefficients;
@property (nonatomic, assign) int coefficientsLen;
@property (nonatomic, weak) ZXModulusGF *field;

@end

@implementation ZXModulusPoly

- (id)initWithField:(ZXModulusGF *)field coefficients:(int *)coefficients coefficientsLen:(int)coefficientsLen {
  if (self = [super init]) {
    _field = field;
    if (coefficientsLen > 1 && coefficients[0] == 0) {
      // Leading term must be non-zero for anything except the constant polynomial "0"
      int firstNonZero = 1;
      while (firstNonZero < coefficientsLen && coefficients[firstNonZero] == 0) {
        firstNonZero++;
      }
      if (firstNonZero == coefficientsLen) {
        ZXModulusPoly *zero = field.zero;
        _coefficients = (int *)malloc(zero.coefficientsLen * sizeof(int));
        memcpy(_coefficients, zero.coefficients, zero.coefficientsLen * sizeof(int));
      } else {
        _coefficientsLen = (coefficientsLen - firstNonZero);
        _coefficients = (int *)malloc(_coefficientsLen * sizeof(int));
        for (int i = 0; i < _coefficientsLen; i++) {
          _coefficients[i] = coefficients[firstNonZero + i];
        }
      }
    } else {
      _coefficients = (int *)malloc(coefficientsLen * sizeof(int));
      memcpy(_coefficients, coefficients, coefficientsLen * sizeof(int));
      _coefficientsLen = coefficientsLen;
    }
  }

  return self;
}

- (void)dealloc {
  if (_coefficients != NULL) {
    free(_coefficients);
    _coefficients = NULL;
  }
}

- (int)degree {
  return self.coefficientsLen - 1;
}

- (BOOL)zero {
  return self.coefficients[0] == 0;
}

- (int)coefficient:(int)degree {
  return self.coefficients[self.coefficientsLen - 1 - degree];
}

- (int)evaluateAt:(int)a {
  if (a == 0) {
    return [self coefficient:0];
  }
  int size = self.coefficientsLen;
  if (a == 1) {
    // Just the sum of the coefficients
    int result = 0;
    for (int i = 0; i < size; i++) {
      result = [self.field add:result b:self.coefficients[i]];
    }
    return result;
  }
  int result = self.coefficients[0];
  for (int i = 1; i < size; i++) {
    result = [self.field add:[self.field multiply:a b:result] b:self.coefficients[i]];
  }
  return result;
}

- (ZXModulusPoly *)add:(ZXModulusPoly *)other {
  if (![self.field isEqual:other.field]) {
    [NSException raise:NSInvalidArgumentException format:@"ZXModulusPolys do not have same ZXModulusGF field"];
  }
  if (self.zero) {
    return other;
  }
  if (other.zero) {
    return self;
  }

  int *smallerCoefficients = self.coefficients;
  int smallerCoefficientsLen = self.coefficientsLen;
  int *largerCoefficients = other.coefficients;
  int largerCoefficientsLen = other.coefficientsLen;
  if (smallerCoefficientsLen > largerCoefficientsLen) {
    int *temp = smallerCoefficients;
    int tempLen = smallerCoefficientsLen;
    smallerCoefficients = largerCoefficients;
    smallerCoefficientsLen = largerCoefficientsLen;
    largerCoefficients = temp;
    largerCoefficientsLen = tempLen;
  }
  int sumDiff[largerCoefficientsLen];
  memset(sumDiff, 0, largerCoefficientsLen * sizeof(int));
  int lengthDiff = largerCoefficientsLen - smallerCoefficientsLen;
  for (int i = 0; i < lengthDiff; i++) {
    sumDiff[i] = largerCoefficients[i];
  }
  for (int i = lengthDiff; i < largerCoefficientsLen; i++) {
    sumDiff[i] = [self.field add:smallerCoefficients[i - lengthDiff] b:largerCoefficients[i]];
  }

  return [[ZXModulusPoly alloc] initWithField:self.field coefficients:sumDiff coefficientsLen:largerCoefficientsLen];
}

- (ZXModulusPoly *)subtract:(ZXModulusPoly *)other {
  if (![self.field isEqual:other.field]) {
    [NSException raise:NSInvalidArgumentException format:@"ZXModulusPolys do not have same ZXModulusGF field"];
  }
  if (self.zero) {
    return self;
  }
  return [self add:[other negative]];
}

- (ZXModulusPoly *)multiply:(ZXModulusPoly *)other {
  if (![self.field isEqual:other.field]) {
    [NSException raise:NSInvalidArgumentException format:@"ZXModulusPolys do not have same ZXModulusGF field"];
  }
  if (self.zero || other.zero) {
    return self.field.zero;
  }
  int *aCoefficients = self.coefficients;
  int aLength = self.coefficientsLen;
  int *bCoefficients = other.coefficients;
  int bLength = other.coefficientsLen;
  int productLen = aLength + bLength - 1;
  int product[productLen];
  memset(product, 0, productLen * sizeof(int));

  for (int i = 0; i < aLength; i++) {
    int aCoeff = aCoefficients[i];
    for (int j = 0; j < bLength; j++) {
      product[i + j] = [self.field add:product[i + j]
                                     b:[self.field multiply:aCoeff b:bCoefficients[j]]];
    }
  }
  return [[ZXModulusPoly alloc] initWithField:self.field coefficients:product coefficientsLen:productLen];
}

- (ZXModulusPoly *)negative {
  int negativeCoefficientsLen = self.coefficientsLen;
  int negativeCoefficients[negativeCoefficientsLen];
  for (int i = 0; i < self.coefficientsLen; i++) {
    negativeCoefficients[i] = [self.field subtract:0 b:self.coefficients[i]];
  }
  return [[ZXModulusPoly alloc] initWithField:self.field coefficients:negativeCoefficients coefficientsLen:negativeCoefficientsLen];
}

- (ZXModulusPoly *)multiplyScalar:(int)scalar {
  if (scalar == 0) {
    return self.field.zero;
  }
  if (scalar == 1) {
    return self;
  }
  int size = self.coefficientsLen;
  int product[size];
  for (int i = 0; i < size; i++) {
    product[i] = [self.field multiply:self.coefficients[i] b:scalar];
  }
  return [[ZXModulusPoly alloc] initWithField:self.field coefficients:product coefficientsLen:size];
}

- (ZXModulusPoly *)multiplyByMonomial:(int)degree coefficient:(int)coefficient {
  if (degree < 0) {
    [NSException raise:NSInvalidArgumentException format:@"Degree must be greater than 0."];
  }
  if (coefficient == 0) {
    return self.field.zero;
  }
  int size = self.coefficientsLen;
  int product[size + degree];
  for (int i = 0; i < size + degree; i++) {
    if (i < size) {
      product[i] = [self.field multiply:self.coefficients[i] b:coefficient];
    } else {
      product[i] = 0;
    }
  }

  return [[ZXModulusPoly alloc] initWithField:self.field coefficients:product coefficientsLen:size + degree];
}

- (NSArray *)divide:(ZXModulusPoly *)other {
  if (![self.field isEqual:other.field]) {
    [NSException raise:NSInvalidArgumentException format:@"ZXModulusPolys do not have same ZXModulusGF field"];
  }
  if (other.zero) {
    [NSException raise:NSInvalidArgumentException format:@"Divide by 0"];
  }

  ZXModulusPoly *quotient = self.field.zero;
  ZXModulusPoly *remainder = self;

  int denominatorLeadingTerm = [other coefficient:other.degree];
  int inverseDenominatorLeadingTerm = [self.field inverse:denominatorLeadingTerm];

  while ([remainder degree] >= other.degree && !remainder.zero) {
    int degreeDifference = remainder.degree - other.degree;
    int scale = [self.field multiply:[remainder coefficient:remainder.degree] b:inverseDenominatorLeadingTerm];
    ZXModulusPoly *term = [other multiplyByMonomial:degreeDifference coefficient:scale];
    ZXModulusPoly *iterationQuotient = [self.field buildMonomial:degreeDifference coefficient:scale];
    quotient = [quotient add:iterationQuotient];
    remainder = [remainder subtract:term];
  }

  return @[quotient, remainder];
}

- (NSString *)description {
  NSMutableString *result = [NSMutableString stringWithCapacity:8 * [self degree]];
  for (int degree = [self degree]; degree >= 0; degree--) {
    int coefficient = [self coefficient:degree];
    if (coefficient != 0) {
      if (coefficient < 0) {
        [result appendString:@" - "];
        coefficient = -coefficient;
      } else {
        if ([result length] > 0) {
          [result appendString:@" + "];
        }
      }
      if (degree == 0 || coefficient != 1) {
        [result appendFormat:@"%d", coefficient];
      }
      if (degree != 0) {
        if (degree == 1) {
          [result appendString:@"x"];
        } else {
          [result appendString:@"x^"];
          [result appendFormat:@"%d", degree];
        }
      }
    }
  }

  return result;
}

@end
