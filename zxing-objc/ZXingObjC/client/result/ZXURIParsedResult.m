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

#import "ZXURIParsedResult.h"

static NSRegularExpression *USER_IN_HOST = nil;

@implementation ZXURIParsedResult

+ (void)initialize {
  USER_IN_HOST = [[NSRegularExpression alloc] initWithPattern:@":/*([^/@]+)@[^/]+" options:0 error:nil];
}

- (id)initWithUri:(NSString *)uri title:(NSString *)title {
  if (self = [super initWithType:kParsedResultTypeURI]) {
    _uri = [self massageURI:uri];
    _title = title;
  }

  return self;
}

+ (id)uriParsedResultWithUri:(NSString *)uri title:(NSString *)title {
  return [[self alloc] initWithUri:uri title:title];
}

/**
 * Returns true if the URI contains suspicious patterns that may suggest it intends to
 * mislead the user about its true nature. At the moment this looks for the presence
 * of user/password syntax in the host/authority portion of a URI which may be used
 * in attempts to make the URI's host appear to be other than it is. Example:
 * http://yourbank.com@phisher.com  This URI connects to phisher.com but may appear
 * to connect to yourbank.com at first glance.
 */
- (BOOL)possiblyMaliciousURI {
  return [USER_IN_HOST numberOfMatchesInString:self.uri options:0 range:NSMakeRange(0, self.uri.length)] > 0;
}

- (NSString *)displayResult {
  NSMutableString *result = [NSMutableString stringWithCapacity:30];
  [ZXParsedResult maybeAppend:self.title result:result];
  [ZXParsedResult maybeAppend:self.uri result:result];
  return result;
}

/**
 * Transforms a string that represents a URI into something more proper, by adding or canonicalizing
 * the protocol.
 */
- (NSString *)massageURI:(NSString *)uri {
  NSString *massagedUri = [uri stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  NSUInteger protocolEnd = [massagedUri rangeOfString:@":"].location;
  if (protocolEnd == NSNotFound) {
    // No protocol, assume http
    massagedUri = [NSString stringWithFormat:@"http://%@", massagedUri];
  } else if ([self isColonFollowedByPortNumber:massagedUri protocolEnd:(int)protocolEnd]) {
    // Found a colon, but it looks like it is after the host, so the protocol is still missing
    massagedUri = [NSString stringWithFormat:@"http://%@", massagedUri];
  }
  return massagedUri;
}

- (BOOL)isColonFollowedByPortNumber:(NSString *)aUri protocolEnd:(int)protocolEnd {
  NSUInteger nextSlash = [aUri rangeOfString:@"/" options:0 range:NSMakeRange(protocolEnd + 1, [aUri length] - protocolEnd - 1)].location;
  if (nextSlash == NSNotFound) {
    nextSlash = [aUri length];
  }
  if (nextSlash <= protocolEnd + 1) {
    return NO;
  }

  for (int x = protocolEnd + 1; x < nextSlash; x++) {
    if ([aUri characterAtIndex:x] < '0' || [aUri characterAtIndex:x] > '9') {
      return NO;
    }
  }

  return YES;
}

@end
