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

#import "ZXParsedResult.h"

@interface ZXGeoParsedResult : ZXParsedResult

@property (nonatomic, readonly) double latitude;
@property (nonatomic, readonly) double longitude;
@property (nonatomic, readonly) double altitude;
@property (nonatomic, copy, readonly) NSString *query;

- (id)initWithLatitude:(double)latitude longitude:(double)longitude altitude:(double)altitude query:(NSString *)query;
+ (id)geoParsedResultWithLatitude:(double)latitude longitude:(double)longitude altitude:(double)altitude query:(NSString *)query;
- (NSString *)geoURI;

@end
