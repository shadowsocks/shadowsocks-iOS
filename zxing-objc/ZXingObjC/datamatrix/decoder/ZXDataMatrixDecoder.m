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
#import "ZXDataMatrixBitMatrixParser.h"
#import "ZXDataMatrixDataBlock.h"
#import "ZXDataMatrixDecodedBitStreamParser.h"
#import "ZXDataMatrixDecoder.h"
#import "ZXDataMatrixVersion.h"
#import "ZXDecoderResult.h"
#import "ZXErrors.h"
#import "ZXGenericGF.h"
#import "ZXReedSolomonDecoder.h"

@interface ZXDataMatrixDecoder ()

@property (nonatomic, strong) ZXReedSolomonDecoder *rsDecoder;

@end

@implementation ZXDataMatrixDecoder

- (id)init {
  if (self = [super init]) {
    _rsDecoder = [[ZXReedSolomonDecoder alloc] initWithField:[ZXGenericGF DataMatrixField256]];
  }

  return self;
}

/**
 * Convenience method that can decode a Data Matrix Code represented as a 2D array of booleans.
 * "true" is taken to mean a black module.
 */
- (ZXDecoderResult *)decode:(BOOL **)image length:(unsigned int)length error:(NSError **)error {
  int dimension = length;
  ZXBitMatrix *bits = [[ZXBitMatrix alloc] initWithDimension:dimension];
  for (int i = 0; i < dimension; i++) {
    for (int j = 0; j < dimension; j++) {
      if (image[i][j]) {
        [bits setX:j y:i];
      }
    }
  }

  return [self decodeMatrix:bits error:error];
}


/**
 * Decodes a Data Matrix Code represented as a BitMatrix. A 1 or "true" is taken
 * to mean a black module.
 */
- (ZXDecoderResult *)decodeMatrix:(ZXBitMatrix *)bits error:(NSError **)error {
  ZXDataMatrixBitMatrixParser *parser = [[ZXDataMatrixBitMatrixParser alloc] initWithBitMatrix:bits error:error];
  if (!parser) {
    return nil;
  }
  ZXDataMatrixVersion *version = [parser version];

  NSArray *codewords = [parser readCodewords];
  NSArray *dataBlocks = [ZXDataMatrixDataBlock dataBlocks:codewords version:version];

  NSUInteger dataBlocksCount = [dataBlocks count];

  int totalBytes = 0;
  for (int i = 0; i < dataBlocksCount; i++) {
    totalBytes += [dataBlocks[i] numDataCodewords];
  }

  if (totalBytes == 0) {
    return nil;
  }

  int8_t resultBytes[totalBytes];

  for (int j = 0; j < dataBlocksCount; j++) {
    ZXDataMatrixDataBlock *dataBlock = dataBlocks[j];
    NSMutableArray *codewordBytes = dataBlock.codewords;
    int numDataCodewords = [dataBlock numDataCodewords];
    if (![self correctErrors:codewordBytes numDataCodewords:numDataCodewords error:error]) {
      return nil;
    }
    for (int i = 0; i < numDataCodewords; i++) {
      resultBytes[i * dataBlocksCount + j] = [codewordBytes[i] charValue];
    }
  }

  return [ZXDataMatrixDecodedBitStreamParser decode:resultBytes length:totalBytes error:error];
}


/**
 * Given data and error-correction codewords received, possibly corrupted by errors, attempts to
 * correct the errors in-place using Reed-Solomon error correction.
 */
- (BOOL)correctErrors:(NSMutableArray *)codewordBytes numDataCodewords:(int)numDataCodewords error:(NSError **)error {
  int numCodewords = (int)[codewordBytes count];
  int codewordsInts[numCodewords];
  for (int i = 0; i < numCodewords; i++) {
    codewordsInts[i] = [codewordBytes[i] charValue] & 0xFF;
  }
  int numECCodewords = (int)[codewordBytes count] - numDataCodewords;

  NSError *decodeError = nil;
  if (![self.rsDecoder decode:codewordsInts receivedLen:numCodewords twoS:numECCodewords error:&decodeError]) {
    if (decodeError.code == ZXReedSolomonError) {
      if (error) *error = ChecksumErrorInstance();
      return NO;
    } else {
      if (error) *error = decodeError;
      return NO;
    }
  }

  for (int i = 0; i < numDataCodewords; i++) {
    codewordBytes[i] = [NSNumber numberWithChar:codewordsInts[i]];
  }
  return YES;
}

@end
