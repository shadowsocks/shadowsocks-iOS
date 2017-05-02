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
#import "ZXPDF417ECErrorCorrection.h"

@interface ZXPDF417ECErrorCorrection ()

@property (nonatomic, strong) ZXModulusGF *field;

@end

@implementation ZXPDF417ECErrorCorrection

- (id)init {
  if (self = [super init]) {
    _field = [ZXModulusGF PDF417_GF];
  }

  return self;
}

- (int)decode:(NSMutableArray *)received numECCodewords:(int)numECCodewords erasures:(NSArray *)erasures {
  int coefficients[received.count];
  for (int i = 0; i < received.count; i++) {
    coefficients[i] = [received[i] intValue];
  }
  ZXModulusPoly *poly = [[ZXModulusPoly alloc] initWithField:self.field coefficients:coefficients coefficientsLen:(int)received.count];

  int S[numECCodewords];
  for (int i = 0; i < numECCodewords; i++) {
    S[i] = 0;
  }

  BOOL error = NO;
  for (int i = numECCodewords; i > 0; i--) {
    int eval = [poly evaluateAt:[self.field exp:i]];
    S[numECCodewords - i] = eval;
    if (eval != 0) {
      error = YES;
    }
  }

  if (!error) {
    return 0;
  }

  ZXModulusPoly *knownErrors = self.field.one;
  for (NSNumber *erasure in erasures) {
    int b = [self.field exp:(int)received.count - 1 - [erasure intValue]];
    // Add (1 - bx) term:
    int termCoefficients[2] = { [self.field subtract:0 b:b], 1 };
    ZXModulusPoly *term = [[ZXModulusPoly alloc] initWithField:self.field coefficients:termCoefficients coefficientsLen:2];
    knownErrors = [knownErrors multiply:term];
  }

  ZXModulusPoly *syndrome = [[ZXModulusPoly alloc] initWithField:self.field coefficients:S coefficientsLen:numECCodewords];
  //[syndrome multiply:knownErrors];

  NSArray *sigmaOmega = [self runEuclideanAlgorithm:[self.field buildMonomial:numECCodewords coefficient:1] b:syndrome R:numECCodewords];
  if (!sigmaOmega) {
    return -1;
  }

  ZXModulusPoly *sigma = sigmaOmega[0];
  ZXModulusPoly *omega = sigmaOmega[1];

  //sigma = [sigma multiply:knownErrors];

  NSArray *errorLocations = [self findErrorLocations:sigma];
  if (!errorLocations) return NO;
  NSArray *errorMagnitudes = [self findErrorMagnitudes:omega errorLocator:sigma errorLocations:errorLocations];

  for (int i = 0; i < [errorLocations count]; i++) {
    int position = (int)received.count - 1 - [self.field log:[errorLocations[i] intValue]];
    if (position < 0) {
      return -1;
    }
    received[position] = @([self.field subtract:[received[position] intValue]
                                              b:[errorMagnitudes[i] intValue]]);
  }

  return (int)[errorLocations count];
}

- (NSArray *)runEuclideanAlgorithm:(ZXModulusPoly *)a b:(ZXModulusPoly *)b R:(int)R {
  // Assume a's degree is >= b's
  if (a.degree < b.degree) {
    ZXModulusPoly *temp = a;
    a = b;
    b = temp;
  }

  ZXModulusPoly *rLast = a;
  ZXModulusPoly *r = b;
  ZXModulusPoly *tLast = self.field.zero;
  ZXModulusPoly *t = self.field.one;

  // Run Euclidean algorithm until r's degree is less than R/2
  while (r.degree >= R / 2) {
    ZXModulusPoly *rLastLast = rLast;
    ZXModulusPoly *tLastLast = tLast;
    rLast = r;
    tLast = t;

    // Divide rLastLast by rLast, with quotient in q and remainder in r
    if (rLast.zero) {
      // Oops, Euclidean algorithm already terminated?
      return nil;
    }
    r = rLastLast;
    ZXModulusPoly *q = self.field.zero;
    int denominatorLeadingTerm = [rLast coefficient:rLast.degree];
    int dltInverse = [self.field inverse:denominatorLeadingTerm];
    while (r.degree >= rLast.degree && !r.zero) {
      int degreeDiff = r.degree - rLast.degree;
      int scale = [self.field multiply:[r coefficient:r.degree] b:dltInverse];
      q = [q add:[self.field buildMonomial:degreeDiff coefficient:scale]];
      r = [r subtract:[rLast multiplyByMonomial:degreeDiff coefficient:scale]];
    }

    t = [[[q multiply:tLast] subtract:tLastLast] negative];
  }

  int sigmaTildeAtZero = [t coefficient:0];
  if (sigmaTildeAtZero == 0) {
    return nil;
  }

  int inverse = [self.field inverse:sigmaTildeAtZero];
  ZXModulusPoly *sigma = [t multiplyScalar:inverse];
  ZXModulusPoly *omega = [r multiplyScalar:inverse];
  return @[sigma, omega];
}

- (NSArray *)findErrorLocations:(ZXModulusPoly *)errorLocator {
  // This is a direct application of Chien's search
  int numErrors = errorLocator.degree;
  NSMutableArray *result = [NSMutableArray arrayWithCapacity:numErrors];
  for (int i = 1; i < self.field.size && result.count < numErrors; i++) {
    if ([errorLocator evaluateAt:i] == 0) {
      [result addObject:@([self.field inverse:i])];
    }
  }
  if (result.count != numErrors) {
    return nil;
  }
  return result;
}

- (NSArray *)findErrorMagnitudes:(ZXModulusPoly *)errorEvaluator errorLocator:(ZXModulusPoly *)errorLocator errorLocations:(NSArray *)errorLocations {
  int errorLocatorDegree = errorLocator.degree;
  int formalDerivativeCoefficients[errorLocatorDegree];
  for (int i = 0; i < errorLocatorDegree; i++) {
    formalDerivativeCoefficients[i] = 0;
  }

  for (int i = 1; i <= errorLocatorDegree; i++) {
    formalDerivativeCoefficients[errorLocatorDegree - i] =
      [self.field multiply:i b:[errorLocator coefficient:i]];
  }
  ZXModulusPoly *formalDerivative = [[ZXModulusPoly alloc] initWithField:self.field coefficients:formalDerivativeCoefficients coefficientsLen:errorLocatorDegree];

  // This is directly applying Forney's Formula
  int s = (int)errorLocations.count;
  NSMutableArray *result = [NSMutableArray arrayWithCapacity:s];
  for (int i = 0; i < s; i++) {
    int xiInverse = [self.field inverse:[errorLocations[i] intValue]];
    int numerator = [self.field subtract:0 b:[errorEvaluator evaluateAt:xiInverse]];
    int denominator = [self.field inverse:[formalDerivative evaluateAt:xiInverse]];
    [result addObject:@([self.field multiply:numerator b:denominator])];
  }
  return result;
}

@end
