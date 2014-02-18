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

#import "ZXASCIIEncoder.h"
#import "ZXEncoderContext.h"
#import "ZXHighLevelEncoder.h"

@implementation ZXASCIIEncoder

- (int)encodingMode {
  return [ZXHighLevelEncoder asciiEncodation];
}

- (void)encode:(ZXEncoderContext *)context {
  //step B
  int n = [ZXHighLevelEncoder determineConsecutiveDigitCount:context.message startpos:context.pos];
  if (n >= 2) {
    [context writeCodeword:[self encodeASCIIDigits:[context.message characterAtIndex:context.pos]
                                            digit2:[context.message characterAtIndex:context.pos + 1]]];
    context.pos += 2;
  } else {
    unichar c = [context currentChar];
    int newMode = [ZXHighLevelEncoder lookAheadTest:context.message startpos:context.pos currentMode:[self encodingMode]];
    if (newMode != [self encodingMode]) {
      if (newMode == [ZXHighLevelEncoder base256Encodation]) {
        [context writeCodeword:[ZXHighLevelEncoder latchToBase256]];
        [context signalEncoderChange:[ZXHighLevelEncoder base256Encodation]];
        return;
      } else if (newMode == [ZXHighLevelEncoder c40Encodation]) {
        [context writeCodeword:[ZXHighLevelEncoder latchToC40]];
        [context signalEncoderChange:[ZXHighLevelEncoder c40Encodation]];
        return;
      } else if (newMode == [ZXHighLevelEncoder x12Encodation]) {
        [context writeCodeword:[ZXHighLevelEncoder latchToAnsiX12]];
        [context signalEncoderChange:[ZXHighLevelEncoder x12Encodation]];
      } else if (newMode == [ZXHighLevelEncoder textEncodation]) {
        [context writeCodeword:[ZXHighLevelEncoder latchToText]];
        [context signalEncoderChange:[ZXHighLevelEncoder textEncodation]];
      } else if (newMode == [ZXHighLevelEncoder edifactEncodation]) {
        [context writeCodeword:[ZXHighLevelEncoder latchToEdifact]];
        [context signalEncoderChange:[ZXHighLevelEncoder edifactEncodation]];
      } else {
        @throw [NSException exceptionWithName:@"IllegalStateException" reason:@"Illegal mode" userInfo:nil];
      }
    } else if ([ZXHighLevelEncoder isExtendedASCII:c]) {
      [context writeCodeword:[ZXHighLevelEncoder upperShift]];
      [context writeCodeword:(unichar)(c - 128 + 1)];
      context.pos++;
    } else {
      [context writeCodeword:(unichar)(c + 1)];
      context.pos++;
    }
  }
}

- (unichar)encodeASCIIDigits:(unichar)digit1 digit2:(unichar)digit2 {
  if ([ZXHighLevelEncoder isDigit:digit1] && [ZXHighLevelEncoder isDigit:digit2]) {
    int num = (digit1 - 48) * 10 + (digit2 - 48);
    return (unichar) (num + 130);
  }
  @throw [NSException exceptionWithName:NSInvalidArgumentException
                                 reason:[NSString stringWithFormat:@"not digits: %C %C", digit1, digit2]
                               userInfo:nil];
}

@end
