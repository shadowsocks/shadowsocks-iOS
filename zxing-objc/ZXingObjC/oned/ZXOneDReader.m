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

#import "ZXBinaryBitmap.h"
#import "ZXBitArray.h"
#import "ZXDecodeHints.h"
#import "ZXErrors.h"
#import "ZXOneDReader.h"
#import "ZXResult.h"
#import "ZXResultPoint.h"

int const INTEGER_MATH_SHIFT = 8;
int const PATTERN_MATCH_RESULT_SCALE_FACTOR = 1 << INTEGER_MATH_SHIFT;

@implementation ZXOneDReader

- (ZXResult *)decode:(ZXBinaryBitmap *)image error:(NSError **)error {
  return [self decode:image hints:nil error:error];
}

// Note that we don't try rotation without the try harder flag, even if rotation was supported.
- (ZXResult *)decode:(ZXBinaryBitmap *)image hints:(ZXDecodeHints *)hints error:(NSError **)error {
  NSError *decodeError = nil;
  ZXResult *result = [self doDecode:image hints:hints error:&decodeError];
  if (result) {
    return result;
  } else if (decodeError.code == ZXNotFoundError) {
    BOOL tryHarder = hints != nil && hints.tryHarder;
    if (tryHarder && [image rotateSupported]) {
      ZXBinaryBitmap *rotatedImage = [image rotateCounterClockwise];
      ZXResult *result = [self doDecode:rotatedImage hints:hints error:error];
      if (!result) {
        return nil;
      }
      // Record that we found it rotated 90 degrees CCW / 270 degrees CW
      NSMutableDictionary *metadata = [result resultMetadata];
      int orientation = 270;
      if (metadata != nil && metadata[@(kResultMetadataTypeOrientation)]) {
        // But if we found it reversed in doDecode(), add in that result here:
        orientation = (orientation + [((NSNumber *)metadata[@(kResultMetadataTypeOrientation)]) intValue]) % 360;
      }
      [result putMetadata:kResultMetadataTypeOrientation value:@(orientation)];
      // Update result points
      NSMutableArray *points = [result resultPoints];
      if (points != nil) {
        int height = [rotatedImage height];
        for (int i = 0; i < [points count]; i++) {
          points[i] = [[ZXResultPoint alloc] initWithX:height - [(ZXResultPoint *)points[i] y]
                                                     y:[(ZXResultPoint *)points[i] x]];
        }
      }
      return result;
    }
  }

  if (error) *error = decodeError;
  return nil;
}

- (void)reset {
  
}


/**
 * We're going to examine rows from the middle outward, searching alternately above and below the
 * middle, and farther out each time. rowStep is the number of rows between each successive
 * attempt above and below the middle. So we'd scan row middle, then middle - rowStep, then
 * middle + rowStep, then middle - (2 * rowStep), etc.
 * rowStep is bigger as the image is taller, but is always at least 1. We've somewhat arbitrarily
 * decided that moving up and down by about 1/16 of the image is pretty good; we try more of the
 * image if "trying harder".
 */
- (ZXResult *)doDecode:(ZXBinaryBitmap *)image hints:(ZXDecodeHints *)hints error:(NSError **)error {
  int width = image.width;
  int height = image.height;
  ZXBitArray *row = [[ZXBitArray alloc] initWithSize:width];
  int middle = height >> 1;
  BOOL tryHarder = hints != nil && hints.tryHarder;
  int rowStep = MAX(1, height >> (tryHarder ? 8 : 5));
  int maxLines;
  if (tryHarder) {
    maxLines = height;
  } else {
    maxLines = 15;
  }

  for (int x = 0; x < maxLines; x++) {
    int rowStepsAboveOrBelow = (x + 1) >> 1;
    BOOL isAbove = (x & 0x01) == 0;
    int rowNumber = middle + rowStep * (isAbove ? rowStepsAboveOrBelow : -rowStepsAboveOrBelow);
    if (rowNumber < 0 || rowNumber >= height) {
      break;
    }

    NSError *rowError = nil;
    row = [image blackRow:rowNumber row:row error:&rowError];
    if (!row && rowError.code == ZXNotFoundError) {
      continue;
    } else if (!row) {
      if (error) *error = rowError;
      return nil;
    }

    for (int attempt = 0; attempt < 2; attempt++) {
      if (attempt == 1) {
        [row reverse];
        if (hints != nil && hints.resultPointCallback) {
          hints = [hints copy];
          hints.resultPointCallback = nil;
        }
      }

      ZXResult *result = [self decodeRow:rowNumber row:row hints:hints error:nil];
      if (result) {
        if (attempt == 1) {
          [result putMetadata:kResultMetadataTypeOrientation value:@180];
          NSMutableArray *points = [result resultPoints];
          if (points != nil) {
            points[0] = [[ZXResultPoint alloc] initWithX:width - [(ZXResultPoint *)points[0] x]
                                                       y:[(ZXResultPoint *)points[0] y]];
            points[1] = [[ZXResultPoint alloc] initWithX:width - [(ZXResultPoint *)points[1] x]
                                                       y:[(ZXResultPoint *)points[1] y]];
          }
        }
        return result;
      }
    }
  }

  if (error) *error = NotFoundErrorInstance();
  return nil;
}


/**
 * Records the size of successive runs of white and black pixels in a row, starting at a given point.
 * The values are recorded in the given array, and the number of runs recorded is equal to the size
 * of the array. If the row starts on a white pixel at the given start point, then the first count
 * recorded is the run of white pixels starting from that point; likewise it is the count of a run
 * of black pixels if the row begin on a black pixels at that point.
 */
+ (BOOL)recordPattern:(ZXBitArray *)row start:(int)start counters:(int[])counters countersSize:(int)countersSize {
  int numCounters = countersSize;

  memset(counters, 0, numCounters * sizeof(int));

  int end = row.size;
  if (start >= end) {
    return NO;
  }
  BOOL isWhite = ![row get:start];
  int counterPosition = 0;
  int i = start;

  while (i < end) {
    if ([row get:i] ^ isWhite) {
      counters[counterPosition]++;
    } else {
      counterPosition++;
      if (counterPosition == numCounters) {
        break;
      } else {
        counters[counterPosition] = 1;
        isWhite = !isWhite;
      }
    }
    i++;
  }

  if (!(counterPosition == numCounters || (counterPosition == numCounters - 1 && i == end))) {
    return NO;
  }
  return YES;
}

+ (BOOL)recordPatternInReverse:(ZXBitArray *)row start:(int)start counters:(int[])counters countersSize:(int)countersSize {
  int numTransitionsLeft = countersSize;
  BOOL last = [row get:start];

  while (start > 0 && numTransitionsLeft >= 0) {
    if ([row get:--start] != last) {
      numTransitionsLeft--;
      last = !last;
    }
  }

  if (numTransitionsLeft >= 0 || ![self recordPattern:row start:start + 1 counters:counters countersSize:countersSize]) {
    return NO;
  }
  return YES;
}


/**
 * Determines how closely a set of observed counts of runs of black/white values matches a given
 * target pattern. This is reported as the ratio of the total variance from the expected pattern
 * proportions across all pattern elements, to the length of the pattern.
 * 
 * Returns ratio of total variance between counters and pattern compared to total pattern size,
 * where the ratio has been multiplied by 256. So, 0 means no variance (perfect match); 256 means
 * the total variance between counters and patterns equals the pattern length, higher values mean
 * even more variance
 */
+ (int)patternMatchVariance:(int[])counters countersSize:(int)countersSize pattern:(int[])pattern maxIndividualVariance:(int)maxIndividualVariance {
  int numCounters = countersSize;
  int total = 0;
  int patternLength = 0;

  for (int i = 0; i < numCounters; i++) {
    total += counters[i];
    patternLength += pattern[i];
  }

  if (total < patternLength || patternLength == 0) {
    return INT_MAX;
  }
  int unitBarWidth = (total << INTEGER_MATH_SHIFT) / patternLength;
  maxIndividualVariance = (maxIndividualVariance * unitBarWidth) >> INTEGER_MATH_SHIFT;
  int totalVariance = 0;

  for (int x = 0; x < numCounters; x++) {
    int counter = counters[x] << INTEGER_MATH_SHIFT;
    int scaledPattern = pattern[x] * unitBarWidth;
    int variance = counter > scaledPattern ? counter - scaledPattern : scaledPattern - counter;
    if (variance > maxIndividualVariance) {
      return INT_MAX;
    }
    totalVariance += variance;
  }

  return totalVariance / total;
}


/**
 * Attempts to decode a one-dimensional barcode format given a single row of
 * an image.
 */
- (ZXResult *)decodeRow:(int)rowNumber row:(ZXBitArray *)row hints:(ZXDecodeHints *)hints error:(NSError **)error {
  @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                 reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                               userInfo:nil];
}

@end
