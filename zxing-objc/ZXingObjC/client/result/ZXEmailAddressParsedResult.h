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

@interface ZXEmailAddressParsedResult : ZXParsedResult

@property (nonatomic, copy, readonly) NSString *body;
@property (nonatomic, copy, readonly) NSString *emailAddress;
@property (nonatomic, copy, readonly) NSString *mailtoURI;
@property (nonatomic, copy, readonly) NSString *subject;

- (id)initWithEmailAddress:(NSString *)emailAddress subject:(NSString *)subject body:(NSString *)body
                 mailtoURI:(NSString *)mailtoURI;
+ (id)emailAddressParsedResultWithEmailAddress:(NSString *)emailAddress subject:(NSString *)subject
                                          body:(NSString *)body mailtoURI:(NSString *)mailtoURI;

@end
