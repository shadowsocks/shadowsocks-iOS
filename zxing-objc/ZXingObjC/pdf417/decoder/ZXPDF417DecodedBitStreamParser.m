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

#import "ZXDecoderResult.h"
#import "ZXErrors.h"
#import "ZXPDF417DecodedBitStreamParser.h"
#import "ZXPDF417ResultMetadata.h"

enum {
  ALPHA,
  LOWER,
  MIXED,
  PUNCT,
  ALPHA_SHIFT,
  PUNCT_SHIFT
};

int const TEXT_COMPACTION_MODE_LATCH = 900;
int const BYTE_COMPACTION_MODE_LATCH = 901;
int const NUMERIC_COMPACTION_MODE_LATCH = 902;
int const BYTE_COMPACTION_MODE_LATCH_6 = 924;
int const BEGIN_MACRO_PDF417_CONTROL_BLOCK = 928;
int const BEGIN_MACRO_PDF417_OPTIONAL_FIELD = 923;
int const MACRO_PDF417_TERMINATOR = 922;
int const MODE_SHIFT_TO_BYTE_COMPACTION_MODE = 913;
int const MAX_NUMERIC_CODEWORDS = 15;

int const PL = 25;
int const LL = 27;
int const AS = 27;
int const ML = 28;
int const AL = 28;
int const PS = 29;
int const PAL = 29;

char const PUNCT_CHARS[29] = {
  ';', '<', '>', '@', '[', '\\', '}', '_', '`', '~', '!',
  '\r', '\t', ',', ':', '\n', '-', '.', '$', '/', '"', '|', '*',
  '(', ')', '?', '{', '}', '\''};

char const MIXED_CHARS[25] = {
  '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '&',
  '\r', '\t', ',', ':', '#', '-', '.', '$', '/', '+', '%', '*',
  '=', '^'};

int const NUMBER_OF_SEQUENCE_CODEWORDS = 2;

/**
 * Table containing values for the exponent of 900.
 * This is used in the numeric compaction decode algorithm.
 */
static NSArray *EXP900 = nil;

@implementation ZXPDF417DecodedBitStreamParser

+ (void)initialize {
  NSMutableArray *exponents = [NSMutableArray arrayWithCapacity:16];
  [exponents addObject:[NSDecimalNumber one]];
  NSDecimalNumber *nineHundred = [NSDecimalNumber decimalNumberWithString:@"900"];
  [exponents addObject:nineHundred];
  for (int i = 2; i < 16; i++) {
    [exponents addObject:[exponents[i - 1] decimalNumberByMultiplyingBy:nineHundred]];
  }
  EXP900 = [[NSArray alloc] initWithArray:exponents];
}

+ (ZXDecoderResult *)decode:(NSArray *)codewords ecLevel:(NSString *)ecLevel error:(NSError **)error {
  if (!codewords) {
    if (error) *error = NotFoundErrorInstance();
    return nil;
  }
  NSMutableString *result = [NSMutableString stringWithCapacity:codewords.count * 2];
  // Get compaction mode
  int codeIndex = 1;
  int code = [codewords[codeIndex++] intValue];
  ZXPDF417ResultMetadata *resultMetadata = [[ZXPDF417ResultMetadata alloc] init];
  while (codeIndex < [codewords[0] intValue]) {
    switch (code) {
    case TEXT_COMPACTION_MODE_LATCH:
      codeIndex = [self textCompaction:codewords codeIndex:codeIndex result:result];
      break;
    case BYTE_COMPACTION_MODE_LATCH:
      codeIndex = [self byteCompaction:code codewords:codewords codeIndex:codeIndex result:result];
      break;
    case NUMERIC_COMPACTION_MODE_LATCH:
      codeIndex = [self numericCompaction:codewords codeIndex:codeIndex result:result];
      break;
    case MODE_SHIFT_TO_BYTE_COMPACTION_MODE:
      codeIndex = [self byteCompaction:code codewords:codewords codeIndex:codeIndex result:result];
      break;
    case BYTE_COMPACTION_MODE_LATCH_6:
      codeIndex = [self byteCompaction:code codewords:codewords codeIndex:codeIndex result:result];
      break;
    case BEGIN_MACRO_PDF417_CONTROL_BLOCK:
      codeIndex = [self decodeMacroBlock:codewords codeIndex:codeIndex resultMetadata:resultMetadata];
      if (codeIndex < 0) {
        if (error) *error = NotFoundErrorInstance();
        return nil;
      }
      break;
    default:
      // Default to text compaction. During testing numerous barcodes
      // appeared to be missing the starting mode. In these cases defaulting
      // to text compaction seems to work.
      codeIndex--;
      codeIndex = [self textCompaction:codewords codeIndex:codeIndex result:result];
      break;
    }
    if (codeIndex < [codewords count]) {
      code = [codewords[codeIndex++] intValue];
    } else {
      if (error) *error = NotFoundErrorInstance();
      return nil;
    }
  }
  if ([result length] == 0) {
    if (error) *error = NotFoundErrorInstance();
    return nil;
  }
  ZXDecoderResult *decoderResult = [[ZXDecoderResult alloc] initWithRawBytes:NULL length:0 text:result byteSegments:nil ecLevel:ecLevel];
  decoderResult.other = resultMetadata;
  return decoderResult;
}

+ (int)decodeMacroBlock:(NSArray *)codewords codeIndex:(int)codeIndex resultMetadata:(ZXPDF417ResultMetadata *)resultMetadata {
  if (codeIndex + NUMBER_OF_SEQUENCE_CODEWORDS > [codewords[0] intValue]) {
    // we must have at least two bytes left for the segment index
    return -1;
  }
  int segmentIndexArray[NUMBER_OF_SEQUENCE_CODEWORDS];
  memset(segmentIndexArray, 0, NUMBER_OF_SEQUENCE_CODEWORDS * sizeof(int));
  for (int i = 0; i < NUMBER_OF_SEQUENCE_CODEWORDS; i++, codeIndex++) {
    segmentIndexArray[i] = [codewords[codeIndex] intValue];
  }
  resultMetadata.segmentIndex = [[self decodeBase900toBase10:segmentIndexArray count:NUMBER_OF_SEQUENCE_CODEWORDS] intValue];

  NSMutableString *fileId = [NSMutableString string];
  codeIndex = [self textCompaction:codewords codeIndex:codeIndex result:fileId];
  resultMetadata.fileId = [NSString stringWithString:fileId];

  if ([codewords[codeIndex] intValue] == BEGIN_MACRO_PDF417_OPTIONAL_FIELD) {
    codeIndex++;
    NSMutableArray *additionalOptionCodeWords = [NSMutableArray array];

    BOOL end = NO;
    while ((codeIndex < [codewords[0] intValue]) && !end) {
      int code = [codewords[codeIndex++] intValue];
      if (code < TEXT_COMPACTION_MODE_LATCH) {
        [additionalOptionCodeWords addObject:@(code)];
      } else {
        switch (code) {
          case MACRO_PDF417_TERMINATOR:
            resultMetadata.lastSegment = YES;
            codeIndex++;
            end = YES;
            break;
          default:
            return -1;
        }
      }
    }

    resultMetadata.optionalData = additionalOptionCodeWords;
  } else if ([codewords[codeIndex] intValue] == MACRO_PDF417_TERMINATOR) {
    resultMetadata.lastSegment = YES;
    codeIndex++;
  }

  return codeIndex;
}

/**
 * Text Compaction mode (see 5.4.1.5) permits all printable ASCII characters to be
 * encoded, i.e. values 32 - 126 inclusive in accordance with ISO/IEC 646 (IRV), as
 * well as selected control characters.
 */
+ (int)textCompaction:(NSArray *)codewords codeIndex:(int)codeIndex result:(NSMutableString *)result {
  int count = ([codewords[0] intValue] - codeIndex) << 1;
  // 2 character per codeword
  int textCompactionData[count];
  // Used to hold the byte compaction value if there is a mode shift
  int byteCompactionData[count];

  for (int i = 0; i < count; i++) {
    textCompactionData[0] = 0;
    byteCompactionData[0] = 0;
  }

  int index = 0;
  BOOL end = NO;
  while ((codeIndex < [codewords[0] intValue]) && !end) {
    int code = [codewords[codeIndex++] intValue];
    if (code < TEXT_COMPACTION_MODE_LATCH) {
      textCompactionData[index] = code / 30;
      textCompactionData[index + 1] = code % 30;
      index += 2;
    } else {
      switch (code) {
      case TEXT_COMPACTION_MODE_LATCH:
        // reinitialize text compaction mode to alpha sub mode
        textCompactionData[index++] = TEXT_COMPACTION_MODE_LATCH;
        break;
      case BYTE_COMPACTION_MODE_LATCH:
        codeIndex--;
        end = YES;
        break;
      case NUMERIC_COMPACTION_MODE_LATCH:
        codeIndex--;
        end = YES;
        break;
      case BEGIN_MACRO_PDF417_CONTROL_BLOCK:
        codeIndex--;
        end = YES;
        break;
      case BEGIN_MACRO_PDF417_OPTIONAL_FIELD:
        codeIndex--;
        end = YES;
        break;
      case MACRO_PDF417_TERMINATOR:
        codeIndex--;
        end = YES;
        break;
      case MODE_SHIFT_TO_BYTE_COMPACTION_MODE:
        // The Mode Shift codeword 913 shall cause a temporary
        // switch from Text Compaction mode to Byte Compaction mode.
        // This switch shall be in effect for only the next codeword,
        // after which the mode shall revert to the prevailing sub-mode
        // of the Text Compaction mode. Codeword 913 is only available
        // in Text Compaction mode; its use is described in 5.4.2.4.
        textCompactionData[index] = MODE_SHIFT_TO_BYTE_COMPACTION_MODE;
        code = [codewords[codeIndex++] intValue];
        byteCompactionData[index] = code;
        index++;
        break;
      case BYTE_COMPACTION_MODE_LATCH_6:
        codeIndex--;
        end = YES;
        break;
      }
    }
  }

  [self decodeTextCompaction:textCompactionData byteCompactionData:byteCompactionData length:index result:result];
  return codeIndex;
}


/**
 * The Text Compaction mode includes all the printable ASCII characters
 * (i.e. values from 32 to 126) and three ASCII control characters: HT or tab
 * (ASCII value 9), LF or line feed (ASCII value 10), and CR or carriage
 * return (ASCII value 13). The Text Compaction mode also includes various latch
 * and shift characters which are used exclusively within the mode. The Text
 * Compaction mode encodes up to 2 characters per codeword. The compaction rules
 * for converting data into PDF417 codewords are defined in 5.4.2.2. The sub-mode
 * switches are defined in 5.4.2.3.
 */
+ (void)decodeTextCompaction:(int *)textCompactionData byteCompactionData:(int *)byteCompactionData length:(unsigned int)length result:(NSMutableString *)result {
  // Beginning from an initial state of the Alpha sub-mode
  // The default compaction mode for PDF417 in effect at the start of each symbol shall always be Text
  // Compaction mode Alpha sub-mode (uppercase alphabetic). A latch codeword from another mode to the Text
  // Compaction mode shall always switch to the Text Compaction Alpha sub-mode.
  int subMode = ALPHA;
  int priorToShiftMode = ALPHA;
  int i = 0;
  while (i < length) {
    int subModeCh = textCompactionData[i];
    unichar ch = 0;
    switch (subMode) {
      case ALPHA:
        // Alpha (uppercase alphabetic)
        if (subModeCh < 26) {
        // Upper case Alpha Character
          ch = (unichar)('A' + subModeCh);
        } else {
          if (subModeCh == 26) {
            ch = ' ';
          } else if (subModeCh == LL) {
            subMode = LOWER;
          } else if (subModeCh == ML) {
            subMode = MIXED;
          } else if (subModeCh == PS) {
            // Shift to punctuation
            priorToShiftMode = subMode;
            subMode = PUNCT_SHIFT;
          } else if (subModeCh == MODE_SHIFT_TO_BYTE_COMPACTION_MODE) {
            [result appendFormat:@"%C", (unichar)byteCompactionData[i]];
          } else if (subModeCh == TEXT_COMPACTION_MODE_LATCH) {
            subMode = ALPHA;
          }
        }
        break;

      case LOWER:
        // Lower (lowercase alphabetic)
        if (subModeCh < 26) {
          ch = (unichar)('a' + subModeCh);
        } else {
          if (subModeCh == 26) {
            ch = ' ';
          } else if (subModeCh == AS) {
            // Shift to alpha
            priorToShiftMode = subMode;
            subMode = ALPHA_SHIFT;
          } else if (subModeCh == ML) {
            subMode = MIXED;
          } else if (subModeCh == PS) {
            // Shift to punctuation
            priorToShiftMode = subMode;
            subMode = PUNCT_SHIFT;
          } else if (subModeCh == MODE_SHIFT_TO_BYTE_COMPACTION_MODE) {
            [result appendFormat:@"%C", (unichar)byteCompactionData[i]];
          } else if (subModeCh == TEXT_COMPACTION_MODE_LATCH) {
            subMode = ALPHA;
          }
        }
        break;

      case MIXED:
        // Mixed (numeric and some punctuation)
        if (subModeCh < PL) {
          ch = MIXED_CHARS[subModeCh];
        } else {
          if (subModeCh == PL) {
            subMode = PUNCT;
          } else if (subModeCh == 26) {
            ch = ' ';
          } else if (subModeCh == LL) {
            subMode = LOWER;
          } else if (subModeCh == AL) {
            subMode = ALPHA;
          } else if (subModeCh == PS) {
            // Shift to punctuation
            priorToShiftMode = subMode;
            subMode = PUNCT_SHIFT;
          } else if (subModeCh == MODE_SHIFT_TO_BYTE_COMPACTION_MODE) {
            [result appendFormat:@"%C", (unichar)byteCompactionData[i]];
          } else if (subModeCh == TEXT_COMPACTION_MODE_LATCH) {
            subMode = ALPHA;
          }
        }
        break;

      case PUNCT:
        // Punctuation
        if (subModeCh < PAL) {
          ch = PUNCT_CHARS[subModeCh];
        } else {
          if (subModeCh == PAL) {
            subMode = ALPHA;
          } else if (subModeCh == MODE_SHIFT_TO_BYTE_COMPACTION_MODE) {
            [result appendFormat:@"%C", (unichar)byteCompactionData[i]];
          } else if (TEXT_COMPACTION_MODE_LATCH) {
            subMode = ALPHA;
          }
        }
        break;

      case ALPHA_SHIFT:
        // Restore sub-mode
        subMode = priorToShiftMode;
        if (subModeCh < 26) {
          ch = (unichar)('A' + subModeCh);
        } else {
          if (subModeCh == 26) {
            ch = ' ';
          } else if (subModeCh == TEXT_COMPACTION_MODE_LATCH) {
            subMode = ALPHA;
          }
        }
        break;

      case PUNCT_SHIFT:
        // Restore sub-mode
        subMode = priorToShiftMode;
        if (subModeCh < PAL) {
          ch = PUNCT_CHARS[subModeCh];
        } else {
          if (subModeCh == PAL) {
            subMode = ALPHA;
          } else if (subModeCh == MODE_SHIFT_TO_BYTE_COMPACTION_MODE) {
            // PS before Shift-to-Byte is used as a padding character,
            // see 5.4.2.4 of the specification
            [result appendFormat:@"%C", (unichar)byteCompactionData[i]];
          } else if (subModeCh == TEXT_COMPACTION_MODE_LATCH) {
            subMode = ALPHA;
          }
        }
        break;
    }
    if (ch != 0) {
      // Append decoded character to result
      [result appendFormat:@"%C", ch];
    }
    i++;
  }
}


/**
 * Byte Compaction mode (see 5.4.3) permits all 256 possible 8-bit byte values to be encoded.
 * This includes all ASCII characters value 0 to 127 inclusive and provides for international
 * character set support.
 */
+ (int)byteCompaction:(int)mode codewords:(NSArray *)codewords codeIndex:(int)codeIndex result:(NSMutableString *)result {
  if (mode == BYTE_COMPACTION_MODE_LATCH) {
    // Total number of Byte Compaction characters to be encoded
    // is not a multiple of 6
    int count = 0;
    long long value = 0;
    char decodedData[6] = {0, 0, 0, 0, 0, 0};
    int byteCompactedCodewords[6] = {0, 0, 0, 0, 0, 0};
    BOOL end = NO;
    int nextCode = [codewords[codeIndex++] intValue];
    while ((codeIndex < [codewords[0] intValue]) && !end) {
      byteCompactedCodewords[count++] = nextCode;
      // Base 900
      value = 900 * value + nextCode;
      nextCode = [codewords[codeIndex++] intValue];
      // perhaps it should be ok to check only nextCode >= TEXT_COMPACTION_MODE_LATCH
      if (nextCode == TEXT_COMPACTION_MODE_LATCH ||
          nextCode == BYTE_COMPACTION_MODE_LATCH ||
          nextCode == NUMERIC_COMPACTION_MODE_LATCH ||
          nextCode == BYTE_COMPACTION_MODE_LATCH_6 ||
          nextCode == BEGIN_MACRO_PDF417_CONTROL_BLOCK ||
          nextCode == BEGIN_MACRO_PDF417_OPTIONAL_FIELD ||
          nextCode == MACRO_PDF417_TERMINATOR) {
        codeIndex--;
        end = YES;
      } else {
        if ((count % 5 == 0) && (count > 0)) {
          // Decode every 5 codewords
          // Convert to Base 256
          for (int j = 0; j < 6; ++j) {
            decodedData[5 - j] = (char) (value % 256);
            value >>= 8;
          }
          [result appendString:[[NSString alloc] initWithBytes:decodedData length:6 encoding:NSISOLatin1StringEncoding]];
          count = 0;
        }
      }
    }

    // if the end of all codewords is reached the last codeword needs to be added
    if (codeIndex == [codewords[0] intValue] && nextCode < TEXT_COMPACTION_MODE_LATCH) {
      byteCompactedCodewords[count++] = nextCode;
    }

    // If Byte Compaction mode is invoked with codeword 901,
    // the last group of codewords is interpreted directly
    // as one byte per codeword, without compaction.
    for (int i = 0; i < count; i++) {
      [result appendFormat:@"%C", (unichar)byteCompactedCodewords[i]];
    }
  } else if (mode == BYTE_COMPACTION_MODE_LATCH_6) {
    // Total number of Byte Compaction characters to be encoded
    // is an integer multiple of 6
    int count = 0;
    long long value = 0;
    BOOL end = NO;
    while (codeIndex < [codewords[0] intValue] && !end) {
      int code = [codewords[codeIndex++] intValue];
      if (code < TEXT_COMPACTION_MODE_LATCH) {
        count++;
        // Base 900
        value = 900 * value + code;
      } else {
        if (code == TEXT_COMPACTION_MODE_LATCH ||
            code == BYTE_COMPACTION_MODE_LATCH ||
            code == NUMERIC_COMPACTION_MODE_LATCH ||
            code == BYTE_COMPACTION_MODE_LATCH_6 ||
            code == BEGIN_MACRO_PDF417_CONTROL_BLOCK ||
            code == BEGIN_MACRO_PDF417_OPTIONAL_FIELD ||
            code == MACRO_PDF417_TERMINATOR) {
          codeIndex--;
          end = YES;
        }
      }
      if ((count % 5 == 0) && (count > 0)) {
        // Decode every 5 codewords
        // Convert to Base 256
        unichar decodedData[6];
        for (int j = 0; j < 6; ++j) {
          decodedData[5 - j] = (unichar)(value & 0xFF);
          value >>= 8;
        }
        [result appendString:[NSString stringWithCharacters:decodedData length:6]];
        count = 0;
      }
    }
  }
  return codeIndex;
}

/**
 * Numeric Compaction mode (see 5.4.4) permits efficient encoding of numeric data strings.
 */
+ (int)numericCompaction:(NSArray *)codewords codeIndex:(int)codeIndex result:(NSMutableString *)result {
  int count = 0;
  BOOL end = NO;

  int numericCodewords[MAX_NUMERIC_CODEWORDS];
  memset(numericCodewords, 0, MAX_NUMERIC_CODEWORDS * sizeof(int));

  while (codeIndex < [codewords[0] intValue] && !end) {
    int code = [codewords[codeIndex++] intValue];
    if (codeIndex == [codewords[0] intValue]) {
      end = YES;
    }
    if (code < TEXT_COMPACTION_MODE_LATCH) {
      numericCodewords[count] = code;
      count++;
    } else {
      if (code == TEXT_COMPACTION_MODE_LATCH ||
          code == BYTE_COMPACTION_MODE_LATCH ||
          code == BYTE_COMPACTION_MODE_LATCH_6 ||
          code == BEGIN_MACRO_PDF417_CONTROL_BLOCK ||
          code == BEGIN_MACRO_PDF417_OPTIONAL_FIELD ||
          code == MACRO_PDF417_TERMINATOR) {
        codeIndex--;
        end = YES;
      }
    }
    if (count % MAX_NUMERIC_CODEWORDS == 0 || code == NUMERIC_COMPACTION_MODE_LATCH || end) {
      NSString *s = [self decodeBase900toBase10:numericCodewords count:count];
      if (s == nil) {
        return INT_MAX;
      }
      [result appendString:s];
      count = 0;
    }
  }
  return codeIndex;
}

/**
 * Convert a list of Numeric Compacted codewords from Base 900 to Base 10.
 */
/*
   EXAMPLE
   Encode the fifteen digit numeric string 000213298174000
   Prefix the numeric string with a 1 and set the initial value of
   t = 1 000 213 298 174 000
   Calculate codeword 0
   d0 = 1 000 213 298 174 000 mod 900 = 200
   
   t = 1 000 213 298 174 000 div 900 = 1 111 348 109 082
   Calculate codeword 1
   d1 = 1 111 348 109 082 mod 900 = 282
   
   t = 1 111 348 109 082 div 900 = 1 234 831 232
   Calculate codeword 2
   d2 = 1 234 831 232 mod 900 = 632
   
   t = 1 234 831 232 div 900 = 1 372 034
   Calculate codeword 3
   d3 = 1 372 034 mod 900 = 434
   
   t = 1 372 034 div 900 = 1 524
   Calculate codeword 4u
   d4 = 1 524 mod 900 = 624
   
   t = 1 524 div 900 = 1
   Calculate codeword 5
   d5 = 1 mod 900 = 1
   t = 1 div 900 = 0
   Codeword sequence is: 1, 624, 434, 632, 282, 200
   
   Decode the above codewords involves
   1 x 900 power of 5 + 624 x 900 power of 4 + 434 x 900 power of 3 +
   632 x 900 power of 2 + 282 x 900 power of 1 + 200 x 900 power of 0 = 1000213298174000
   
   Remove leading 1 =>  Result is 000213298174000
 */
+ (NSString *)decodeBase900toBase10:(int[])codewords count:(int)count {
  NSDecimalNumber *result = [NSDecimalNumber zero];
  for (int i = 0; i < count; i++) {
    result = [result decimalNumberByAdding:[EXP900[count - i - 1] decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithDecimal:[@(codewords[i]) decimalValue]]]];
  }
  NSString *resultString = [result stringValue];
  if (![resultString hasPrefix:@"1"]) {
    return nil;
  }
  return [resultString substringFromIndex:1];
}

@end
