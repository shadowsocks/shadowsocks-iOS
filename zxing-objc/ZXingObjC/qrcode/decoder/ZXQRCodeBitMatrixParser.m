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
#import "ZXDataMask.h"
#import "ZXErrors.h"
#import "ZXFormatInformation.h"
#import "ZXQRCodeBitMatrixParser.h"
#import "ZXQRCodeVersion.h"

@interface ZXQRCodeBitMatrixParser ()

@property (nonatomic, strong) ZXBitMatrix *bitMatrix;
@property (nonatomic, strong) ZXFormatInformation *parsedFormatInfo;
@property (nonatomic, strong) ZXQRCodeVersion *parsedVersion;

@end

@implementation ZXQRCodeBitMatrixParser

- (id)initWithBitMatrix:(ZXBitMatrix *)bitMatrix error:(NSError **)error {
  int dimension = bitMatrix.height;
  if (dimension < 21 || (dimension & 0x03) != 1) {
    if (error) *error = FormatErrorInstance();
    return nil;
  }

  if (self = [super init]) {
    _bitMatrix = bitMatrix;
    _parsedFormatInfo = nil;
    _parsedVersion = nil;
  }
  return self;
}

/**
 * Reads format information from one of its two locations within the QR Code.
 */
- (ZXFormatInformation *)readFormatInformationWithError:(NSError **)error {
  if (self.parsedFormatInfo != nil) {
    return self.parsedFormatInfo;
  }
  int formatInfoBits1 = 0;

  for (int i = 0; i < 6; i++) {
    formatInfoBits1 = [self copyBit:i j:8 versionBits:formatInfoBits1];
  }

  formatInfoBits1 = [self copyBit:7 j:8 versionBits:formatInfoBits1];
  formatInfoBits1 = [self copyBit:8 j:8 versionBits:formatInfoBits1];
  formatInfoBits1 = [self copyBit:8 j:7 versionBits:formatInfoBits1];

  for (int j = 5; j >= 0; j--) {
    formatInfoBits1 = [self copyBit:8 j:j versionBits:formatInfoBits1];
  }

  int dimension = self.bitMatrix.height;
  int formatInfoBits2 = 0;
  int jMin = dimension - 7;

  for (int j = dimension - 1; j >= jMin; j--) {
    formatInfoBits2 = [self copyBit:8 j:j versionBits:formatInfoBits2];
  }

  for (int i = dimension - 8; i < dimension; i++) {
    formatInfoBits2 = [self copyBit:i j:8 versionBits:formatInfoBits2];
  }

  self.parsedFormatInfo = [ZXFormatInformation decodeFormatInformation:formatInfoBits1 maskedFormatInfo2:formatInfoBits2];
  if (self.parsedFormatInfo != nil) {
    return self.parsedFormatInfo;
  }
  if (error) *error = FormatErrorInstance();
  return nil;
}


/**
 * Reads version information from one of its two locations within the QR Code.
 */
- (ZXQRCodeVersion *)readVersionWithError:(NSError **)error {
  if (self.parsedVersion != nil) {
    return self.parsedVersion;
  }
  int dimension = self.bitMatrix.height;
  int provisionalVersion = (dimension - 17) >> 2;
  if (provisionalVersion <= 6) {
    return [ZXQRCodeVersion versionForNumber:provisionalVersion];
  }
  int versionBits = 0;
  int ijMin = dimension - 11;

  for (int j = 5; j >= 0; j--) {

    for (int i = dimension - 9; i >= ijMin; i--) {
      versionBits = [self copyBit:i j:j versionBits:versionBits];
    }

  }

  ZXQRCodeVersion *theParsedVersion = [ZXQRCodeVersion decodeVersionInformation:versionBits];
  if (theParsedVersion != nil && theParsedVersion.dimensionForVersion == dimension) {
    self.parsedVersion = theParsedVersion;
    return self.parsedVersion;
  }
  versionBits = 0;

  for (int i = 5; i >= 0; i--) {
    for (int j = dimension - 9; j >= ijMin; j--) {
      versionBits = [self copyBit:i j:j versionBits:versionBits];
    }
  }

  theParsedVersion = [ZXQRCodeVersion decodeVersionInformation:versionBits];
  if (theParsedVersion != nil && theParsedVersion.dimensionForVersion == dimension) {
    self.parsedVersion = theParsedVersion;
    return self.parsedVersion;
  }
  if (error) *error = FormatErrorInstance();
  return nil;
}

- (int)copyBit:(int)i j:(int)j versionBits:(int)versionBits {
  return [self.bitMatrix getX:i y:j] ? (versionBits << 1) | 0x1 : versionBits << 1;
}


/**
 * Reads the bits in the {@link BitMatrix} representing the finder pattern in the
 * correct order in order to reconstitute the codewords bytes contained within the
 * QR Code.
 */
- (NSArray *)readCodewordsWithError:(NSError **)error {
  ZXFormatInformation *formatInfo = [self readFormatInformationWithError:error];
  if (!formatInfo) {
    return nil;
  }

  ZXQRCodeVersion *version = [self readVersionWithError:error];
  if (!version) {
    return nil;
  }

  ZXDataMask *dataMask = [ZXDataMask forReference:(int)[formatInfo dataMask]];
  int dimension = self.bitMatrix.height;
  [dataMask unmaskBitMatrix:self.bitMatrix dimension:dimension];
  ZXBitMatrix *functionPattern = [version buildFunctionPattern];
  BOOL readingUp = YES;
  NSMutableArray *result = [NSMutableArray array];
  int resultOffset = 0;
  int currentByte = 0;
  int bitsRead = 0;

  for (int j = dimension - 1; j > 0; j -= 2) {
    if (j == 6) {
      j--;
    }

    for (int count = 0; count < dimension; count++) {
      int i = readingUp ? dimension - 1 - count : count;

      for (int col = 0; col < 2; col++) {
        if (![functionPattern getX:j - col y:i]) {
          bitsRead++;
          currentByte <<= 1;
          if ([self.bitMatrix getX:j - col y:i]) {
            currentByte |= 1;
          }
          if (bitsRead == 8) {
            [result addObject:@((char)currentByte)];
            resultOffset++;
            bitsRead = 0;
            currentByte = 0;
          }
        }
      }
    }

    readingUp ^= YES;
  }

  if (resultOffset != [version totalCodewords]) {
    if (error) *error = FormatErrorInstance();
    return nil;
  }
  return result;
}

@end
