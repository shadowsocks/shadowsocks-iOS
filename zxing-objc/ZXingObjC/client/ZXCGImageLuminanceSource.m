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

#import <CoreVideo/CoreVideo.h>
#import "ZXCGImageLuminanceSource.h"
#import "ZXImage.h"

@implementation ZXCGImageLuminanceSource

+ (CGImageRef)createImageFromBuffer:(CVImageBufferRef)buffer CF_RETURNS_RETAINED {
  return [self createImageFromBuffer:buffer
                                left:0
                                 top:0
                               width:CVPixelBufferGetWidth(buffer)
                              height:CVPixelBufferGetHeight(buffer)];
}

+ (CGImageRef)createImageFromBuffer:(CVImageBufferRef)buffer
                                      left:(size_t)left
                                       top:(size_t)top
                                     width:(size_t)width
                                    height:(size_t)height CF_RETURNS_RETAINED {
  size_t bytesPerRow = CVPixelBufferGetBytesPerRow(buffer);
  size_t dataWidth = CVPixelBufferGetWidth(buffer);
  size_t dataHeight = CVPixelBufferGetHeight(buffer);

  if (left + width > dataWidth ||
      top + height > dataHeight) {
    [NSException raise:NSInvalidArgumentException format:@"Crop rectangle does not fit within image data."];
  }

  size_t newBytesPerRow = ((width*4+0xf)>>4)<<4;

  CVPixelBufferLockBaseAddress(buffer,0); 

  int8_t *baseAddress =
  (int8_t *)CVPixelBufferGetBaseAddress(buffer); 

  size_t size = newBytesPerRow*height;
  int8_t *bytes = (int8_t *)malloc(size * sizeof(int8_t));
  if (newBytesPerRow == bytesPerRow) {
    memcpy(bytes, baseAddress+top*bytesPerRow, size * sizeof(int8_t));
  } else {
    for(int y=0; y<height; y++) {
      memcpy(bytes+y*newBytesPerRow,
             baseAddress+left*4+(top+y)*bytesPerRow,
             newBytesPerRow * sizeof(int8_t));
    }
  }
  CVPixelBufferUnlockBaseAddress(buffer, 0);

  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB(); 
  CGContextRef newContext = CGBitmapContextCreate(bytes,
                                                  width,
                                                  height,
                                                  8,
                                                  newBytesPerRow,
                                                  colorSpace,
                                                  kCGBitmapByteOrder32Little|
                                                  kCGImageAlphaNoneSkipFirst);
  CGColorSpaceRelease(colorSpace);

  CGImageRef result = CGBitmapContextCreateImage(newContext);

  CGContextRelease(newContext);

  free(bytes);

  return result;
}

- (id)initWithZXImage:(ZXImage *)image
                 left:(size_t)left
                  top:(size_t)top
                width:(size_t)width
               height:(size_t)height {
  return [self initWithCGImage:image.cgimage left:left top:top width:width height:height];
}

- (id)initWithZXImage:(ZXImage *)image {
  return [self initWithCGImage:image.cgimage];
}

- (id)initWithCGImage:(CGImageRef)image
                 left:(size_t)left
                  top:(size_t)top
                width:(size_t)width
               height:(size_t)height {
  if (self = [super initWithWidth:(int)width height:(int)height]) {
    [self initializeWithImage:image left:left top:top width:width height:height];
  }

  return self;
}

- (id)initWithCGImage:(CGImageRef)image {
  return [self initWithCGImage:image left:0 top:0 width:CGImageGetWidth(image) height:CGImageGetHeight(image)];
}

- (id)initWithBuffer:(CVPixelBufferRef)buffer
                left:(size_t)left
                 top:(size_t)top
               width:(size_t)width
              height:(size_t)height {
  CGImageRef image = [ZXCGImageLuminanceSource createImageFromBuffer:buffer left:left top:top width:width height:height];

  self = [self initWithCGImage:image];

  CGImageRelease(image);

  return self;
}

- (id)initWithBuffer:(CVPixelBufferRef)buffer {
  CGImageRef image = [ZXCGImageLuminanceSource createImageFromBuffer:buffer];

  self = [self initWithCGImage:image];

  CGImageRelease(image);

  return self;
}

- (CGImageRef)image {
  return _image;
}

- (void)dealloc {  
  if (_image) {
    CGImageRelease(_image);
  }
  if (_data) {
    free(_data);
  }
}

- (int8_t *)row:(int)y {
  if (y < 0 || y >= self.height) {
    [NSException raise:NSInvalidArgumentException format:@"Requested row is outside the image: %d", y];
  }

  int8_t *row = (int8_t *)malloc(self.width * sizeof(int8_t));

  int offset = y * self.width;
  memcpy(row, _data + offset, self.width);
  return row;
}

- (int8_t *)matrix {
  int area = self.width * self.height;

  int8_t *result = (int8_t *)malloc(area * sizeof(int8_t));
  memcpy(result, _data, area * sizeof(int8_t));
  return result;
}

- (void)initializeWithImage:(CGImageRef)cgimage left:(size_t)left top:(size_t)top width:(size_t)width height:(size_t)height {
  _data = 0;
  _image = CGImageRetain(cgimage);
  _left = left;
  _top = top;
  size_t sourceWidth = CGImageGetWidth(cgimage);
  size_t sourceHeight = CGImageGetHeight(cgimage);

  if (left + self.width > sourceWidth ||
      top + self.height > sourceHeight) {
    [NSException raise:NSInvalidArgumentException format:@"Crop rectangle does not fit within image data."];
  }

  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  CGContextRef context = CGBitmapContextCreate(0, self.width, self.height, 8, self.width * 4, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedLast);
  CGContextSetAllowsAntialiasing(context, FALSE);
  CGContextSetInterpolationQuality(context, kCGInterpolationNone);

  if (top || left) {
    CGContextClipToRect(context, CGRectMake(0, 0, self.width, self.height));
  }

  CGContextDrawImage(context, CGRectMake(-left, -top, self.width, self.height), self.image);

  uint32_t *pixelData = (uint32_t *) malloc(self.width * self.height * sizeof(uint32_t));
  memcpy(pixelData, CGBitmapContextGetData(context), self.width * self.height * sizeof(uint32_t));
  CGContextRelease(context);
  CGColorSpaceRelease(colorSpace);

  _data = (int8_t *)malloc(self.width * self.height * sizeof(int8_t));

  for (int i = 0; i < self.height * self.width; i++) {
    uint32_t rgbPixel=pixelData[i];

    float red = (rgbPixel>>24)&0xFF;
    float green = (rgbPixel>>16)&0xFF;
    float blue = (rgbPixel>>8)&0xFF;
    float alpha = (float)(rgbPixel & 0xFF) / 255.0f;

    // ImageIO premultiplies all PNGs, so we have to "un-premultiply them":
    // http://code.google.com/p/cocos2d-iphone/issues/detail?id=697#c26
    red = round((red / alpha) - 0.001f);
    green = round((green / alpha) - 0.001f);
    blue = round((blue / alpha) - 0.001f);

    if (red == green && green == blue) {
      _data[i] = red;
    } else {
      _data[i] = (306 * (int)red +
                 601 * (int)green +
                 117 * (int)blue +
                (0x200)) >> 10; // 0x200 = 1<<9, half an lsb of the result to force rounding
    }
  }

  free(pixelData);

  _top = top;
  _left = left;
}

- (BOOL)rotateSupported {
  return YES;
}

- (ZXLuminanceSource *)rotateCounterClockwise {
  double radians = 270.0f * M_PI / 180;

#if TARGET_OS_EMBEDDED || TARGET_IPHONE_SIMULATOR
  radians = -1 * radians;
#endif

  int sourceWidth = self.width;
  int sourceHeight = self.height;

  CGRect imgRect = CGRectMake(0, 0, sourceWidth, sourceHeight);
  CGAffineTransform transform = CGAffineTransformMakeRotation(radians);
  CGRect rotatedRect = CGRectApplyAffineTransform(imgRect, transform);

  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  CGContextRef context = CGBitmapContextCreate(NULL,
                                               rotatedRect.size.width,
                                               rotatedRect.size.height,
                                               CGImageGetBitsPerComponent(self.image),
                                               0,
                                               colorSpace,
                                               kCGBitmapAlphaInfoMask & kCGImageAlphaPremultipliedFirst);
  CGContextSetAllowsAntialiasing(context, FALSE);
  CGContextSetInterpolationQuality(context, kCGInterpolationNone);
  CGColorSpaceRelease(colorSpace);

  CGContextTranslateCTM(context,
                        +(rotatedRect.size.width/2),
                        +(rotatedRect.size.height/2));
  CGContextRotateCTM(context, radians);

  CGContextDrawImage(context, CGRectMake(-imgRect.size.width/2,
                                         -imgRect.size.height/2,
                                         imgRect.size.width,
                                         imgRect.size.height),
                     self.image);

  CGImageRef rotatedImage = CGBitmapContextCreateImage(context);

  CFRelease(context);

  ZXCGImageLuminanceSource *result = [[ZXCGImageLuminanceSource alloc] initWithCGImage:rotatedImage left:_top top:sourceWidth - (_left + self.width) width:self.height height:self.width];

  CGImageRelease(rotatedImage);

  return result;
}

@end
