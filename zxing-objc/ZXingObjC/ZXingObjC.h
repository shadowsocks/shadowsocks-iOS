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

#import <Foundation/Foundation.h>

// ZXingObjC/aztec/decoder
#import "ZXAztecDecoder.h"

// ZXingObjC/aztec/detector
#import "ZXAztecDetector.h"

// ZXingObjC/aztec/encoder
#import "ZXAztecCode.h"
#import "ZXAztecEncoder.h"
#import "ZXAztecWriter.h"

// ZXingObjC/aztec
#import "ZXAztecDetectorResult.h"
#import "ZXAztecReader.h"

// ZXingObjC/client/result
#import "ZXAbstractDoCoMoResultParser.h"
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
#import "ZXParsedResultType.h"
#import "ZXProductParsedResult.h"
#import "ZXProductResultParser.h"
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

// ZXingObjC/client
#import "ZXCapture.h"
#import "ZXCaptureDelegate.h"
#import "ZXCaptureView.h"
#import "ZXCGImageLuminanceSource.h"
#import "ZXImage.h"
#import "ZXView.h"

// ZXingObjC/common/detector
#import "ZXMathUtils.h"
#import "ZXMonochromeRectangleDetector.h"
#import "ZXWhiteRectangleDetector.h"

// ZXingObjC/common/reedsolomon
#import "ZXGenericGF.h"
#import "ZXGenericGFPoly.h"
#import "ZXReedSolomonDecoder.h"
#import "ZXReedSolomonEncoder.h"

// ZXingObjC/common
#import "ZXBitArray.h"
#import "ZXBitMatrix.h"
#import "ZXBitSource.h"
#import "ZXCharacterSetECI.h"
#import "ZXDecoderResult.h"
#import "ZXDefaultGridSampler.h"
#import "ZXDetectorResult.h"
#import "ZXECI.h"
#import "ZXGlobalHistogramBinarizer.h"
#import "ZXGridSampler.h"
#import "ZXHybridBinarizer.h"
#import "ZXPerspectiveTransform.h"
#import "ZXStringUtils.h"

// ZXingObjC/datamatrix/decoder
#import "ZXDataMatrixBitMatrixParser.h"
#import "ZXDataMatrixDataBlock.h"
#import "ZXDataMatrixDecodedBitStreamParser.h"
#import "ZXDataMatrixDecoder.h"
#import "ZXDataMatrixVersion.h"

// ZXingObjC/datamatrix/detector
#import "ZXDataMatrixDetector.h"

// ZXingObjC/datamatrix/encoder
#import "ZXASCIIEncoder.h"
#import "ZXBase256Encoder.h"
#import "ZXC40Encoder.h"
#import "ZXDataMatrixEncoder.h"
#import "ZXDataMatrixErrorCorrection.h"
#import "ZXDataMatrixSymbolInfo144.h"
#import "ZXDefaultPlacement.h"
#import "ZXEdifactEncoder.h"
#import "ZXEncoderContext.h"
#import "ZXHighLevelEncoder.h"
#import "ZXSymbolInfo.h"
#import "ZXSymbolShapeHint.h"
#import "ZXTextEncoder.h"
#import "ZXX12Encoder.h"

// ZXingObjC/datamatrix
#import "ZXDataMatrixReader.h"
#import "ZXDataMatrixWriter.h"

// ZXingObjC/maxicode/decoder
#import "ZXMaxiCodeBitMatrixParser.h"
#import "ZXMaxiCodeDecodedBitStreamParser.h"
#import "ZXMaxiCodeDecoder.h"

// ZXingObjC/maxicode
#import "ZXMaxiCodeReader.h"

// ZXingObjC/multi/qrcode/detector
#import "ZXMultiDetector.h"
#import "ZXMultiFinderPatternFinder.h"

// ZXingObjC/multi/qrcode
#import "ZXQRCodeMultiReader.h"

// ZXingObjC/multi
#import "ZXByQuadrantReader.h"
#import "ZXGenericMultipleBarcodeReader.h"
#import "ZXMultipleBarcodeReader.h"

// ZXingObjC/oned/rss/expanded/decoders
#import "ZXAbstractExpandedDecoder.h"
#import "ZXAI013103decoder.h"
#import "ZXAI01320xDecoder.h"
#import "ZXAI01392xDecoder.h"
#import "ZXAI01393xDecoder.h"
#import "ZXAI013x0x1xDecoder.h"
#import "ZXAI013x0xDecoder.h"
#import "ZXAI01AndOtherAIs.h"
#import "ZXAI01decoder.h"
#import "ZXAI01weightDecoder.h"
#import "ZXAnyAIDecoder.h"
#import "ZXBlockParsedResult.h"
#import "ZXCurrentParsingState.h"
#import "ZXDecodedChar.h"
#import "ZXDecodedInformation.h"
#import "ZXDecodedNumeric.h"
#import "ZXDecodedObject.h"
#import "ZXFieldParser.h"
#import "ZXGeneralAppIdDecoder.h"

// ZXingObjC/oned/rss/expanded
#import "ZXBitArrayBuilder.h"
#import "ZXExpandedPair.h"
#import "ZXExpandedRow.h"
#import "ZXRSSExpandedReader.h"

// ZXingObjC/oned/rss
#import "ZXAbstractRSSReader.h"
#import "ZXDataCharacter.h"
#import "ZXPair.h"
#import "ZXRSS14Reader.h"
#import "ZXRSSFinderPattern.h"
#import "ZXRSSUtils.h"

// ZXingObjC/oned
#import "ZXCodaBarReader.h"
#import "ZXCodaBarWriter.h"
#import "ZXCode128Reader.h"
#import "ZXCode128Writer.h"
#import "ZXCode39Reader.h"
#import "ZXCode39Writer.h"
#import "ZXCode93Reader.h"
#import "ZXEAN13Reader.h"
#import "ZXEAN13Writer.h"
#import "ZXEAN8Reader.h"
#import "ZXEAN8Writer.h"
#import "ZXEANManufacturerOrgSupport.h"
#import "ZXITFReader.h"
#import "ZXITFWriter.h"
#import "ZXMultiFormatOneDReader.h"
#import "ZXMultiFormatUPCEANReader.h"
#import "ZXOneDimensionalCodeWriter.h"
#import "ZXOneDReader.h"
#import "ZXUPCAReader.h"
#import "ZXUPCAWriter.h"
#import "ZXUPCEANExtension2Support.h"
#import "ZXUPCEANExtension5Support.h"
#import "ZXUPCEANExtensionSupport.h"
#import "ZXUPCEANReader.h"
#import "ZXUPCEANWriter.h"
#import "ZXUPCEReader.h"

// ZXingObjC/pdf417/decoder/ec
#import "ZXModulusGF.h"
#import "ZXModulusPoly.h"
#import "ZXPDF417ECErrorCorrection.h"

// ZXingObjC/pdf417/decoder
#import "ZXPDF417BarcodeMetadata.h"
#import "ZXPDF417BarcodeValue.h"
#import "ZXPDF417BoundingBox.h"
#import "ZXPDF417Codeword.h"
#import "ZXPDF417CodewordDecoder.h"
#import "ZXPDF417DecodedBitStreamParser.h"
#import "ZXPDF417DetectionResult.h"
#import "ZXPDF417DetectionResultColumn.h"
#import "ZXPDF417DetectionResultRowIndicatorColumn.h"
#import "ZXPDF417ScanningDecoder.h"

// ZXingObjC/pdf417/detector
#import "ZXPDF417Detector.h"
#import "ZXPDF417DetectorResult.h"

// ZXingObjC/pdf417/encoder
#import "ZXBarcodeMatrix.h"
#import "ZXBarcodeRow.h"
#import "ZXCompaction.h"
#import "ZXDimensions.h"
#import "ZXPDF417.h"
#import "ZXPDF417ErrorCorrection.h"
#import "ZXPDF417HighLevelEncoder.h"
#import "ZXPDF417Writer.h"

// ZXingObjC/pdf417
#import "ZXPDF417Common.h"
#import "ZXPDF417Reader.h"
#import "ZXPDF417ResultMetadata.h"
#import "ZXPDF417Writer.h"

// ZXingObjC/qrcode/decoder
#import "ZXDataMask.h"
#import "ZXErrorCorrectionLevel.h"
#import "ZXFormatInformation.h"
#import "ZXMode.h"
#import "ZXQRCodeBitMatrixParser.h"
#import "ZXQRCodeDataBlock.h"
#import "ZXQRCodeDecodedBitStreamParser.h"
#import "ZXQRCodeDecoder.h"
#import "ZXQRCodeVersion.h"

// ZXingObjC/qrcode/detector
#import "ZXAlignmentPattern.h"
#import "ZXAlignmentPatternFinder.h"
#import "ZXFinderPatternFinder.h"
#import "ZXFinderPatternInfo.h"
#import "ZXQRCodeDetector.h"
#import "ZXQRCodeFinderPattern.h"

// ZXingObjC/qrcode/encoder
#import "ZXBlockPair.h"
#import "ZXByteMatrix.h"
#import "ZXEncoder.h"
#import "ZXMaskUtil.h"
#import "ZXMatrixUtil.h"
#import "ZXQRCode.h"

// ZXingObjC/qrcode
#import "ZXQRCodeReader.h"
#import "ZXQRCodeWriter.h"

// ZXingObjC
#import "ZXBarcodeFormat.h"
#import "ZXBinarizer.h"
#import "ZXBinaryBitmap.h"
#import "ZXDecodeHints.h"
#import "ZXDimension.h"
#import "ZXEncodeHints.h"
#import "ZXErrors.h"
#import "ZXInvertedLuminanceSource.h"
#import "ZXLuminanceSource.h"
#import "ZXMultiFormatReader.h"
#import "ZXMultiFormatWriter.h"
#import "ZXPlanarYUVLuminanceSource.h"
#import "ZXReader.h"
#import "ZXResult.h"
#import "ZXResultMetadataType.h"
#import "ZXResultPoint.h"
#import "ZXResultPointCallback.h"
#import "ZXRGBLuminanceSource.h"
#import "ZXWriter.h"
