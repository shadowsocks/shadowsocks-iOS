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
 * Implements Reed-Solomon decoding, as the name implies.
 * 
 * The algorithm will not be explained here, but the following references were helpful
 * in creating this implementation:
 * 
 * Bruce Maggs.
 * http://www.cs.cmu.edu/afs/cs.cmu.edu/project/pscico-guyb/realworld/www/rs_decode.ps
 * "Decoding Reed-Solomon Codes" (see discussion of Forney's Formula)
 *
 * J.I. Hall. www.mth.msu.edu/~jhall/classes/codenotes/GRS.pdf
 * "Chapter 5. Generalized Reed-Solomon Codes"
 * (see discussion of Euclidean algorithm)
 * 
 * Much credit is due to William Rucklidge since portions of this code are an indirect
 * port of his C++ Reed-Solomon implementation.
 */

@class ZXGenericGF;

@interface ZXReedSolomonDecoder : NSObject

- (id)initWithField:(ZXGenericGF *)field;
- (BOOL)decode:(int *)received receivedLen:(int)receivedLen twoS:(int)twoS error:(NSError **)error;

@end
