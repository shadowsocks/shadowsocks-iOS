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

#import "ZXPlanarYUVLuminanceSource.h"

const int THUMBNAIL_SCALE_FACTOR = 2;

@interface ZXPlanarYUVLuminanceSource ()

@property (nonatomic, assign) int8_t *yuvData;
@property (nonatomic, assign) int yuvDataLen;
@property (nonatomic, assign) int dataWidth;
@property (nonatomic, assign) int dataHeight;
@property (nonatomic, assign) int left;
@property (nonatomic, assign) int top;

@end

@implementation ZXPlanarYUVLuminanceSource

- (id)initWithYuvData:(int8_t *)yuvData yuvDataLen:(int)yuvDataLen dataWidth:(int)dataWidth
           dataHeight:(int)dataHeight left:(int)left top:(int)top width:(int)width height:(int)height
    reverseHorizontal:(BOOL)reverseHorizontal {
  if (self = [super initWithWidth:width height:height]) {
    if (left + width > dataWidth || top + height > dataHeight) {
      [NSException raise:NSInvalidArgumentException format:@"Crop rectangle does not fit within image data."];
    }

    _yuvDataLen = yuvDataLen;
    _yuvData = (int8_t *)malloc(yuvDataLen * sizeof(int8_t));
    memcpy(_yuvData, yuvData, yuvDataLen);
    _dataWidth = dataWidth;
    _dataHeight = dataHeight;
    _left = left;
    _top = top;
    if (reverseHorizontal) {
      [self reverseHorizontal:width height:height];
    }
  }

  return self;
}

- (void)dealloc {
  if (_yuvData != NULL) {
    free(_yuvData);
    _yuvData = NULL;
  }
}

- (int8_t *)row:(int)y {
  if (y < 0 || y >= self.height) {
    [NSException raise:NSInvalidArgumentException
                format:@"Requested row is outside the image: %d", y];
  }
  int8_t *row = (int8_t *)malloc(self.width * sizeof(int8_t));
  int offset = (y + self.top) * self.dataWidth + self.left;
  memcpy(row, self.yuvData + offset, self.width);
  return row;
}

- (int8_t *)matrix {
  int area = self.width * self.height;
  int8_t *matrix = malloc(area * sizeof(int8_t));
  int inputOffset = self.top * self.dataWidth + self.left;

  // If the width matches the full width of the underlying data, perform a single copy.
  if (self.width == self.dataWidth) {
    memcpy(matrix, self.yuvData + inputOffset, area - inputOffset);
    return matrix;
  }

  // Otherwise copy one cropped row at a time.
  for (int y = 0; y < self.height; y++) {
    int outputOffset = y * self.width;
    memcpy(matrix + outputOffset, self.yuvData + inputOffset, self.width);
    inputOffset += self.dataWidth;
  }
  return matrix;
}

- (BOOL)cropSupported {
  return YES;
}

- (ZXLuminanceSource *)crop:(int)left top:(int)top width:(int)width height:(int)height {
  return [[[self class] alloc] initWithYuvData:self.yuvData yuvDataLen:self.yuvDataLen dataWidth:self.dataWidth
                                    dataHeight:self.dataHeight left:self.left + left top:self.top + top
                                         width:width height:height reverseHorizontal:NO];
}

- (int *)renderThumbnail {
  int thumbWidth = self.width / THUMBNAIL_SCALE_FACTOR;
  int thumbHeight = self.height / THUMBNAIL_SCALE_FACTOR;
  int *pixels = (int *)malloc(thumbWidth * thumbHeight * sizeof(int));
  int inputOffset = self.top * self.dataWidth + self.left;

  for (int y = 0; y < self.height; y++) {
    int outputOffset = y * self.width;
    for (int x = 0; x < self.width; x++) {
      int grey = self.yuvData[inputOffset + x * THUMBNAIL_SCALE_FACTOR] & 0xff;
      pixels[outputOffset + x] = 0xFF000000 | (grey * 0x00010101);
    }
    inputOffset += self.dataWidth * THUMBNAIL_SCALE_FACTOR;
  }
  return pixels;
}

- (int)thumbnailWidth {
  return self.width / THUMBNAIL_SCALE_FACTOR;
}

- (int)thumbnailHeight {
  return self.height / THUMBNAIL_SCALE_FACTOR;
}

- (void)reverseHorizontal:(int)_width height:(int)_height {
  for (int y = 0, rowStart = self.top * self.dataWidth + self.left; y < _height; y++, rowStart += self.dataWidth) {
    int middle = rowStart + _width / 2;
    for (int x1 = rowStart, x2 = rowStart + _width - 1; x1 < middle; x1++, x2--) {
      int8_t temp = self.yuvData[x1];
      self.yuvData[x1] = self.yuvData[x2];
      self.yuvData[x2] = temp;
    }
  }
}

@end
