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

#import "ZXEmailAddressParsedResult.h"
#import "ZXParsedResultType.h"

@implementation ZXEmailAddressParsedResult

- (id)initWithEmailAddress:(NSString *)emailAddress subject:(NSString *)subject body:(NSString *)body mailtoURI:(NSString *)mailtoURI {
  if (self = [super initWithType:kParsedResultTypeEmailAddress]) {
    _emailAddress = emailAddress;
    _subject = subject;
    _body = body;
    _mailtoURI = mailtoURI;
  }

  return self;
}

+ (id)emailAddressParsedResultWithEmailAddress:(NSString *)emailAddress subject:(NSString *)subject body:(NSString *)body mailtoURI:(NSString *)mailtoURI {
  return [[self alloc] initWithEmailAddress:emailAddress subject:subject body:body mailtoURI:mailtoURI];
}

- (NSString *)displayResult {
  NSMutableString *result = [NSMutableString stringWithCapacity:30];
  [ZXParsedResult maybeAppend:self.emailAddress result:result];
  [ZXParsedResult maybeAppend:self.subject result:result];
  [ZXParsedResult maybeAppend:self.body result:result];
  return result;
}

@end
