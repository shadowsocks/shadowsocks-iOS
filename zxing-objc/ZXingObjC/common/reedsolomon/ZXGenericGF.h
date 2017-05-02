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

/**
 * This class contains utility methods for performing mathematical operations over
 * the Galois Fields. Operations use a given primitive polynomial in calculations.
 * 
 * Throughout this package, elements of the GF are represented as an int
 * for convenience and speed (but at the cost of memory).
 */

@class ZXGenericGFPoly;

@interface ZXGenericGF : NSObject

@property (nonatomic, strong, readonly) ZXGenericGFPoly *zero;
@property (nonatomic, strong, readonly) ZXGenericGFPoly *one;
@property (nonatomic, assign, readonly) int size;
@property (nonatomic, assign, readonly) int generatorBase;

+ (ZXGenericGF *)AztecData12;
+ (ZXGenericGF *)AztecData10;
+ (ZXGenericGF *)AztecData6;
+ (ZXGenericGF *)AztecParam;
+ (ZXGenericGF *)QrCodeField256;
+ (ZXGenericGF *)DataMatrixField256;
+ (ZXGenericGF *)AztecData8;
+ (ZXGenericGF *)MaxiCodeField64;

- (id)initWithPrimitive:(int)primitive size:(int)size b:(int)b;
- (ZXGenericGFPoly *)buildMonomial:(int)degree coefficient:(int)coefficient;
+ (int)addOrSubtract:(int)a b:(int)b;
- (int)exp:(int)a;
- (int)log:(int)a;
- (int)inverse:(int)a;
- (int)multiply:(int)a b:(int)b;

@end
