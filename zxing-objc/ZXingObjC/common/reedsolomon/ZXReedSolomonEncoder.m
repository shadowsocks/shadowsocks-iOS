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

#import "ZXGenericGF.h"
#import "ZXGenericGFPoly.h"
#import "ZXReedSolomonEncoder.h"

@interface ZXReedSolomonEncoder ()

@property (nonatomic, strong) NSMutableArray *cachedGenerators;
@property (nonatomic, strong) ZXGenericGF *field;

@end

@implementation ZXReedSolomonEncoder

- (id)initWithField:(ZXGenericGF *)field {
  if (self = [super init]) {
    _field = field;
    int one = 1;
    _cachedGenerators = [NSMutableArray arrayWithObject:[[ZXGenericGFPoly alloc] initWithField:field coefficients:&one coefficientsLen:1]];
  }

  return self;
}

- (ZXGenericGFPoly *)buildGenerator:(int)degree {
  if (degree >= self.cachedGenerators.count) {
    ZXGenericGFPoly *lastGenerator = self.cachedGenerators[[self.cachedGenerators count] - 1];
    for (NSUInteger d = [self.cachedGenerators count]; d <= degree; d++) {
      int next[2] = { 1, [self.field exp:(int)d - 1 + self.field.generatorBase] };
      ZXGenericGFPoly *nextGenerator = [lastGenerator multiply:[[ZXGenericGFPoly alloc] initWithField:self.field coefficients:next coefficientsLen:2]];
      [self.cachedGenerators addObject:nextGenerator];
      lastGenerator = nextGenerator;
    }
  }

  return (ZXGenericGFPoly *)self.cachedGenerators[degree];
}

- (void)encode:(int *)toEncode toEncodeLen:(int)toEncodeLen ecBytes:(int)ecBytes {
  if (ecBytes == 0) {
    @throw [NSException exceptionWithName:NSInvalidArgumentException
                                   reason:@"No error correction bytes"
                                 userInfo:nil];
  }
  int dataBytes = toEncodeLen - ecBytes;
  if (dataBytes <= 0) {
    @throw [NSException exceptionWithName:NSInvalidArgumentException
                                   reason:@"No data bytes provided"
                                 userInfo:nil];
  }
  ZXGenericGFPoly *generator = [self buildGenerator:ecBytes];
  int infoCoefficients[dataBytes];
  for (int i = 0; i < dataBytes; i++) {
    infoCoefficients[i] = toEncode[i];
  }
  ZXGenericGFPoly *info = [[ZXGenericGFPoly alloc] initWithField:self.field coefficients:infoCoefficients coefficientsLen:dataBytes];
  info = [info multiplyByMonomial:ecBytes coefficient:1];
  ZXGenericGFPoly *remainder = [info divide:generator][1];
  int *coefficients = remainder.coefficients;
  int coefficientsLen = remainder.coefficientsLen;
  int numZeroCoefficients = ecBytes - coefficientsLen;
  for (int i = 0; i < numZeroCoefficients; i++) {
    toEncode[dataBytes + i] = 0;
  }
  for (int i = 0; i < coefficientsLen; i++) {
    toEncode[dataBytes + numZeroCoefficients + i] = coefficients[i];
  }
}

@end
