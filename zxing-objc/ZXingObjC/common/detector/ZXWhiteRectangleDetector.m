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
#import "ZXMathUtils.h"
#import "ZXWhiteRectangleDetector.h"

@interface ZXWhiteRectangleDetector ()

@property (nonatomic, strong) ZXBitMatrix *image;
@property (nonatomic, assign) int height;
@property (nonatomic, assign) int width;
@property (nonatomic, assign) int leftInit;
@property (nonatomic, assign) int rightInit;
@property (nonatomic, assign) int downInit;
@property (nonatomic, assign) int upInit;

@end

int const INIT_SIZE = 30;
int const CORR = 1;

@implementation ZXWhiteRectangleDetector

- (id)initWithImage:(ZXBitMatrix *)image error:(NSError **)error {
  if (self = [super init]) {
    _image = image;
    _height = image.height;
    _width = image.width;
    _leftInit = (_width - INIT_SIZE) >> 1;
    _rightInit = (_width + INIT_SIZE) >> 1;
    _upInit = (_height - INIT_SIZE) >> 1;
    _downInit = (_height + INIT_SIZE) >> 1;
    if (_upInit < 0 || _leftInit < 0 || _downInit >= _height || _rightInit >= _width) {
      if (error) *error = NotFoundErrorInstance();
      return nil;
    }
  }

  return self;
}

- (id)initWithImage:(ZXBitMatrix *)image initSize:(int)initSize x:(int)x y:(int)y error:(NSError **)error {
  if (self = [super init]) {
    _image = image;
    _height = image.height;
    _width = image.width;
    int halfsize = initSize >> 1;
    _leftInit = x - halfsize;
    _rightInit = x + halfsize;
    _upInit = y - halfsize;
    _downInit = y + halfsize;
    if (_upInit < 0 || _leftInit < 0 || _downInit >= _height || _rightInit >= _width) {
      if (error) *error = NotFoundErrorInstance();
      return nil;
    }
  }

  return self;
}

/**
 * Detects a candidate barcode-like rectangular region within an image. It
 * starts around the center of the image, increases the size of the candidate
 * region until it finds a white rectangular region.
 * 
 * Returns a ResultPoint NSArray describing the corners of the rectangular
 * region. The first and last points are opposed on the diagonal, as
 * are the second and third. The first point will be the topmost
 * point and the last, the bottommost. The second point will be
 * leftmost and the third, the rightmost
 */
- (NSArray *)detectWithError:(NSError **)error {
  int left = self.leftInit;
  int right = self.rightInit;
  int up = self.upInit;
  int down = self.downInit;
  BOOL sizeExceeded = NO;
  BOOL aBlackPointFoundOnBorder = YES;
  BOOL atLeastOneBlackPointFoundOnBorder = NO;

  while (aBlackPointFoundOnBorder) {
    aBlackPointFoundOnBorder = NO;

    // .....
    // .   |
    // .....
    BOOL rightBorderNotWhite = YES;
    while (rightBorderNotWhite && right < self.width) {
      rightBorderNotWhite = [self containsBlackPoint:up b:down fixed:right horizontal:NO];
      if (rightBorderNotWhite) {
        right++;
        aBlackPointFoundOnBorder = YES;
      }
    }

    if (right >= self.width) {
      sizeExceeded = YES;
      break;
    }

    // .....
    // .   .
    // .___.
    BOOL bottomBorderNotWhite = YES;
    while (bottomBorderNotWhite && down < self.height) {
      bottomBorderNotWhite = [self containsBlackPoint:left b:right fixed:down horizontal:YES];
      if (bottomBorderNotWhite) {
        down++;
        aBlackPointFoundOnBorder = YES;
      }
    }

    if (down >= self.height) {
      sizeExceeded = YES;
      break;
    }

    // .....
    // |   .
    // .....
    BOOL leftBorderNotWhite = YES;
    while (leftBorderNotWhite && left >= 0) {
      leftBorderNotWhite = [self containsBlackPoint:up b:down fixed:left horizontal:NO];
      if (leftBorderNotWhite) {
        left--;
        aBlackPointFoundOnBorder = YES;
      }
    }

    if (left < 0) {
      sizeExceeded = YES;
      break;
    }

    // .___.
    // .   .
    // .....
    BOOL topBorderNotWhite = YES;
    while (topBorderNotWhite && up >= 0) {
      topBorderNotWhite = [self containsBlackPoint:left b:right fixed:up horizontal:YES];
      if (topBorderNotWhite) {
        up--;
        aBlackPointFoundOnBorder = YES;
      }
    }

    if (up < 0) {
      sizeExceeded = YES;
      break;
    }

    if (aBlackPointFoundOnBorder) {
      atLeastOneBlackPointFoundOnBorder = YES;
    }
  }

  if (!sizeExceeded && atLeastOneBlackPointFoundOnBorder) {
    int maxSize = right - left;

    ZXResultPoint *z = nil;
    for (int i = 1; i < maxSize; i++) {
      z = [self blackPointOnSegment:left aY:down - i bX:left + i bY:down];
      if (z != nil) {
        break;
      }
    }

    if (z == nil) {
      if (error) *error = NotFoundErrorInstance();
      return nil;
    }

    ZXResultPoint *t = nil;
    for (int i = 1; i < maxSize; i++) {
      t = [self blackPointOnSegment:left aY:up + i bX:left + i bY:up];
      if (t != nil) {
        break;
      }
    }

    if (t == nil) {
      if (error) *error = NotFoundErrorInstance();
      return nil;
    }

    ZXResultPoint *x = nil;
    for (int i = 1; i < maxSize; i++) {
      x = [self blackPointOnSegment:right aY:up + i bX:right - i bY:up];
      if (x != nil) {
        break;
      }
    }

    if (x == nil) {
      if (error) *error = NotFoundErrorInstance();
      return nil;
    }

    ZXResultPoint *y = nil;
    for (int i = 1; i < maxSize; i++) {
      y = [self blackPointOnSegment:right aY:down - i bX:right - i bY:down];
      if (y != nil) {
        break;
      }
    }

    if (y == nil) {
      if (error) *error = NotFoundErrorInstance();
      return nil;
    }
    return [self centerEdges:y z:z x:x t:t];
  } else {
    if (error) *error = NotFoundErrorInstance();
    return nil;
  }
}


- (ZXResultPoint *)blackPointOnSegment:(float)aX aY:(float)aY bX:(float)bX bY:(float)bY {
  int dist = [ZXMathUtils round:[ZXMathUtils distance:aX aY:aY bX:bX bY:bY]];
  float xStep = (bX - aX) / dist;
  float yStep = (bY - aY) / dist;

  for (int i = 0; i < dist; i++) {
    int x = [ZXMathUtils round:aX + i * xStep];
    int y = [ZXMathUtils round:aY + i * yStep];
    if ([self.image getX:x y:y]) {
      return [[ZXResultPoint alloc] initWithX:x y:y];
    }
  }

  return nil;
}

/**
 * recenters the points of a constant distance towards the center
 *
 * returns a ResultPoint NSArray describing the corners of the rectangular
 * region. The first and last points are opposed on the diagonal, as
 * are the second and third. The first point will be the topmost
 * point and the last, the bottommost. The second point will be
 * leftmost and the third, the rightmost
 */
- (NSArray *)centerEdges:(ZXResultPoint *)y z:(ZXResultPoint *)z x:(ZXResultPoint *)x t:(ZXResultPoint *)t {
  //
  //       t            t
  //  z                      x
  //        x    OR    z
  //   y                    y
  //

  float yi = y.x;
  float yj = y.y;
  float zi = z.x;
  float zj = z.y;
  float xi = x.x;
  float xj = x.y;
  float ti = t.x;
  float tj = t.y;

  if (yi < self.width / 2.0f) {
    return @[[[ZXResultPoint alloc] initWithX:ti - CORR y:tj + CORR],
             [[ZXResultPoint alloc] initWithX:zi + CORR y:zj + CORR],
             [[ZXResultPoint alloc] initWithX:xi - CORR y:xj - CORR],
             [[ZXResultPoint alloc] initWithX:yi + CORR y:yj - CORR]];
  } else {
    return @[[[ZXResultPoint alloc] initWithX:ti + CORR y:tj + CORR],
             [[ZXResultPoint alloc] initWithX:zi + CORR y:zj - CORR],
             [[ZXResultPoint alloc] initWithX:xi - CORR y:xj + CORR],
             [[ZXResultPoint alloc] initWithX:yi - CORR y:yj - CORR]];
  }
}


/**
 * Determines whether a segment contains a black point
 */
- (BOOL)containsBlackPoint:(int)a b:(int)b fixed:(int)fixed horizontal:(BOOL)horizontal {
  if (horizontal) {
    for (int x = a; x <= b; x++) {
      if ([self.image getX:x y:fixed]) {
        return YES;
      }
    }
  } else {
    for (int y = a; y <= b; y++) {
      if ([self.image getX:fixed y:y]) {
        return YES;
      }
    }
  }

  return NO;
}

@end
