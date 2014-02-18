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

#import "ZXAztecReader.h"
#import "ZXBinaryBitmap.h"
#import "ZXDataMatrixReader.h"
#import "ZXDecodeHints.h"
#import "ZXErrors.h"
#import "ZXMaxiCodeReader.h"
#import "ZXMultiFormatOneDReader.h"
#import "ZXMultiFormatReader.h"
#import "ZXPDF417Reader.h"
#import "ZXQRCodeReader.h"
#import "ZXResult.h"

@interface ZXMultiFormatReader ()

@property (nonatomic, strong) NSMutableArray *readers;

@end

@implementation ZXMultiFormatReader

- (id)init {
  if (self = [super init]) {
    _readers = [NSMutableArray array];
  }

  return self;
}

+ (id)reader {
  return [[ZXMultiFormatReader alloc] init];
}

/**
 * This version of decode honors the intent of Reader.decode(BinaryBitmap) in that it
 * passes null as a hint to the decoders. However, that makes it inefficient to call repeatedly.
 * Use setHints() followed by decodeWithState() for continuous scan applications.
 */
- (ZXResult *)decode:(ZXBinaryBitmap *)image error:(NSError **)error {
  self.hints = nil;
  return [self decodeInternal:image error:error];
}


/**
 * Decode an image using the hints provided. Does not honor existing state.
 */
- (ZXResult *)decode:(ZXBinaryBitmap *)image hints:(ZXDecodeHints *)hints error:(NSError **)error {
  self.hints = hints;
  return [self decodeInternal:image error:error];
}

/**
 * Decode an image using the state set up by calling setHints() previously. Continuous scan
 * clients will get a <b>large</b> speed increase by using this instead of decode().
 */
- (ZXResult *)decodeWithState:(ZXBinaryBitmap *)image error:(NSError **)error {
  if (self.readers == nil) {
    self.hints = nil;
  }
  return [self decodeInternal:image error:error];
}

/**
 * This method adds state to the ZXMultiFormatReader. By setting the hints once, subsequent calls
 * to decodeWithState(image) can reuse the same set of readers without reallocating memory. This
 * is important for performance in continuous scan clients.
 */
- (void)setHints:(ZXDecodeHints *)hints {
  _hints = hints;

  BOOL tryHarder = hints != nil && hints.tryHarder;
  [self.readers removeAllObjects];
  if (hints != nil) {
    BOOL addZXOneDReader = [hints containsFormat:kBarcodeFormatUPCA] ||
      [hints containsFormat:kBarcodeFormatUPCE] ||
      [hints containsFormat:kBarcodeFormatEan13] ||
      [hints containsFormat:kBarcodeFormatEan8] ||
      [hints containsFormat:kBarcodeFormatCodabar] ||
      [hints containsFormat:kBarcodeFormatCode39] ||
      [hints containsFormat:kBarcodeFormatCode93] ||
      [hints containsFormat:kBarcodeFormatCode128] ||
      [hints containsFormat:kBarcodeFormatITF] ||
      [hints containsFormat:kBarcodeFormatRSS14] ||
      [hints containsFormat:kBarcodeFormatRSSExpanded];
    if (addZXOneDReader && !tryHarder) {
      [self.readers addObject:[[ZXMultiFormatOneDReader alloc] initWithHints:hints]];
    }
    if ([hints containsFormat:kBarcodeFormatQRCode]) {
      [self.readers addObject:[[ZXQRCodeReader alloc] init]];
    }
    if ([hints containsFormat:kBarcodeFormatDataMatrix]) {
      [self.readers addObject:[[ZXDataMatrixReader alloc] init]];
    }
    if ([hints containsFormat:kBarcodeFormatAztec]) {
      [self.readers addObject:[[ZXAztecReader alloc] init]];
    }
    if ([hints containsFormat:kBarcodeFormatPDF417]) {
      [self.readers addObject:[[ZXPDF417Reader alloc] init]];
    }
    if ([hints containsFormat:kBarcodeFormatMaxiCode]) {
      [self.readers addObject:[[ZXMaxiCodeReader alloc] init]];
    }
    if (addZXOneDReader && tryHarder) {
      [self.readers addObject:[[ZXMultiFormatOneDReader alloc] initWithHints:hints]];
    }
  }
  if ([self.readers count] == 0) {
    if (!tryHarder) {
      [self.readers addObject:[[ZXMultiFormatOneDReader alloc] initWithHints:hints]];
    }
    [self.readers addObject:[[ZXQRCodeReader alloc] init]];
    [self.readers addObject:[[ZXDataMatrixReader alloc] init]];
    [self.readers addObject:[[ZXAztecReader alloc] init]];
    [self.readers addObject:[[ZXPDF417Reader alloc] init]];
    [self.readers addObject:[[ZXMaxiCodeReader alloc] init]];
    if (tryHarder) {
      [self.readers addObject:[[ZXMultiFormatOneDReader alloc] initWithHints:hints]];
    }
  }
}

- (void)reset {
  if (self.readers != nil) {
    for (id<ZXReader> reader in self.readers) {
      [reader reset];
    }
  }
}

- (ZXResult *)decodeInternal:(ZXBinaryBitmap *)image error:(NSError **)error {
  if (self.readers != nil) {
    for (id<ZXReader> reader in self.readers) {
      ZXResult *result = [reader decode:image hints:self.hints error:nil];
      if (result) {
        return result;
      }
    }
  }

  if (error) *error = NotFoundErrorInstance();
  return nil;
}

@end
