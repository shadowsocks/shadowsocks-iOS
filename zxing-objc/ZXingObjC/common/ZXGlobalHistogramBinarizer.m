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

#import "ZXGlobalHistogramBinarizer.h"
#import "ZXBitArray.h"
#import "ZXBitMatrix.h"
#import "ZXErrors.h"
#import "ZXLuminanceSource.h"

int const LUMINANCE_BITS = 5;
int const LUMINANCE_SHIFT = 8 - LUMINANCE_BITS;
int const LUMINANCE_BUCKETS = 1 << LUMINANCE_BITS;

@interface ZXGlobalHistogramBinarizer ()

@property (nonatomic, assign) int8_t *luminances;
@property (nonatomic, assign) int luminancesCount;
@property (nonatomic, assign) int *buckets;

@end

@implementation ZXGlobalHistogramBinarizer

- (id)initWithSource:(ZXLuminanceSource *)source {
  if (self = [super initWithSource:source]) {
    _luminances = NULL;
    _luminancesCount = 0;
    _buckets = (int *)malloc(LUMINANCE_BUCKETS * sizeof(int));
  }

  return self;
}

- (void)dealloc {
  if (_luminances != NULL) {
    free(_luminances);
    _luminances = NULL;
  }

  if (_buckets != NULL) {
    free(_buckets);
    _buckets = NULL;
  }
}

- (ZXBitArray *)blackRow:(int)y row:(ZXBitArray *)row error:(NSError **)error {
  ZXLuminanceSource *source = self.luminanceSource;
  int width = source.width;
  if (row == nil || row.size < width) {
    row = [[ZXBitArray alloc] initWithSize:width];
  } else {
    [row clear];
  }

  [self initArrays:width];
  int8_t *localLuminances = [source row:y];
  int *localBuckets = (int *)malloc(LUMINANCE_BUCKETS * sizeof(int));
  memset(localBuckets, 0, LUMINANCE_BUCKETS * sizeof(int));
  for (int x = 0; x < width; x++) {
    int pixel = localLuminances[x] & 0xff;
    localBuckets[pixel >> LUMINANCE_SHIFT]++;
  }
  int blackPoint = [self estimateBlackPoint:localBuckets];
  free(localBuckets);
  localBuckets = NULL;
  if (blackPoint == -1) {
    free(localLuminances);
    if (error) *error = NotFoundErrorInstance();
    return nil;
  }

  int left = localLuminances[0] & 0xff;
  int center = localLuminances[1] & 0xff;
  for (int x = 1; x < width - 1; x++) {
    int right = localLuminances[x + 1] & 0xff;
    int luminance = ((center << 2) - left - right) >> 1;
    if (luminance < blackPoint) {
      [row set:x];
    }
    left = center;
    center = right;
  }

  free(localLuminances);
  return row;
}

- (ZXBitMatrix *)blackMatrixWithError:(NSError **)error {
  ZXLuminanceSource *source = self.luminanceSource;
  int width = source.width;
  int height = source.height;
  ZXBitMatrix *matrix = [[ZXBitMatrix alloc] initWithWidth:width height:height];

  [self initArrays:width];

  int *localBuckets = (int *)malloc(LUMINANCE_BUCKETS * sizeof(int));
  memset(localBuckets, 0, LUMINANCE_BUCKETS * sizeof(int));
  for (int y = 1; y < 5; y++) {
    int row = height * y / 5;
    int8_t *localLuminances = [source row:row];
    int right = (width << 2) / 5;
    for (int x = width / 5; x < right; x++) {
      int pixel = localLuminances[x] & 0xff;
      localBuckets[pixel >> LUMINANCE_SHIFT]++;
    }
  }
  int blackPoint = [self estimateBlackPoint:localBuckets];
  free(localBuckets);
  localBuckets = NULL;

  if (blackPoint == -1) {
    if (error) *error = NotFoundErrorInstance();
    return nil;
  }

  int8_t *localLuminances = source.matrix;
  for (int y = 0; y < height; y++) {
    int offset = y * width;
    for (int x = 0; x < width; x++) {
      int pixel = localLuminances[offset + x] & 0xff;
      if (pixel < blackPoint) {
        [matrix setX:x y:y];
      }
    }
  }

  return matrix;
}

- (ZXBinarizer *)createBinarizer:(ZXLuminanceSource *)source {
  return [[ZXGlobalHistogramBinarizer alloc] initWithSource:source];
}

- (void)initArrays:(int)luminanceSize {
  if (self.luminances == NULL || self.luminancesCount < luminanceSize) {
    if (self.luminances != NULL) {
      free(self.luminances);
    }
    self.luminances = (int8_t *)malloc(luminanceSize * sizeof(int8_t));
    self.luminancesCount = luminanceSize;
  }

  for (int x = 0; x < LUMINANCE_BUCKETS; x++) {
    self.buckets[x] = 0;
  }
}

- (int)estimateBlackPoint:(int *)otherBuckets {
  int numBuckets = LUMINANCE_BUCKETS;
  int maxBucketCount = 0;
  int firstPeak = 0;
  int firstPeakSize = 0;

  for (int x = 0; x < numBuckets; x++) {
    if (otherBuckets[x] > firstPeakSize) {
      firstPeak = x;
      firstPeakSize = otherBuckets[x];
    }
    if (otherBuckets[x] > maxBucketCount) {
      maxBucketCount = otherBuckets[x];
    }
  }

  int secondPeak = 0;
  int secondPeakScore = 0;
  for (int x = 0; x < numBuckets; x++) {
    int distanceToBiggest = x - firstPeak;
    int score = otherBuckets[x] * distanceToBiggest * distanceToBiggest;
    if (score > secondPeakScore) {
      secondPeak = x;
      secondPeakScore = score;
    }
  }

  if (firstPeak > secondPeak) {
    int temp = firstPeak;
    firstPeak = secondPeak;
    secondPeak = temp;
  }

  if (secondPeak - firstPeak <= numBuckets >> 4) {
    return -1;
  }

  int bestValley = secondPeak - 1;
  int bestValleyScore = -1;
  for (int x = secondPeak - 1; x > firstPeak; x--) {
    int fromFirst = x - firstPeak;
    int score = fromFirst * fromFirst * (secondPeak - x) * (maxBucketCount - otherBuckets[x]);
    if (score > bestValleyScore) {
      bestValley = x;
      bestValleyScore = score;
    }
  }

  return bestValley << LUMINANCE_SHIFT;
}

@end
