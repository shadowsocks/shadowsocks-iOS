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
 * This class attempts to find alignment patterns in a QR Code. Alignment patterns look like finder
 * patterns but are smaller and appear at regular intervals throughout the image.
 * 
 * At the moment this only looks for the bottom-right alignment pattern.
 * 
 * This is mostly a simplified copy of {@link FinderPatternFinder}. It is copied,
 * pasted and stripped down here for maximum performance but does unfortunately duplicate
 * some code.
 * 
 * This class is thread-safe but not reentrant. Each thread must allocate its own object.
 */

@class ZXAlignmentPattern, ZXBitMatrix;
@protocol ZXResultPointCallback;

@interface ZXAlignmentPatternFinder : NSObject

- (id)initWithImage:(ZXBitMatrix *)image startX:(int)startX startY:(int)startY width:(int)width height:(int)height moduleSize:(float)moduleSize resultPointCallback:(id<ZXResultPointCallback>)resultPointCallback;
- (ZXAlignmentPattern *)findWithError:(NSError **)error;

@end
