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

#import "ZXAddressBookAUResultParser.h"
#import "ZXAddressBookDoCoMoResultParser.h"
#import "ZXAddressBookParsedResult.h"
#import "ZXBizcardResultParser.h"
#import "ZXBookmarkDoCoMoResultParser.h"
#import "ZXCalendarParsedResult.h"
#import "ZXEmailAddressParsedResult.h"
#import "ZXEmailAddressResultParser.h"
#import "ZXEmailDoCoMoResultParser.h"
#import "ZXExpandedProductParsedResult.h"
#import "ZXExpandedProductResultParser.h"
#import "ZXGeoParsedResult.h"
#import "ZXGeoResultParser.h"
#import "ZXISBNParsedResult.h"
#import "ZXISBNResultParser.h"
#import "ZXParsedResult.h"
#import "ZXProductParsedResult.h"
#import "ZXProductResultParser.h"
#import "ZXResult.h"
#import "ZXResultParser.h"
#import "ZXSMSMMSResultParser.h"
#import "ZXSMSParsedResult.h"
#import "ZXSMSTOMMSTOResultParser.h"
#import "ZXSMTPResultParser.h"
#import "ZXTelParsedResult.h"
#import "ZXTelResultParser.h"
#import "ZXTextParsedResult.h"
#import "ZXURIParsedResult.h"
#import "ZXURIResultParser.h"
#import "ZXURLTOResultParser.h"
#import "ZXVCardResultParser.h"
#import "ZXVEventResultParser.h"
#import "ZXWifiParsedResult.h"
#import "ZXWifiResultParser.h"

static NSArray *PARSERS = nil;
static NSRegularExpression *DIGITS = nil;
static NSRegularExpression *ALPHANUM = nil;
static NSString *AMPERSAND = @"&";
static NSString *EQUALS = @"=";
static unichar BYTE_ORDER_MARK = L'\ufeff';

@implementation ZXResultParser

+ (void)initialize {
  PARSERS = @[[[ZXBookmarkDoCoMoResultParser alloc] init],
              [[ZXAddressBookDoCoMoResultParser alloc] init],
              [[ZXEmailDoCoMoResultParser alloc] init],
              [[ZXAddressBookAUResultParser alloc] init],
              [[ZXVCardResultParser alloc] init],
              [[ZXBizcardResultParser alloc] init],
              [[ZXVEventResultParser alloc] init],
              [[ZXEmailAddressResultParser alloc] init],
              [[ZXSMTPResultParser alloc] init],
              [[ZXTelResultParser alloc] init],
              [[ZXSMSMMSResultParser alloc] init],
              [[ZXSMSTOMMSTOResultParser alloc] init],
              [[ZXGeoResultParser alloc] init],
              [[ZXWifiResultParser alloc] init],
              [[ZXURLTOResultParser alloc] init],
              [[ZXURIResultParser alloc] init],
              [[ZXISBNResultParser alloc] init],
              [[ZXProductResultParser alloc] init],
              [[ZXExpandedProductResultParser alloc] init]];
  DIGITS = [[NSRegularExpression alloc] initWithPattern:@"^\\d*$" options:0 error:nil];
  ALPHANUM = [[NSRegularExpression alloc] initWithPattern:@"^[a-zA-Z0-9]*$" options:0 error:nil];
}

+ (NSString *)massagedText:(ZXResult *)result {
  NSString *text = result.text;
  if (text.length > 0 && [text characterAtIndex:0] == BYTE_ORDER_MARK) {
    text = [text substringFromIndex:1];
  }
  return text;
}

- (ZXParsedResult *)parse:(ZXResult *)result {
  @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                 reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                               userInfo:nil];
}

+ (ZXParsedResult *)parseResult:(ZXResult *)theResult {
  for (ZXResultParser *parser in PARSERS) {
    ZXParsedResult *result = [parser parse:theResult];
    if (result != nil) {
      return result;
    }
  }
  return [ZXTextParsedResult textParsedResultWithText:[theResult text] language:nil];
}

- (void)maybeAppend:(NSString *)value result:(NSMutableString *)result {
  if (value != nil) {
    [result appendFormat:@"\n%@", value];
  }
}

- (void)maybeAppendArray:(NSArray *)value result:(NSMutableString *)result {
  if (value != nil) {
    for (NSString *s in value) {
      [result appendFormat:@"\n%@", s];
    }
  }
}

- (NSArray *)maybeWrap:(NSString *)value {
  return value == nil ? nil : @[value];
}

+ (NSString *)unescapeBackslash:(NSString *)escaped {
  NSUInteger backslash = [escaped rangeOfString:@"\\"].location;
  if (backslash == NSNotFound) {
    return escaped;
  }
  NSUInteger max = [escaped length];
  NSMutableString *unescaped = [NSMutableString stringWithCapacity:max - 1];
  [unescaped appendString:[escaped substringToIndex:backslash]];
  BOOL nextIsEscaped = NO;
  for (int i = (int)backslash; i < max; i++) {
    unichar c = [escaped characterAtIndex:i];
    if (nextIsEscaped || c != '\\') {
      [unescaped appendFormat:@"%C", c];
      nextIsEscaped = NO;
    } else {
      nextIsEscaped = YES;
    }
  }
  return unescaped;
}

+ (int)parseHexDigit:(unichar)c {
  if (c >= '0' && c <= '9') {
    return c - '0';
  }
  if (c >= 'a' && c <= 'f') {
    return 10 + (c - 'a');
  }
  if (c >= 'A' && c <= 'F') {
    return 10 + (c - 'A');
  }
  return -1;
}

+ (BOOL)isStringOfDigits:(NSString *)value length:(unsigned int)length {
  return value != nil && length == value.length && [DIGITS numberOfMatchesInString:value options:0 range:NSMakeRange(0, value.length)] > 0;
}

- (NSString *)urlDecode:(NSString *)escaped {
  if (escaped == nil) {
    return nil;
  }

  int first = [self findFirstEscape:escaped];
  if (first == -1) {
    return escaped;
  }

  NSUInteger max = [escaped length];
  NSMutableString *unescaped = [NSMutableString stringWithCapacity:max - 2];
  [unescaped appendString:[escaped substringToIndex:first]];

  for (int i = first; i < max; i++) {
    unichar c = [escaped characterAtIndex:i];
    switch (c) {
      case '+':
        [unescaped appendString:@" "];
        break;
      case '%':
        if (i >= max - 2) {
          [unescaped appendString:@"%"];
        } else {
          int firstDigitValue = [[self class] parseHexDigit:[escaped characterAtIndex:++i]];
          int secondDigitValue = [[self class] parseHexDigit:[escaped characterAtIndex:++i]];
          if (firstDigitValue < 0 || secondDigitValue < 0) {
            [unescaped appendFormat:@"%%%C%C", [escaped characterAtIndex:i - 1], [escaped characterAtIndex:i]];
          }
          [unescaped appendFormat:@"%C", (unichar)((firstDigitValue << 4) + secondDigitValue)];
        }
        break;
      default:
        [unescaped appendFormat:@"%C", c];
        break;
    }
  }

  return unescaped;
}

- (int)findFirstEscape:(NSString *)escaped {
  NSUInteger max = [escaped length];
  for (int i = 0; i < max; i++) {
    unichar c = [escaped characterAtIndex:i];
    if (c == '+' || c == '%') {
      return i;
    }
  }

  return -1;
}

+ (BOOL)isSubstringOfDigits:(NSString *)value offset:(int)offset length:(unsigned int)length {
  if (value == nil) {
    return NO;
  }
  int max = offset + length;
  return value.length >= max && [DIGITS numberOfMatchesInString:value options:0 range:NSMakeRange(offset, max - offset)] > 0;
}

+ (BOOL)isSubstringOfAlphaNumeric:(NSString *)value offset:(int)offset length:(unsigned int)length {
  if (value == nil) {
    return NO;
  }
  int max = offset + length;
  return value.length >= max && [ALPHANUM numberOfMatchesInString:value options:0 range:NSMakeRange(offset, max - offset)] > 0;
}

- (NSMutableDictionary *)parseNameValuePairs:(NSString *)uri {
  NSUInteger paramStart = [uri rangeOfString:@"?"].location;
  if (paramStart == NSNotFound) {
    return nil;
  }
  NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:3];
  for (NSString *keyValue in [[uri substringFromIndex:paramStart + 1] componentsSeparatedByString:AMPERSAND]) {
    [self appendKeyValue:keyValue result:result];
  }
  return result;
}

- (void)appendKeyValue:(NSString *)keyValue result:(NSMutableDictionary *)result {
  NSRange equalsRange = [keyValue rangeOfString:EQUALS];
  if (equalsRange.location != NSNotFound) {
    NSString *key = [keyValue substringToIndex:equalsRange.location];
    NSString *value = [keyValue substringFromIndex:equalsRange.location + 1];
    value = [self urlDecode:value];
    result[key] = value;
  }
}

+ (NSString *)urlDecode:(NSString *)encoded {
  NSString *result = [encoded stringByReplacingOccurrencesOfString:@"+" withString:@" "];
  result = [result stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
  return result;
}

+ (NSArray *)matchPrefixedField:(NSString *)prefix rawText:(NSString *)rawText endChar:(unichar)endChar trim:(BOOL)trim {
  NSMutableArray *matches = nil;
  NSUInteger i = 0;
  NSUInteger max = [rawText length];
  while (i < max) {
    i = [rawText rangeOfString:prefix options:NSLiteralSearch range:NSMakeRange(i, [rawText length] - i - 1)].location;
    if (i == NSNotFound) {
      break;
    }
    i += [prefix length];
    NSUInteger start = i;
    BOOL more = YES;
    while (more) {
      i = [rawText rangeOfString:[NSString stringWithFormat:@"%C", endChar] options:NSLiteralSearch range:NSMakeRange(i, [rawText length] - i)].location;
      if (i == NSNotFound) {
        i = [rawText length];
        more = NO;
      } else if ([rawText characterAtIndex:i - 1] == '\\') {
        i++;
      } else {
        if (matches == nil) {
          matches = [NSMutableArray arrayWithCapacity:3];
        }
        NSString *element = [self unescapeBackslash:[rawText substringWithRange:NSMakeRange(start, i - start)]];
        if (trim) {
          element = [element stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        }
        if (element.length > 0) {
          [matches addObject:element];
        }
        i++;
        more = NO;
      }
    }
  }
  if (matches == nil || [matches count] == 0) {
    return nil;
  }
  return matches;
}

+ (NSString *)matchSinglePrefixedField:(NSString *)prefix rawText:(NSString *)rawText endChar:(unichar)endChar trim:(BOOL)trim {
  NSArray *matches = [self matchPrefixedField:prefix rawText:rawText endChar:endChar trim:trim];
  return matches == nil ? nil : matches[0];
}

@end
