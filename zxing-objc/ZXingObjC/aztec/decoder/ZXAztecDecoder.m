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

#import "ZXAztecDecoder.h"
#import "ZXAztecDetectorResult.h"
#import "ZXBitMatrix.h"
#import "ZXDecoderResult.h"
#import "ZXErrors.h"
#import "ZXGenericGF.h"
#import "ZXReedSolomonDecoder.h"

enum {
  UPPER = 0,
  LOWER,
  MIXED,
  DIGIT,
  PUNCT,
  BINARY
};

static int NB_BITS_COMPACT[] = {
  0, 104, 240, 408, 608
};

static int NB_BITS[] = {
  0, 128, 288, 480, 704, 960, 1248, 1568, 1920, 2304, 2720, 3168, 3648, 4160, 4704, 5280, 5888, 6528,
  7200, 7904, 8640, 9408, 10208, 11040, 11904, 12800, 13728, 14688, 15680, 16704, 17760, 18848, 19968
};

static int NB_DATABLOCK_COMPACT[] = {
  0, 17, 40, 51, 76
};

static int NB_DATABLOCK[] = {
  0, 21, 48, 60, 88, 120, 156, 196, 240, 230, 272, 316, 364, 416, 470, 528, 588, 652, 720, 790, 864,
  940, 1020, 920, 992, 1066, 1144, 1224, 1306, 1392, 1480, 1570, 1664
};

static NSString *UPPER_TABLE[] = {
  @"CTRL_PS", @" ", @"A", @"B", @"C", @"D", @"E", @"F", @"G", @"H", @"I", @"J", @"K", @"L", @"M", @"N", @"O", @"P",
  @"Q", @"R", @"S", @"T", @"U", @"V", @"W", @"X", @"Y", @"Z", @"CTRL_LL", @"CTRL_ML", @"CTRL_DL", @"CTRL_BS"
};

static NSString *LOWER_TABLE[] = {
  @"CTRL_PS", @" ", @"a", @"b", @"c", @"d", @"e", @"f", @"g", @"h", @"i", @"j", @"k", @"l", @"m", @"n", @"o", @"p",
  @"q", @"r", @"s", @"t", @"u", @"v", @"w", @"x", @"y", @"z", @"CTRL_US", @"CTRL_ML", @"CTRL_DL", @"CTRL_BS"
};

static NSString *MIXED_TABLE[] = {
  @"CTRL_PS", @" ", @"\1", @"\2", @"\3", @"\4", @"\5", @"\6", @"\7", @"\b", @"\t", @"\n",
  @"\13", @"\f", @"\r", @"\33", @"\34", @"\35", @"\36", @"\37", @"@", @"\\", @"^", @"_",
  @"`", @"|", @"~", @"\177", @"CTRL_LL", @"CTRL_UL", @"CTRL_PL", @"CTRL_BS"
};

static NSString *PUNCT_TABLE[] = {
  @"", @"\r", @"\r\n", @". ", @", ", @": ", @"!", @"\"", @"#", @"$", @"%", @"&", @"'", @"(", @")",
  @"*", @"+", @",", @"-", @".", @"/", @":", @";", @"<", @"=", @">", @"?", @"[", @"]", @"{", @"}", @"CTRL_UL"
};

static NSString *DIGIT_TABLE[] = {
  @"CTRL_PS", @" ", @"0", @"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @",", @".", @"CTRL_UL", @"CTRL_US"
};

@interface ZXAztecDecoder ()

@property (nonatomic, assign) int codewordSize;
@property (nonatomic, strong) ZXAztecDetectorResult *ddata;
@property (nonatomic, assign) int invertedBitCount;
@property (nonatomic, assign) int numCodewords;

@end

@implementation ZXAztecDecoder

- (ZXDecoderResult *)decode:(ZXAztecDetectorResult *)detectorResult error:(NSError **)error {
  self.ddata = detectorResult;
  ZXBitMatrix *matrix = [detectorResult bits];
  if (![self.ddata compact]) {
    matrix = [self removeDashedLines:[self.ddata bits]];
  }

  BOOL *rawbits;
  NSUInteger rawbitsLength = [self extractBits:matrix pBits:&rawbits];
  if (rawbitsLength == 0) {
    if (error) *error = FormatErrorInstance();
    return nil;
  }

  BOOL *correctedBits;
  NSUInteger correctedBitsLength = [self correctBits:rawbits bitsLength:rawbitsLength pBits:&correctedBits error:error];
  free(rawbits);
  rawbits = NULL;
  if (correctedBitsLength == 0) {
    return nil;
  }

  NSString *result = [self encodedData:correctedBits length:correctedBitsLength error:error];

  free(correctedBits);
  correctedBits = NULL;

  if (!result) {
    return nil;
  }
  return [[ZXDecoderResult alloc] initWithRawBytes:NULL length:0 text:result byteSegments:nil ecLevel:nil];
}


/**
 * 
 * Gets the string encoded in the aztec code bits
 */
- (NSString *)encodedData:(BOOL *)correctedBits length:(NSUInteger)correctedBitsLength error:(NSError **)error {
  int endIndex = self.codewordSize * [self.ddata nbDatablocks] - self.invertedBitCount;
  if (endIndex > correctedBitsLength) {
    if (error) *error = FormatErrorInstance();
    return nil;
  }
  int lastTable = UPPER;
  int table = UPPER;
  int startIndex = 0;
  NSMutableString *result = [NSMutableString stringWithCapacity:20];
  BOOL end = NO;
  BOOL shift = NO;
  BOOL switchShift = NO;
  BOOL binaryShift = NO;

  while (!end) {
    if (shift) {
      switchShift = YES;
    } else {
      lastTable = table;
    }

    int code;
    if (binaryShift) {
      if (endIndex - startIndex < 5) {
        break;
      }

      int length = [self readCode:correctedBits startIndex:startIndex length:5];
      startIndex += 5;
      if (length == 0) {
        if (endIndex - startIndex < 11) {
          break;
        }

        length = [self readCode:correctedBits startIndex:startIndex length:11] + 31;
        startIndex += 11;
      }
      for (int charCount = 0; charCount < length; charCount++) {
        if (endIndex - startIndex < 8) {
          end = true;
          break;
        }

        code = [self readCode:correctedBits startIndex:startIndex length:8];
        unichar uCode = (unichar)code;
        [result appendString:[NSString stringWithCharacters:&uCode length:1]];
        startIndex += 8;
      }
      binaryShift = false;
    } else {
      if (table == BINARY) {
        if (endIndex - startIndex < 8) {
          break;
        }
        code = [self readCode:correctedBits startIndex:startIndex length:8];
        startIndex += 8;

        unichar uCode = (unichar)code;
        [result appendString:[NSString stringWithCharacters:&uCode length:1]];
      } else {
        int size = 5;

        if (table == DIGIT) {
          size = 4;
        }

        if (endIndex - startIndex < size) {
          break;
        }

        code = [self readCode:correctedBits startIndex:startIndex length:size];
        startIndex += size;

        NSString *str = [self character:table code:code];
        if ([str hasPrefix:@"CTRL_"]) {
          // Table changes
          table = [self table:[str characterAtIndex:5]];

          if ([str characterAtIndex:6] == 'S') {
            shift = YES;
            if ([str characterAtIndex:5] == 'B') {
              binaryShift = YES;
            }
          }
        } else {
          [result appendString:str];
        }
      }
    }

    if (switchShift) {
      table = lastTable;
      shift = NO;
      switchShift = NO;
    }
  }

  return result;
}


/**
 * gets the table corresponding to the char passed
 */
- (int)table:(unichar)t {
  int table = UPPER;

  switch (t) {
  case 'U':
    table = UPPER;
    break;
  case 'L':
    table = LOWER;
    break;
  case 'P':
    table = PUNCT;
    break;
  case 'M':
    table = MIXED;
    break;
  case 'D':
    table = DIGIT;
    break;
  case 'B':
    table = BINARY;
    break;
  }
  return table;
}


/**
 * Gets the character (or string) corresponding to the passed code in the given table
 */
- (NSString *)character:(int)table code:(int)code {
  switch (table) {
  case UPPER:
    return UPPER_TABLE[code];
  case LOWER:
    return LOWER_TABLE[code];
  case MIXED:
    return MIXED_TABLE[code];
  case PUNCT:
    return PUNCT_TABLE[code];
  case DIGIT:
    return DIGIT_TABLE[code];
  default:
    return @"";
  }
}


/**
 * Performs RS error correction on an array of bits
 */
- (NSUInteger)correctBits:(BOOL *)rawbits bitsLength:(NSUInteger)rawbitsLength pBits:(BOOL **)pBits error:(NSError **)error {
  ZXGenericGF *gf;
  if ([self.ddata nbLayers] <= 2) {
    self.codewordSize = 6;
    gf = [ZXGenericGF AztecData6];
  } else if ([self.ddata nbLayers] <= 8) {
    self.codewordSize = 8;
    gf = [ZXGenericGF AztecData8];
  } else if ([self.ddata nbLayers] <= 22) {
    self.codewordSize = 10;
    gf = [ZXGenericGF AztecData10];
  } else {
    self.codewordSize = 12;
    gf = [ZXGenericGF AztecData12];
  }

  int numDataCodewords = [self.ddata nbDatablocks];
  int numECCodewords;
  int offset;

  if ([self.ddata compact]) {
    offset = NB_BITS_COMPACT[[self.ddata nbLayers]] - self.numCodewords * self.codewordSize;
    numECCodewords = NB_DATABLOCK_COMPACT[[self.ddata nbLayers]] - numDataCodewords;
  } else {
    offset = NB_BITS[[self.ddata nbLayers]] - self.numCodewords * self.codewordSize;
    numECCodewords = NB_DATABLOCK[[self.ddata nbLayers]] - numDataCodewords;
  }

  int dataWordsLen = self.numCodewords;
  int dataWords[dataWordsLen];
  for (int i = 0; i < dataWordsLen; i++) {
    dataWords[i] = 0;
    int flag = 1;
    for (int j = 1; j <= self.codewordSize; j++) {
      if (rawbits[self.codewordSize * i + self.codewordSize - j + offset]) {
        dataWords[i] += flag;
      }
      flag <<= 1;
    }
  }

  ZXReedSolomonDecoder *rsDecoder = [[ZXReedSolomonDecoder alloc] initWithField:gf];
  NSError *decodeError = nil;
  if (![rsDecoder decode:dataWords receivedLen:dataWordsLen twoS:numECCodewords error:&decodeError]) {
    if (decodeError.code == ZXReedSolomonError) {
      if (error) *error = FormatErrorInstance();
    } else {
      if (error) *error = decodeError;
    }
    return 0;
  }

  offset = 0;
  self.invertedBitCount = 0;

  NSUInteger correctedBitsLength = numDataCodewords * self.codewordSize;
  BOOL *correctedBits = (BOOL *)malloc(correctedBitsLength * sizeof(BOOL));
  memset(correctedBits, NO, correctedBitsLength * sizeof(BOOL));

  for (int i = 0; i < numDataCodewords; i++) {
    BOOL seriesColor = NO;
    int seriesCount = 0;
    int flag = 1 << (self.codewordSize - 1);

    for (int j = 0; j < self.codewordSize; j++) {
      BOOL color = (dataWords[i] & flag) == flag;

      if (seriesCount == self.codewordSize - 1) {
        if (color == seriesColor) {
          if (error) *error = FormatErrorInstance();
          return 0;
        }
        seriesColor = NO;
        seriesCount = 0;
        offset++;
        self.invertedBitCount++;
      } else {
        if (seriesColor == color) {
          seriesCount++;
        } else {
          seriesCount = 1;
          seriesColor = color;
        }

        correctedBits[i * self.codewordSize + j - offset] = color;
      }

      flag = (int)(((NSUInteger)flag) >> 1);
    }
  }

  *pBits = correctedBits;
  return correctedBitsLength;
}


/**
 * Gets the array of bits from an Aztec Code matrix
 */
- (NSUInteger)extractBits:(ZXBitMatrix *)matrix pBits:(BOOL **)pBits {
  NSUInteger rawBitsLength;
  if ([self.ddata compact]) {
    if ([self.ddata nbLayers] > (sizeof(NB_BITS_COMPACT) / sizeof(int))) {
      return 0;
    }
    rawBitsLength = NB_BITS_COMPACT[[self.ddata nbLayers]];
    self.numCodewords = NB_DATABLOCK_COMPACT[[self.ddata nbLayers]];
  } else {
    if ([self.ddata nbLayers] > (sizeof(NB_BITS) / sizeof(int))) {
      return 0;
    }
    rawBitsLength = NB_BITS[[self.ddata nbLayers]];
    self.numCodewords = NB_DATABLOCK[[self.ddata nbLayers]];
  }

  BOOL *rawbits = (BOOL *)malloc(rawBitsLength * sizeof(BOOL));
  memset(rawbits, NO, rawBitsLength * sizeof(BOOL));

  int layer = [self.ddata nbLayers];
  int size = matrix.height;
  int rawbitsOffset = 0;
  int matrixOffset = 0;

  while (layer != 0) {
    int flip = 0;

    for (int i = 0; i < 2 * size - 4; i++) {
      rawbits[rawbitsOffset + i] = [matrix getX:matrixOffset + flip y:matrixOffset + i / 2];

      rawbits[rawbitsOffset + 2 * size - 4 + i] = [matrix getX:matrixOffset + i / 2 y:matrixOffset + size - 1 - flip];

      flip = (flip + 1) % 2;
    }

    flip = 0;
    for (int i = 2 * size + 1; i > 5; i--) {
      rawbits[rawbitsOffset + 4 * size - 8 + (2 * size - i) + 1] =
        [matrix getX:matrixOffset + size - 1 - flip y:matrixOffset + i / 2 - 1];
      rawbits[rawbitsOffset + 6 * size - 12 + (2 * size - i) + 1] =
        [matrix getX:matrixOffset + i / 2 - 1 y:matrixOffset + flip];
      flip = (flip + 1) % 2;
    }

    matrixOffset += 2;
    rawbitsOffset += 8 * size - 16;
    layer--;
    size -= 4;
  }

  *pBits = rawbits;
  return rawBitsLength;
}


/**
 * Transforms an Aztec code matrix by removing the control dashed lines
 */
- (ZXBitMatrix *)removeDashedLines:(ZXBitMatrix *)matrix {
  int nbDashed = 1 + 2 * ((matrix.width - 1) / 2 / 16);
  ZXBitMatrix *newMatrix = [[ZXBitMatrix alloc] initWithWidth:matrix.width - nbDashed height:matrix.height - nbDashed];
  int nx = 0;

  for (int x = 0; x < matrix.width; x++) {
    if ((matrix.width / 2 - x) % 16 == 0) {
      continue;
    }
    int ny = 0;

    for (int y = 0; y < matrix.height; y++) {
      if ((matrix.width / 2 - y) % 16 == 0) {
        continue;
      }
      if ([matrix getX:x y:y]) {
        [newMatrix setX:nx y:ny];
      }
      ny++;
    }

    nx++;
  }

  return newMatrix;
}


/**
 * Reads a code of given length and at given index in an array of bits
 */
- (int)readCode:(BOOL *)rawbits startIndex:(int)startIndex length:(int)length {
  int res = 0;

  for (int i = startIndex; i < startIndex + length; i++) {
    res <<= 1;
    if (rawbits[i]) {
      res++;
    }
  }

  return res;
}

@end
