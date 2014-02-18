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

#import "ZXDataMatrixDataBlock.h"
#import "ZXDataMatrixVersion.h"
#import "ZXQRCodeVersion.h"

@implementation ZXDataMatrixDataBlock

- (id)initWithNumDataCodewords:(int)numDataCodewords codewords:(NSMutableArray *)codewords {
  if (self = [super init]) {
    _numDataCodewords = numDataCodewords;
    _codewords = codewords;
  }

  return self;
}

/**
 * When Data Matrix Codes use multiple data blocks, they actually interleave the bytes of each of them.
 * That is, the first byte of data block 1 to n is written, then the second bytes, and so on. This
 * method will separate the data into original blocks.
 */
+ (NSArray *)dataBlocks:(NSArray *)rawCodewords version:(ZXDataMatrixVersion *)version {
  ZXDataMatrixECBlocks *ecBlocks = version.ecBlocks;

  int totalBlocks = 0;
  NSArray *ecBlockArray = ecBlocks.ecBlocks;
  for (ZXDataMatrixECB *ecBlock in ecBlockArray) {
    totalBlocks += ecBlock.count;
  }

  NSMutableArray *result = [NSMutableArray arrayWithCapacity:totalBlocks];
  int numResultBlocks = 0;
  for (ZXDataMatrixECB *ecBlock in ecBlockArray) {
    for (int i = 0; i < ecBlock.count; i++) {
      int numDataCodewords = ecBlock.dataCodewords;
      int numBlockCodewords = ecBlocks.ecCodewords + numDataCodewords;
      NSMutableArray *tempCodewords = [NSMutableArray arrayWithCapacity:numBlockCodewords];
      for (int j = 0; j < numBlockCodewords; j++) {
        [tempCodewords addObject:@0];
      }
      [result addObject:[[ZXDataMatrixDataBlock alloc] initWithNumDataCodewords:numDataCodewords codewords:tempCodewords]];
      numResultBlocks++;
    }
  }

  int longerBlocksTotalCodewords = (int)[[result[0] codewords] count];
  int longerBlocksNumDataCodewords = longerBlocksTotalCodewords - ecBlocks.ecCodewords;
  int shorterBlocksNumDataCodewords = longerBlocksNumDataCodewords - 1;
  int rawCodewordsOffset = 0;
  for (int i = 0; i < shorterBlocksNumDataCodewords; i++) {
    for (int j = 0; j < numResultBlocks; j++) {
      [result[j] codewords][i] = rawCodewords[rawCodewordsOffset++];
    }
  }

  BOOL specialVersion = version.versionNumber == 24;
  int numLongerBlocks = specialVersion ? 8 : numResultBlocks;
  for (int j = 0; j < numLongerBlocks; j++) {
    [result[j] codewords][longerBlocksNumDataCodewords - 1] = rawCodewords[rawCodewordsOffset++];
  }

  NSUInteger max = [[result[0] codewords] count];
  for (int i = longerBlocksNumDataCodewords; i < max; i++) {
    for (int j = 0; j < numResultBlocks; j++) {
      int iOffset = specialVersion && j > 7 ? i - 1 : i;
      [result[j] codewords][iOffset] = rawCodewords[rawCodewordsOffset++];
    }
  }

  if (rawCodewordsOffset != [rawCodewords count]) {
    [NSException raise:NSInvalidArgumentException format:@"Codewords size mismatch"];
  }
  return result;
}

@end
