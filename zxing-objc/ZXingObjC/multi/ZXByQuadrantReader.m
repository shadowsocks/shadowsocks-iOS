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
#import "ZXByQuadrantReader.h"
#import "ZXDecodeHints.h"
#import "ZXErrors.h"
#import "ZXResult.h"

@interface ZXByQuadrantReader ()

@property (nonatomic, weak) id<ZXReader> delegate;

@end

@implementation ZXByQuadrantReader

- (id)initWithDelegate:(id<ZXReader>)delegate {
  if (self = [super init]) {
    _delegate = delegate;
  }

  return self;
}

- (ZXResult *)decode:(ZXBinaryBitmap *)image error:(NSError **)error {
  return [self decode:image hints:nil error:error];
}

- (ZXResult *)decode:(ZXBinaryBitmap *)image hints:(ZXDecodeHints *)hints error:(NSError **)error {
  int width = image.width;
  int height = image.height;
  int halfWidth = width / 2;
  int halfHeight = height / 2;

  ZXBinaryBitmap *topLeft = [image crop:0 top:0 width:halfWidth height:halfHeight];
  NSError *decodeError = nil;
  ZXResult *result = [self.delegate decode:topLeft hints:hints error:&decodeError];
  if (result) {
    return result;
  } else if (decodeError.code != ZXNotFoundError) {
    if (error) *error = decodeError;
    return nil;
  }

  ZXBinaryBitmap *topRight = [image crop:halfWidth top:0 width:halfWidth height:halfHeight];
  decodeError = nil;
  result = [self.delegate decode:topRight hints:hints error:&decodeError];
  if (result) {
    return result;
  } else if (decodeError.code != ZXNotFoundError) {
    if (error) *error = decodeError;
    return nil;
  }

  ZXBinaryBitmap *bottomLeft = [image crop:0 top:halfHeight width:halfWidth height:halfHeight];
  decodeError = nil;
  result = [self.delegate decode:bottomLeft hints:hints error:&decodeError];
  if (result) {
    return result;
  } else if (decodeError.code != ZXNotFoundError) {
    if (error) *error = decodeError;
    return nil;
  }

  ZXBinaryBitmap *bottomRight = [image crop:halfWidth top:halfHeight width:halfWidth height:halfHeight];
  decodeError = nil;
  result = [self.delegate decode:bottomRight hints:hints error:&decodeError];
  if (result) {
    return result;
  } else if (decodeError.code != ZXNotFoundError) {
    if (error) *error = decodeError;
    return nil;
  }

  int quarterWidth = halfWidth / 2;
  int quarterHeight = halfHeight / 2;
  ZXBinaryBitmap *center = [image crop:quarterWidth top:quarterHeight width:halfWidth height:halfHeight];
  return [self.delegate decode:center hints:hints error:error];
}

- (void)reset {
  [self.delegate reset];
}

@end
