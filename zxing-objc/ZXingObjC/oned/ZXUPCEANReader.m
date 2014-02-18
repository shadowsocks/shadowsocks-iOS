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

#import "ZXBitArray.h"
#import "ZXDecodeHints.h"
#import "ZXEANManufacturerOrgSupport.h"
#import "ZXErrors.h"
#import "ZXResult.h"
#import "ZXResultPoint.h"
#import "ZXResultPointCallback.h"
#import "ZXUPCEANReader.h"
#import "ZXUPCEANExtensionSupport.h"

#define MAX_AVG_VARIANCE (int)(PATTERN_MATCH_RESULT_SCALE_FACTOR * 0.48f)
#define MAX_INDIVIDUAL_VARIANCE (int)(PATTERN_MATCH_RESULT_SCALE_FACTOR * 0.7f)

/**
 * Start/end guard pattern.
 */
const int START_END_PATTERN[START_END_PATTERN_LEN] = {1, 1, 1};

/**
 * Pattern marking the middle of a UPC/EAN pattern, separating the two halves.
 */
const int MIDDLE_PATTERN[MIDDLE_PATTERN_LEN] = {1, 1, 1, 1, 1};

/**
 * "Odd", or "L" patterns used to encode UPC/EAN digits.
 */
const int L_PATTERNS[L_PATTERNS_LEN][L_PATTERNS_SUB_LEN] = {
  {3, 2, 1, 1}, // 0
  {2, 2, 2, 1}, // 1
  {2, 1, 2, 2}, // 2
  {1, 4, 1, 1}, // 3
  {1, 1, 3, 2}, // 4
  {1, 2, 3, 1}, // 5
  {1, 1, 1, 4}, // 6
  {1, 3, 1, 2}, // 7
  {1, 2, 1, 3}, // 8
  {3, 1, 1, 2}  // 9
};

/**
 * As above but also including the "even", or "G" patterns used to encode UPC/EAN digits.
 */
#define L_AND_G_PATTERNS_LEN 20
#define L_AND_G_PATTERNS_SUB_LEN 4
const int L_AND_G_PATTERNS[L_AND_G_PATTERNS_LEN][L_AND_G_PATTERNS_SUB_LEN] = {
  {3, 2, 1, 1}, // 0
  {2, 2, 2, 1}, // 1
  {2, 1, 2, 2}, // 2
  {1, 4, 1, 1}, // 3
  {1, 1, 3, 2}, // 4
  {1, 2, 3, 1}, // 5
  {1, 1, 1, 4}, // 6
  {1, 3, 1, 2}, // 7
  {1, 2, 1, 3}, // 8
  {3, 1, 1, 2}, // 9
  {1, 1, 2, 3}, // 10 reversed 0
  {1, 2, 2, 2}, // 11 reversed 1
  {2, 2, 1, 2}, // 12 reversed 2
  {1, 1, 4, 1}, // 13 reversed 3
  {2, 3, 1, 1}, // 14 reversed 4
  {1, 3, 2, 1}, // 15 reversed 5
  {4, 1, 1, 1}, // 16 reversed 6
  {2, 1, 3, 1}, // 17 reversed 7
  {3, 1, 2, 1}, // 18 reversed 8
  {2, 1, 1, 3}  // 19 reversed 9
};

@interface ZXUPCEANReader ()

@property (nonatomic, strong) NSMutableString *decodeRowNSMutableString;
@property (nonatomic, strong) ZXUPCEANExtensionSupport *extensionReader;
@property (nonatomic, strong) ZXEANManufacturerOrgSupport *eanManSupport;

@end

@implementation ZXUPCEANReader

- (id)init {
  if (self = [super init]) {
    _decodeRowNSMutableString = [NSMutableString stringWithCapacity:20];
    _extensionReader = [[ZXUPCEANExtensionSupport alloc] init];
    _eanManSupport = [[ZXEANManufacturerOrgSupport alloc] init];
  }

  return self;
}

+ (NSRange)findStartGuardPattern:(ZXBitArray *)row error:(NSError **)error {
  BOOL foundStart = NO;
  NSRange startRange = NSMakeRange(NSNotFound, 0);
  int nextStart = 0;
  int counters[START_END_PATTERN_LEN];

  while (!foundStart) {
    startRange = [self findGuardPattern:row rowOffset:nextStart whiteFirst:NO pattern:(int *)START_END_PATTERN patternLen:START_END_PATTERN_LEN counters:counters error:error];
    if (startRange.location == NSNotFound) {
      return startRange;
    }
    int start = (int)startRange.location;
    nextStart = (int)NSMaxRange(startRange);
    // Make sure there is a quiet zone at least as big as the start pattern before the barcode.
    // If this check would run off the left edge of the image, do not accept this barcode,
    // as it is very likely to be a false positive.
    int quietStart = start - (nextStart - start);
    if (quietStart >= 0) {
      foundStart = [row isRange:quietStart end:start value:NO];
    }
  }
  return startRange;
}

- (ZXResult *)decodeRow:(int)rowNumber row:(ZXBitArray *)row hints:(ZXDecodeHints *)hints error:(NSError **)error {
  return [self decodeRow:rowNumber row:row startGuardRange:[[self class] findStartGuardPattern:row error:error] hints:hints error:error];
}

/**
 * Like decodeRow:row:hints:, but allows caller to inform method about where the UPC/EAN start pattern is
 * found. This allows this to be computed once and reused across many implementations.
 */
- (ZXResult *)decodeRow:(int)rowNumber row:(ZXBitArray *)row startGuardRange:(NSRange)startGuardRange hints:(ZXDecodeHints *)hints error:(NSError **)error {
  id<ZXResultPointCallback> resultPointCallback = hints == nil ? nil : hints.resultPointCallback;

  if (resultPointCallback != nil) {
    [resultPointCallback foundPossibleResultPoint:[[ZXResultPoint alloc] initWithX:(startGuardRange.location + NSMaxRange(startGuardRange)) / 2.0f y:rowNumber]];
  }

  NSMutableString *result = [NSMutableString string];
  int endStart = [self decodeMiddle:row startRange:startGuardRange result:result error:error];
  if (endStart == -1) {
    return nil;
  }

  if (resultPointCallback != nil) {
    [resultPointCallback foundPossibleResultPoint:[[ZXResultPoint alloc] initWithX:endStart y:rowNumber]];
  }

  NSRange endRange = [self decodeEnd:row endStart:endStart error:error];
  if (endRange.location == NSNotFound) {
    return nil;
  }

  if (resultPointCallback != nil) {
    [resultPointCallback foundPossibleResultPoint:[[ZXResultPoint alloc] initWithX:(endRange.location + NSMaxRange(endRange)) / 2.0f y:rowNumber]];
  }

  // Make sure there is a quiet zone at least as big as the end pattern after the barcode. The
  // spec might want more whitespace, but in practice this is the maximum we can count on.
  int end = (int)NSMaxRange(endRange);
  int quietEnd = end + (end - (int)endRange.location);
  if (quietEnd >= [row size] || ![row isRange:end end:quietEnd value:NO]) {
    if (error) *error = NotFoundErrorInstance();
    return nil;
  }

  NSString *resultString = [result description];
  if (![self checkChecksum:resultString error:error]) {
    if (error) *error = ChecksumErrorInstance();
    return nil;
  }

  float left = (float)(NSMaxRange(startGuardRange) + startGuardRange.location) / 2.0f;
  float right = (float)(NSMaxRange(endRange) + endRange.location) / 2.0f;
  ZXBarcodeFormat format = [self barcodeFormat];

  ZXResult *decodeResult = [ZXResult resultWithText:resultString
                                           rawBytes:NULL
                                             length:0
                                       resultPoints:@[[[ZXResultPoint alloc] initWithX:left y:(float)rowNumber], [[ZXResultPoint alloc] initWithX:right y:(float)rowNumber]]
                                             format:format];

  ZXResult *extensionResult = [self.extensionReader decodeRow:rowNumber row:row rowOffset:(int)NSMaxRange(endRange) error:error];
  if (extensionResult) {
    [decodeResult putMetadata:kResultMetadataTypeUPCEANExtension value:extensionResult.text];
    [decodeResult putAllMetadata:[extensionResult resultMetadata]];
    [decodeResult addResultPoints:[extensionResult resultPoints]];
  }

  if (format == kBarcodeFormatEan13 || format == kBarcodeFormatUPCA) {
    NSString *countryID = [self.eanManSupport lookupCountryIdentifier:resultString];
    if (countryID != nil) {
      [decodeResult putMetadata:kResultMetadataTypePossibleCountry value:countryID];
    }
  }
  return decodeResult;
}

- (BOOL)checkChecksum:(NSString *)s error:(NSError **)error {
  if ([[self class] checkStandardUPCEANChecksum:s]) {
    return YES;
  } else {
    if (error) *error = FormatErrorInstance();
    return NO;
  }
}


/**
 * Computes the UPC/EAN checksum on a string of digits, and reports
 * whether the checksum is correct or not.
 */
+ (BOOL)checkStandardUPCEANChecksum:(NSString *)s {
  int length = (int)[s length];
  if (length == 0) {
    return NO;
  }
  int sum = 0;

  for (int i = length - 2; i >= 0; i -= 2) {
    int digit = (int)[s characterAtIndex:i] - (int)'0';
    if (digit < 0 || digit > 9) {
      return NO;
    }
    sum += digit;
  }

  sum *= 3;

  for (int i = length - 1; i >= 0; i -= 2) {
    int digit = (int)[s characterAtIndex:i] - (int)'0';
    if (digit < 0 || digit > 9) {
      return NO;
    }
    sum += digit;
  }

  return sum % 10 == 0;
}

- (NSRange)decodeEnd:(ZXBitArray *)row endStart:(int)endStart error:(NSError **)error {
  return [[self class] findGuardPattern:row rowOffset:endStart whiteFirst:NO pattern:(int *)START_END_PATTERN patternLen:START_END_PATTERN_LEN error:error];
}

+ (NSRange)findGuardPattern:(ZXBitArray *)row rowOffset:(int)rowOffset whiteFirst:(BOOL)whiteFirst pattern:(int *)pattern patternLen:(int)patternLen error:(NSError **)error {
  int counters[patternLen];
  return [self findGuardPattern:row rowOffset:rowOffset whiteFirst:whiteFirst pattern:pattern patternLen:patternLen counters:counters error:error];
}

+ (NSRange)findGuardPattern:(ZXBitArray *)row rowOffset:(int)rowOffset whiteFirst:(BOOL)whiteFirst pattern:(int *)pattern patternLen:(int)patternLen counters:(int *)counters error:(NSError **)error {
  int patternLength = patternLen;
  memset(counters, 0, patternLength * sizeof(int));
  int width = row.size;

  BOOL isWhite = whiteFirst;
  rowOffset = whiteFirst ? [row nextUnset:rowOffset] : [row nextSet:rowOffset];
  int counterPosition = 0;
  int patternStart = rowOffset;

  for (int x = rowOffset; x < width; x++) {
    if ([row get:x] ^ isWhite) {
      counters[counterPosition]++;
    } else {
      if (counterPosition == patternLength - 1) {
        if ([self patternMatchVariance:counters countersSize:patternLength pattern:pattern maxIndividualVariance:MAX_INDIVIDUAL_VARIANCE] < MAX_AVG_VARIANCE) {
          return NSMakeRange(patternStart, x - patternStart);
        }
        patternStart += counters[0] + counters[1];

        for (int y = 2; y < patternLength; y++) {
          counters[y - 2] = counters[y];
        }

        counters[patternLength - 2] = 0;
        counters[patternLength - 1] = 0;
        counterPosition--;
      } else {
        counterPosition++;
      }
      counters[counterPosition] = 1;
      isWhite = !isWhite;
    }
  }

  if (error) *error = NotFoundErrorInstance();
  return NSMakeRange(NSNotFound, 0);
}


/**
 * Attempts to decode a single UPC/EAN-encoded digit.
 */
+ (int)decodeDigit:(ZXBitArray *)row counters:(int[])counters countersLen:(int)countersLen rowOffset:(int)rowOffset patternType:(UPC_EAN_PATTERNS)patternType error:(NSError **)error {
  if (![self recordPattern:row start:rowOffset counters:counters countersSize:countersLen]) {
    if (error) *error = NotFoundErrorInstance();
    return -1;
  }
  int bestVariance = MAX_AVG_VARIANCE;
  int bestMatch = -1;
  int max = 0;
  switch (patternType) {
    case UPC_EAN_PATTERNS_L_PATTERNS:
      max = L_PATTERNS_LEN;
      for (int i = 0; i < max; i++) {
        int pattern[countersLen];
        for(int j = 0; j < countersLen; j++){
          pattern[j] = L_PATTERNS[i][j];
        }

        int variance = [self patternMatchVariance:counters countersSize:countersLen pattern:pattern maxIndividualVariance:MAX_INDIVIDUAL_VARIANCE];
        if (variance < bestVariance) {
          bestVariance = variance;
          bestMatch = i;
        }
      }
      break;
    case UPC_EAN_PATTERNS_L_AND_G_PATTERNS:
      max = L_AND_G_PATTERNS_LEN;
      for (int i = 0; i < max; i++) {
        int pattern[countersLen];
        for(int j = 0; j< countersLen; j++){
          pattern[j] = L_AND_G_PATTERNS[i][j];
        }
        
        int variance = [self patternMatchVariance:counters countersSize:countersLen pattern:pattern maxIndividualVariance:MAX_INDIVIDUAL_VARIANCE];
        if (variance < bestVariance) {
          bestVariance = variance;
          bestMatch = i;
        }
      }
      break;
    default:
      break;
  }

  if (bestMatch >= 0) {
    return bestMatch;
  } else {
    if (error) *error = NotFoundErrorInstance();
    return -1;
  }
}

/**
 * Get the format of this decoder.
 */
- (ZXBarcodeFormat)barcodeFormat {
  @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                 reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                               userInfo:nil];
}


/**
 * Subclasses override this to decode the portion of a barcode between the start
 * and end guard patterns.
 */
- (int)decodeMiddle:(ZXBitArray *)row startRange:(NSRange)startRange result:(NSMutableString *)result error:(NSError **)error {
  @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                 reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                               userInfo:nil];
}

@end
