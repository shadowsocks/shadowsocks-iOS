ZXingObjC
=========

ZXingObjC is a full Objective-C port of [ZXing](http://code.google.com/p/zxing/) ("Zebra Crossing"), a Java barcode image processing library. It is designed to be used on both iOS devices and in Mac applications.

The following barcodes are currently supported for both encoding and decoding:

* UPC-A and UPC-E
* EAN-8 and EAN-13
* Code 39
* Code 93
* Code 128
* ITF
* Codabar
* RSS-14 (all variants)
* QR Code
* Data Matrix
* Aztec ('beta' quality)
* PDF 417 ('alpha' quality)

ZXingObjC currently has feature parity with ZXing version 2.0.

Usage
----

Encoding:

```objc
NSError* error = nil;
ZXMultiFormatWriter* writer = [ZXMultiFormatWriter writer];
ZXBitMatrix* result = [writer encode:@"A string to encode"
                              format:kBarcodeFormatQRCode
                               width:500
                              height:500
                               error:&error];
if (result) {
  CGImageRef image = [[ZXImage imageWithMatrix:result] cgimage];

  // This CGImageRef image can be placed in a UIImage, NSImage, or written to a file.
} else {
  NSString* errorMessage = [error localizedDescription];
}
```

Decoding:

```objc
CGImageRef imageToDecode;  // Given a CGImage in which we are looking for barcodes

ZXLuminanceSource* source = [[[ZXCGImageLuminanceSource alloc] initWithCGImage:imageToDecode] autorelease];
ZXBinaryBitmap* bitmap = [ZXBinaryBitmap binaryBitmapWithBinarizer:[ZXHybridBinarizer binarizerWithSource:source]];

NSError* error = nil;

// There are a number of hints we can give to the reader, including
// possible formats, allowed lengths, and the string encoding.
ZXDecodeHints* hints = [ZXDecodeHints hints];

ZXMultiFormatReader* reader = [ZXMultiFormatReader reader];
ZXResult* result = [reader decode:bitmap
                            hints:hints
                            error:&error];
if (result) {
  // The coded result as a string. The raw data can be accessed with
  // result.rawBytes and result.length.
  NSString* contents = result.text;

  // The barcode format, such as a QR code or UPC-A
  ZXBarcodeFormat format = result.barcodeFormat;
} else {
  // Use error to determine why we didn't get a result, such as a barcode
  // not being found, an invalid checksum, or a format inconsistency.
}
```

Examples
--------

ZXingObjC includes several example applications found in "examples" folder:

* BarcodeScanner - An iOS application that captures video from the camera, scans for barcodes and displays results on screen.
* QrCodeTest - A basic QR code generator that accepts input, encodes it as a QR code, and displays it on screen.

Getting Started
---------------
> As a simpler alternative to adding files directly, you can consider using [CocoaPods](http://cocoapods.org) to add ZXingObjC as a dependency.

1. [Download ZXingObjC](https://github.com/TheLevelUp/ZXingObjC/tarball/master) or clone it from git: `git clone git://github.com/TheLevelUp/ZXingObjC.git`.

2. Drag the ZXingObjC folder onto Xcode. Make sure "Copy items" is checked before clicking "Add".

3. Selecting your project in the left sidebar, select your target, and choose the "Build Phases" tab. Under "Link Binary With Libraries", add the appropriate frameworks for your architecture:

  For an iOS app:
    * AVFoundation.framework
    * CoreGraphics.framework
    * CoreMedia.framework
    * CoreVideo.framework
    * ImageIO.framework
    * QuartzCore.framework

  For a Mac app:
    * ApplicationServices.framework
    * CoreMedia.framework
    * CoreVideo.framework
    * QuartzCore.framework
    * QTKit.framework

4. Import the ZXingObjC framework header:

```obj-c
#import "ZXingObjC.h"
```

License
-------

ZXingObjC is available under the [Apache 2.0 license](http://www.apache.org/licenses/LICENSE-2.0.html).
