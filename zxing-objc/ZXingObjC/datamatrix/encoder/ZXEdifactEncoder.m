/*
 * Copyright 2013 ZXing authors
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

#import "ZXEdifactEncoder.h"
#import "ZXEncoderContext.h"
#import "ZXHighLevelEncoder.h"
#import "ZXSymbolInfo.h"

@implementation ZXEdifactEncoder

- (int)encodingMode {
  return [ZXHighLevelEncoder edifactEncodation];
}

- (void)encode:(ZXEncoderContext *)context {
  //step F
  NSMutableString *buffer = [NSMutableString string];
  while ([context hasMoreCharacters]) {
    unichar c = [context currentChar];
    [self encodeChar:c buffer:buffer];
    context.pos++;

    NSUInteger count = buffer.length;
    if (count >= 4) {
      [context writeCodewords:[self encodeToCodewords:buffer startpos:0]];
      [buffer deleteCharactersInRange:NSMakeRange(0, 4)];

      int newMode = [ZXHighLevelEncoder lookAheadTest:context.message startpos:context.pos currentMode:[self encodingMode]];
      if (newMode != [self encodingMode]) {
        [context signalEncoderChange:[ZXHighLevelEncoder asciiEncodation]];
        break;
      }
    }
  }
  [buffer appendFormat:@"%C", (unichar) 31]; //Unlatch
  [self handleEOD:context buffer:buffer];
}

/**
 * Handle "end of data" situations
 */
- (void)handleEOD:(ZXEncoderContext *)context buffer:(NSMutableString *)buffer {
  @try {
    NSUInteger count = buffer.length;
    if (count == 0) {
      return; //Already finished
    }
    if (count == 1) {
      //Only an unlatch at the end
      [context updateSymbolInfo];
      int available = context.symbolInfo.dataCapacity - context.codewordCount;
      int remaining = [context remainingCharacters];
      if (remaining == 0 && available <= 2) {
        return; //No unlatch
      }
    }

    if (count > 4) {
      @throw [NSException exceptionWithName:@"IllegalStateException"
                                     reason:@"Count must not exceed 4"
                                   userInfo:nil];
    }
    int restChars = (int)count - 1;
    NSString *encoded = [self encodeToCodewords:buffer startpos:0];
    BOOL endOfSymbolReached = ![context hasMoreCharacters];
    BOOL restInAscii = endOfSymbolReached && restChars <= 2;

    if (restChars <= 2) {
      [context updateSymbolInfoWithLength:context.codewordCount + restChars];
      int available = context.symbolInfo.dataCapacity - context.codewordCount;
      if (available >= 3) {
        restInAscii = NO;
        [context updateSymbolInfoWithLength:context.codewordCount + (int)encoded.length];
        //available = context.symbolInfo.dataCapacity - context.codewordCount;
      }
    }

    if (restInAscii) {
      [context resetSymbolInfo];
      context.pos -= restChars;
    } else {
      [context writeCodewords:encoded];
    }
  } @finally {
    [context signalEncoderChange:[ZXHighLevelEncoder asciiEncodation]];
  }
}

- (void)encodeChar:(unichar)c buffer:(NSMutableString *)sb {
  if (c >= ' ' && c <= '?') {
    [sb appendFormat:@"%C", c];
  } else if (c >= '@' && c <= '^') {
    [sb appendFormat:@"%C", (unichar) (c - 64)];
  } else {
    [ZXHighLevelEncoder illegalCharacter:c];
  }
}

- (NSString *)encodeToCodewords:(NSMutableString *)sb startpos:(int)startPos {
  int len = (int)sb.length - startPos;
  if (len == 0) {
    @throw [NSException exceptionWithName:@"IllegalStateException"
                                   reason:@"Buffer must not be empty"
                                 userInfo:nil];
  }
  unichar c1 = [sb characterAtIndex:startPos];
  unichar c2 = len >= 2 ? [sb characterAtIndex:startPos + 1] : 0;
  unichar c3 = len >= 3 ? [sb characterAtIndex:startPos + 2] : 0;
  unichar c4 = len >= 4 ? [sb characterAtIndex:startPos + 3] : 0;

  int v = (c1 << 18) + (c2 << 12) + (c3 << 6) + c4;
  unichar cw1 = (unichar) ((v >> 16) & 255);
  unichar cw2 = (unichar) ((v >> 8) & 255);
  unichar cw3 = (unichar) (v & 255);
  NSMutableString *res = [NSMutableString stringWithCapacity:3];
  [res appendFormat:@"%C", cw1];
  if (len >= 2) {
    [res appendFormat:@"%C", cw2];
  }
  if (len >= 3) {
    [res appendFormat:@"%C", cw3];
  }
  return [NSString stringWithString:res];
}

@end
