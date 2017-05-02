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
#import "ZXDecodeHints.h"
#import "ZXDecoderResult.h"
#import "ZXErrors.h"
#import "ZXGenericGF.h"
#import "ZXMaxiCodeBitMatrixParser.h"
#import "ZXMaxiCodeDecodedBitStreamParser.h"
#import "ZXMaxiCodeDecoder.h"
#import "ZXReedSolomonDecoder.h"

const int ALL = 0;
const int EVEN = 1;
const int ODD = 2;

@interface ZXMaxiCodeDecoder ()

@property (nonatomic, strong) ZXReedSolomonDecoder *rsDecoder;

@end

@implementation ZXMaxiCodeDecoder

- (id)init {
  if (self = [super init]) {
    _rsDecoder = [[ZXReedSolomonDecoder alloc] initWithField:[ZXGenericGF MaxiCodeField64]];
  }

  return self;
}

- (ZXDecoderResult *)decode:(ZXBitMatrix *)bits error:(NSError **)error {
  return [self decode:bits hints:nil error:error];
}

- (ZXDecoderResult *)decode:(ZXBitMatrix *)bits hints:(ZXDecodeHints *)hints error:(NSError **)error {
  ZXMaxiCodeBitMatrixParser *parser = [[ZXMaxiCodeBitMatrixParser alloc] initWithBitMatrix:bits error:error];
  if (!parser) {
    return nil;
  }
  NSMutableArray *codewords = [[parser readCodewords] mutableCopy];

  if (![self correctErrors:codewords start:0 dataCodewords:10 ecCodewords:10 mode:ALL error:error]) {
    return nil;
  }
  int mode = [codewords[0] charValue] & 0x0F;
  int datawordsLen;
  switch (mode) {
    case 2:
    case 3:
    case 4:
      if (![self correctErrors:codewords start:20 dataCodewords:84 ecCodewords:40 mode:EVEN error:error]) {
        return nil;
      }
      if (![self correctErrors:codewords start:20 dataCodewords:84 ecCodewords:40 mode:ODD error:error]) {
        return nil;
      }
      datawordsLen = 94;
      break;
    case 5:
      if (![self correctErrors:codewords start:20 dataCodewords:68 ecCodewords:56 mode:EVEN error:error]) {
        return nil;
      }
      if (![self correctErrors:codewords start:20 dataCodewords:68 ecCodewords:56 mode:ODD error:error]) {
        return nil;
      }
      datawordsLen = 78;
      break;
    default:
      if (error) *error = NotFoundErrorInstance();
      return nil;
  }

  int8_t *datawords = (int8_t *)malloc(datawordsLen * sizeof(int8_t));
  for (int i = 0; i < 10; i++) {
    datawords[i] = [codewords[i] charValue];
  }
  for (int i = 20; i < datawordsLen + 10; i++) {
    datawords[i - 10] = [codewords[i] charValue];
  }

  ZXDecoderResult *result = [ZXMaxiCodeDecodedBitStreamParser decode:datawords length:datawordsLen mode:mode];
  free(datawords);
  return result;
}

- (BOOL)correctErrors:(NSMutableArray *)codewordBytes start:(int)start dataCodewords:(int)dataCodewords
          ecCodewords:(int)ecCodewords mode:(int)mode error:(NSError **)error {
  int codewords = dataCodewords + ecCodewords;

  // in EVEN or ODD mode only half the codewords
  int divisor = mode == ALL ? 1 : 2;

  // First read into an array of ints
  int codewordsIntsLen = codewords / divisor;
  int *codewordsInts = (int *)malloc(codewordsIntsLen * sizeof(int));
  memset(codewordsInts, 0, codewordsIntsLen * sizeof(int));
  for (int i = 0; i < codewords; i++) {
    if ((mode == ALL) || (i % 2 == (mode - 1))) {
      codewordsInts[i / divisor] = [codewordBytes[i + start] charValue] & 0xFF;
    }
  }

  NSError *decodeError = nil;
  if (![self.rsDecoder decode:codewordsInts receivedLen:codewordsIntsLen twoS:ecCodewords / divisor error:&decodeError]) {
    if (decodeError.code == ZXReedSolomonError && error) {
      *error = ChecksumErrorInstance();
    }
    return NO;
  }
  // Copy back into array of bytes -- only need to worry about the bytes that were data
  // We don't care about errors in the error-correction codewords
  for (int i = 0; i < dataCodewords; i++) {
    if ((mode == ALL) || (i % 2 == (mode - 1))) {
      codewordBytes[i + start] = [NSNumber numberWithChar:codewordsInts[i / divisor]];
    }
  }

  return YES;
}

@end
