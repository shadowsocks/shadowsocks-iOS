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

#import "ZXBarcodeRow.h"

@interface ZXBarcodeRow ()

@property (nonatomic, assign) int currentLocation;

@end

@implementation ZXBarcodeRow

+ (ZXBarcodeRow *)barcodeRowWithWidth:(int)width {
  return [[ZXBarcodeRow alloc] initWithWidth:width];
}

- (id)initWithWidth:(int)width {
  if (self = [super init]) {
    _rowLength = width;
    _row = (int8_t *)malloc(_rowLength * sizeof(int8_t));
    memset(_row, 0, self.rowLength * sizeof(int8_t));
    _currentLocation = 0;
  }
  return self;
}

- (void)dealloc {
  if (_row != NULL) {
    free(_row);
    _row = NULL;
  }
}

- (void)setX:(int)x value:(int8_t)value {
  self.row[x] = value;
}

- (void)setX:(int)x black:(BOOL)black {
  self.row[x] = (int8_t)(black ? 1 : 0);
}

- (void)addBar:(BOOL)black width:(int)width {
  for (int ii = 0; ii < width; ii++) {
    [self setX:self.currentLocation++ black:black];
  }
}

- (int8_t *)scaledRow:(int)scale {
  int8_t *output = (int8_t *)malloc(self.rowLength * scale);
  for (int i = 0; i < self.rowLength * scale; i++) {
    output[i] = self.row[i / scale];
  }
  return output;
}

@end
