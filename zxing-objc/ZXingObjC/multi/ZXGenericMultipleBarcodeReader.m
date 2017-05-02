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

#import "ZXErrors.h"
#import "ZXGenericMultipleBarcodeReader.h"
#import "ZXReader.h"
#import "ZXResultPoint.h"

int const MIN_DIMENSION_TO_RECUR = 100;
int const MAX_DEPTH = 4;

@interface ZXGenericMultipleBarcodeReader ()

@property (nonatomic, weak) id<ZXReader> delegate;

@end

@implementation ZXGenericMultipleBarcodeReader

- (id)initWithDelegate:(id<ZXReader>)delegate {
  if (self = [super init]) {
    _delegate = delegate;
  }

  return self;
}

- (NSArray *)decodeMultiple:(ZXBinaryBitmap *)image error:(NSError **)error {
  return [self decodeMultiple:image hints:nil error:error];
}

- (NSArray *)decodeMultiple:(ZXBinaryBitmap *)image hints:(ZXDecodeHints *)hints error:(NSError **)error {
  NSMutableArray *results = [NSMutableArray array];
  if (![self doDecodeMultiple:image hints:hints results:results xOffset:0 yOffset:0 currentDepth:0 error:error]) {
    return nil;
  } else if (results.count == 0) {
    if (error) *error = NotFoundErrorInstance();
    return nil;
  }
  return results;
}

- (BOOL)doDecodeMultiple:(ZXBinaryBitmap *)image hints:(ZXDecodeHints *)hints results:(NSMutableArray *)results
                 xOffset:(int)xOffset yOffset:(int)yOffset currentDepth:(int)currentDepth error:(NSError **)error {
  if (currentDepth > MAX_DEPTH) {
    return YES;
  }

  ZXResult *result = [self.delegate decode:image hints:hints error:error];
  if (!result) {
    return NO;
  }

  BOOL alreadyFound = NO;
  for (ZXResult *existingResult in results) {
    if ([[existingResult text] isEqualToString:[result text]]) {
      alreadyFound = YES;
      break;
    }
  }
  if (!alreadyFound) {
    [results addObject:[self translateResultPoints:result xOffset:xOffset yOffset:yOffset]];
  }
  NSMutableArray *resultPoints = [result resultPoints];
  if (resultPoints == nil || [resultPoints count] == 0) {
    return YES;
  }
  int width = [image width];
  int height = [image height];
  float minX = width;
  float minY = height;
  float maxX = 0.0f;
  float maxY = 0.0f;
  for (ZXResultPoint *point in resultPoints) {
    float x = [point x];
    float y = [point y];
    if (x < minX) {
      minX = x;
    }
    if (y < minY) {
      minY = y;
    }
    if (x > maxX) {
      maxX = x;
    }
    if (y > maxY) {
      maxY = y;
    }
  }

  if (minX > MIN_DIMENSION_TO_RECUR) {
    return [self doDecodeMultiple:[image crop:0 top:0 width:(int)minX height:height] hints:hints results:results xOffset:xOffset yOffset:yOffset currentDepth:currentDepth + 1 error:error];
  }
  if (minY > MIN_DIMENSION_TO_RECUR) {
    return [self doDecodeMultiple:[image crop:0 top:0 width:width height:(int)minY] hints:hints results:results xOffset:xOffset yOffset:yOffset currentDepth:currentDepth + 1 error:error];
  }
  if (maxX < width - MIN_DIMENSION_TO_RECUR) {
    return [self doDecodeMultiple:[image crop:(int)maxX top:0 width:width - (int)maxX height:height] hints:hints results:results xOffset:xOffset + (int)maxX yOffset:yOffset currentDepth:currentDepth + 1 error:error];
  }
  if (maxY < height - MIN_DIMENSION_TO_RECUR) {
    return [self doDecodeMultiple:[image crop:0 top:(int)maxY width:width height:height - (int)maxY] hints:hints results:results xOffset:xOffset yOffset:yOffset + (int)maxY currentDepth:currentDepth + 1 error:error];
  }

  return YES;
}

- (ZXResult *)translateResultPoints:(ZXResult *)result xOffset:(int)xOffset yOffset:(int)yOffset {
  NSArray *oldResultPoints = [result resultPoints];
  if (oldResultPoints == nil) {
    return result;
  }
  NSMutableArray *newResultPoints = [NSMutableArray arrayWithCapacity:[oldResultPoints count]];
  for (ZXResultPoint *oldPoint in oldResultPoints) {
    [newResultPoints addObject:[[ZXResultPoint alloc] initWithX:[oldPoint x] + xOffset y:[oldPoint y] + yOffset]];
  }

  ZXResult *newResult = [ZXResult resultWithText:result.text rawBytes:result.rawBytes length:result.length resultPoints:newResultPoints format:result.barcodeFormat];
  [newResult putAllMetadata:result.resultMetadata];
  return newResult;
}

@end
