/*
 * Copyright 2006 Jeremias Maerki in part, and ZXing Authors in part
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/**
 * PDF417 error correction code following the algorithm described in ISO/IEC 15438:2001(E) in
 * chapter 4.10.
 */
@interface ZXPDF417ErrorCorrection : NSObject

+ (int)errorCorrectionCodewordCount:(int)errorCorrectionLevel;
+ (int)recommendedMinimumErrorCorrectionLevel:(int)n error:(NSError **)error;
+ (NSString *)generateErrorCorrection:(NSString *)dataCodewords errorCorrectionLevel:(int)errorCorrectionLevel;

@end
