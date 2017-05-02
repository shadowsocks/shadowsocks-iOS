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

#import "ZXBitMatrix.h"
#import "ZXErrorCorrectionLevel.h"
#import "ZXFormatInformation.h"
#import "ZXQRCodeVersion.h"

@implementation ZXQRCodeECBlocks

- (id)initWithEcCodewordsPerBlock:(int)ecCodewordsPerBlock ecBlocks:(ZXQRCodeECB *)ecBlocks {
  if (self = [super init]) {
    _ecCodewordsPerBlock = ecCodewordsPerBlock;
    _ecBlocks = @[ecBlocks];
  }

  return self;
}

- (id)initWithEcCodewordsPerBlock:(int)ecCodewordsPerBlock ecBlocks1:(ZXQRCodeECB *)ecBlocks1 ecBlocks2:(ZXQRCodeECB *)ecBlocks2 {
  if (self = [super init]) {
    _ecCodewordsPerBlock = ecCodewordsPerBlock;
    _ecBlocks = @[ecBlocks1, ecBlocks2];
  }

  return self;
}

+ (ZXQRCodeECBlocks *)ecBlocksWithEcCodewordsPerBlock:(int)ecCodewordsPerBlock ecBlocks:(ZXQRCodeECB *)ecBlocks {
  return [[ZXQRCodeECBlocks alloc] initWithEcCodewordsPerBlock:ecCodewordsPerBlock ecBlocks:ecBlocks];
}

+ (ZXQRCodeECBlocks *)ecBlocksWithEcCodewordsPerBlock:(int)ecCodewordsPerBlock ecBlocks1:(ZXQRCodeECB *)ecBlocks1 ecBlocks2:(ZXQRCodeECB *)ecBlocks2 {
  return [[ZXQRCodeECBlocks alloc] initWithEcCodewordsPerBlock:ecCodewordsPerBlock ecBlocks1:ecBlocks1 ecBlocks2:ecBlocks2];
}

- (int)numBlocks {
  int total = 0;

  for (ZXQRCodeECB *ecb in self.ecBlocks) {
    total += [ecb count];
  }

  return total;
}

- (int)totalECCodewords {
  return self.ecCodewordsPerBlock * [self numBlocks];
}

@end

@implementation ZXQRCodeECB

- (id)initWithCount:(int)count dataCodewords:(int)dataCodewords {
  if (self = [super init]) {
    _count = count;
    _dataCodewords = dataCodewords;
  }

  return self;
}

+ (ZXQRCodeECB *)ecbWithCount:(int)count dataCodewords:(int)dataCodewords {
  return [[ZXQRCodeECB alloc] initWithCount:count dataCodewords:dataCodewords];
}

@end


/**
 * See ISO 18004:2006 Annex D.
 * Element i represents the raw version bits that specify version i + 7
 */

int const VERSION_DECODE_INFO_LEN = 34;
int const VERSION_DECODE_INFO[VERSION_DECODE_INFO_LEN] = {
  0x07C94, 0x085BC, 0x09A99, 0x0A4D3, 0x0BBF6,
  0x0C762, 0x0D847, 0x0E60D, 0x0F928, 0x10B78,
  0x1145D, 0x12A17, 0x13532, 0x149A6, 0x15683,
  0x168C9, 0x177EC, 0x18EC4, 0x191E1, 0x1AFAB,
  0x1B08E, 0x1CC1A, 0x1D33F, 0x1ED75, 0x1F250,
  0x209D5, 0x216F0, 0x228BA, 0x2379F, 0x24B0B,
  0x2542E, 0x26A64, 0x27541, 0x28C69
};

static NSArray *VERSIONS = nil;

@implementation ZXQRCodeVersion

- (id)initWithVersionNumber:(int)versionNumber alignmentPatternCenters:(NSArray *)alignmentPatternCenters ecBlocks1:(ZXQRCodeECBlocks *)ecBlocks1 ecBlocks2:(ZXQRCodeECBlocks *)ecBlocks2 ecBlocks3:(ZXQRCodeECBlocks *)ecBlocks3 ecBlocks4:(ZXQRCodeECBlocks *)ecBlocks4 {
  if (self = [super init]) {
    _versionNumber = versionNumber;
    _alignmentPatternCenters = alignmentPatternCenters;
    _ecBlocks = @[ecBlocks1, ecBlocks2, ecBlocks3, ecBlocks4];
    int total = 0;
    int ecCodewords = ecBlocks1.ecCodewordsPerBlock;

    for (ZXQRCodeECB *ecBlock in ecBlocks1.ecBlocks) {
      total += ecBlock.count * (ecBlock.dataCodewords + ecCodewords);
    }

    _totalCodewords = total;
  }

  return self;
}

+ (ZXQRCodeVersion *)ZXQRCodeVersionWithVersionNumber:(int)aVersionNumber alignmentPatternCenters:(NSArray *)anAlignmentPatternCenters ecBlocks1:(ZXQRCodeECBlocks *)ecBlocks1 ecBlocks2:(ZXQRCodeECBlocks *)ecBlocks2 ecBlocks3:(ZXQRCodeECBlocks *)ecBlocks3 ecBlocks4:(ZXQRCodeECBlocks *)ecBlocks4 {
  return [[ZXQRCodeVersion alloc] initWithVersionNumber:aVersionNumber alignmentPatternCenters:anAlignmentPatternCenters ecBlocks1:ecBlocks1 ecBlocks2:ecBlocks2 ecBlocks3:ecBlocks3 ecBlocks4:ecBlocks4];
}

- (int)dimensionForVersion {
  return 17 + 4 * self.versionNumber;
}

- (ZXQRCodeECBlocks *)ecBlocksForLevel:(ZXErrorCorrectionLevel *)ecLevel {
  return self.ecBlocks[[ecLevel ordinal]];
}

/**
 * Deduces version information purely from QR Code dimensions.
 */
+ (ZXQRCodeVersion *)provisionalVersionForDimension:(int)dimension {
  if (dimension % 4 != 1) {
    return nil;
  }

  return [self versionForNumber:(dimension - 17) >> 2];
}

+ (ZXQRCodeVersion *)versionForNumber:(int)versionNumber {
  if (versionNumber < 1 || versionNumber > 40) {
    return nil;
  }
  return VERSIONS[versionNumber - 1];
}

+ (ZXQRCodeVersion *)decodeVersionInformation:(int)versionBits {
  int bestDifference = INT_MAX;
  int bestVersion = 0;

  for (int i = 0; i < VERSION_DECODE_INFO_LEN; i++) {
    int targetVersion = VERSION_DECODE_INFO[i];
    if (targetVersion == versionBits) {
      return [self versionForNumber:i + 7];
    }
    int bitsDifference = [ZXFormatInformation numBitsDiffering:versionBits b:targetVersion];
    if (bitsDifference < bestDifference) {
      bestVersion = i + 7;
      bestDifference = bitsDifference;
    }
  }

  if (bestDifference <= 3) {
    return [self versionForNumber:bestVersion];
  }
  return nil;
}

/**
 * See ISO 18004:2006 Annex E
 */
- (ZXBitMatrix *)buildFunctionPattern {
  int dimension = [self dimensionForVersion];
  ZXBitMatrix *bitMatrix = [[ZXBitMatrix alloc] initWithDimension:dimension];
  [bitMatrix setRegionAtLeft:0 top:0 width:9 height:9];
  [bitMatrix setRegionAtLeft:dimension - 8 top:0 width:8 height:9];
  [bitMatrix setRegionAtLeft:0 top:dimension - 8 width:9 height:8];
  int max = (int)self.alignmentPatternCenters.count;

  for (int x = 0; x < max; x++) {
    int i = [(self.alignmentPatternCenters)[x] intValue] - 2;

    for (int y = 0; y < max; y++) {
      if ((x == 0 && (y == 0 || y == max - 1)) || (x == max - 1 && y == 0)) {
        continue;
      }
      [bitMatrix setRegionAtLeft:[(self.alignmentPatternCenters)[y] intValue] - 2 top:i width:5 height:5];
    }
  }

  [bitMatrix setRegionAtLeft:6 top:9 width:1 height:dimension - 17];
  [bitMatrix setRegionAtLeft:9 top:6 width:dimension - 17 height:1];
  if (self.versionNumber > 6) {
    [bitMatrix setRegionAtLeft:dimension - 11 top:0 width:3 height:6];
    [bitMatrix setRegionAtLeft:0 top:dimension - 11 width:6 height:3];
  }
  return bitMatrix;
}

- (NSString *)description {
  return [@(self.versionNumber) stringValue];
}

/**
 * See ISO 18004:2006 6.5.1 Table 9
 */
+ (void)initialize {
  VERSIONS = @[[ZXQRCodeVersion ZXQRCodeVersionWithVersionNumber:1
                                     alignmentPatternCenters:@[]
                                                   ecBlocks1:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:7 ecBlocks:[ZXQRCodeECB ecbWithCount:1 dataCodewords:19]]
                                                   ecBlocks2:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:10 ecBlocks:[ZXQRCodeECB ecbWithCount:1 dataCodewords:16]]
                                                   ecBlocks3:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:13 ecBlocks:[ZXQRCodeECB ecbWithCount:1 dataCodewords:13]]
                                                   ecBlocks4:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:17 ecBlocks:[ZXQRCodeECB ecbWithCount:1 dataCodewords:9]]],

           [ZXQRCodeVersion ZXQRCodeVersionWithVersionNumber:2
                                     alignmentPatternCenters:@[@6, @18]
                                                   ecBlocks1:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:10 ecBlocks:[ZXQRCodeECB ecbWithCount:1 dataCodewords:34]]
                                                   ecBlocks2:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:16 ecBlocks:[ZXQRCodeECB ecbWithCount:1 dataCodewords:28]]
                                                   ecBlocks3:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:22 ecBlocks:[ZXQRCodeECB ecbWithCount:1 dataCodewords:22]]
                                                   ecBlocks4:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:28 ecBlocks:[ZXQRCodeECB ecbWithCount:1 dataCodewords:16]]],

           [ZXQRCodeVersion ZXQRCodeVersionWithVersionNumber:3
                                     alignmentPatternCenters:@[@6, @22]
                                                   ecBlocks1:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:15 ecBlocks:[ZXQRCodeECB ecbWithCount:1 dataCodewords:55]]
                                                   ecBlocks2:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:26 ecBlocks:[ZXQRCodeECB ecbWithCount:1 dataCodewords:44]]
                                                   ecBlocks3:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:18 ecBlocks:[ZXQRCodeECB ecbWithCount:2 dataCodewords:17]]
                                                   ecBlocks4:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:22 ecBlocks:[ZXQRCodeECB ecbWithCount:2 dataCodewords:13]]],

           [ZXQRCodeVersion ZXQRCodeVersionWithVersionNumber:4
                                     alignmentPatternCenters:@[@6, @26]
                                                   ecBlocks1:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:20 ecBlocks:[ZXQRCodeECB ecbWithCount:1 dataCodewords:80]]
                                                   ecBlocks2:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:18 ecBlocks:[ZXQRCodeECB ecbWithCount:2 dataCodewords:32]]
                                                   ecBlocks3:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:26 ecBlocks:[ZXQRCodeECB ecbWithCount:2 dataCodewords:24]]
                                                   ecBlocks4:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:16 ecBlocks:[ZXQRCodeECB ecbWithCount:4 dataCodewords:9]]],

           [ZXQRCodeVersion ZXQRCodeVersionWithVersionNumber:5
                                     alignmentPatternCenters:@[@6, @30]
                                                   ecBlocks1:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:26 ecBlocks:[ZXQRCodeECB ecbWithCount:1 dataCodewords:108]]
                                                   ecBlocks2:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:24 ecBlocks:[ZXQRCodeECB ecbWithCount:2 dataCodewords:43]]
                                                   ecBlocks3:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:18 ecBlocks1:[ZXQRCodeECB ecbWithCount:2 dataCodewords:15] ecBlocks2:[ZXQRCodeECB ecbWithCount:2 dataCodewords:16]]
                                                   ecBlocks4:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:22 ecBlocks1:[ZXQRCodeECB ecbWithCount:2 dataCodewords:11] ecBlocks2:[ZXQRCodeECB ecbWithCount:2 dataCodewords:12]]],

           [ZXQRCodeVersion ZXQRCodeVersionWithVersionNumber:6
                                     alignmentPatternCenters:@[@6, @34]
                                                   ecBlocks1:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:18 ecBlocks:[ZXQRCodeECB ecbWithCount:2 dataCodewords:68]]
                                                   ecBlocks2:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:16 ecBlocks:[ZXQRCodeECB ecbWithCount:4 dataCodewords:27]]
                                                   ecBlocks3:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:24 ecBlocks:[ZXQRCodeECB ecbWithCount:4 dataCodewords:19]]
                                                   ecBlocks4:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:28 ecBlocks:[ZXQRCodeECB ecbWithCount:4 dataCodewords:15]]],

           [ZXQRCodeVersion ZXQRCodeVersionWithVersionNumber:7
                                     alignmentPatternCenters:@[@6, @22, @38]
                                                   ecBlocks1:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:20 ecBlocks:[ZXQRCodeECB ecbWithCount:2 dataCodewords:78]]
                                                   ecBlocks2:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:18 ecBlocks:[ZXQRCodeECB ecbWithCount:4 dataCodewords:31]]
                                                   ecBlocks3:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:18 ecBlocks1:[ZXQRCodeECB ecbWithCount:2 dataCodewords:14] ecBlocks2:[ZXQRCodeECB ecbWithCount:4 dataCodewords:15]]
                                                   ecBlocks4:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:26 ecBlocks1:[ZXQRCodeECB ecbWithCount:4 dataCodewords:13] ecBlocks2:[ZXQRCodeECB ecbWithCount:1 dataCodewords:14]]],

           [ZXQRCodeVersion ZXQRCodeVersionWithVersionNumber:8
                                     alignmentPatternCenters:@[@6, @24, @42]
                                                   ecBlocks1:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:24 ecBlocks:[ZXQRCodeECB ecbWithCount:2 dataCodewords:97]]
                                                   ecBlocks2:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:22 ecBlocks1:[ZXQRCodeECB ecbWithCount:2 dataCodewords:38] ecBlocks2:[ZXQRCodeECB ecbWithCount:2 dataCodewords:39]]
                                                   ecBlocks3:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:22 ecBlocks1:[ZXQRCodeECB ecbWithCount:4 dataCodewords:18] ecBlocks2:[ZXQRCodeECB ecbWithCount:2 dataCodewords:19]]
                                                   ecBlocks4:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:26 ecBlocks1:[ZXQRCodeECB ecbWithCount:4 dataCodewords:14] ecBlocks2:[ZXQRCodeECB ecbWithCount:2 dataCodewords:15]]],

           [ZXQRCodeVersion ZXQRCodeVersionWithVersionNumber:9
                                     alignmentPatternCenters:@[@6, @26, @46]
                                                   ecBlocks1:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:30 ecBlocks:[ZXQRCodeECB ecbWithCount:2 dataCodewords:116]]
                                                   ecBlocks2:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:22 ecBlocks1:[ZXQRCodeECB ecbWithCount:3 dataCodewords:36] ecBlocks2:[ZXQRCodeECB ecbWithCount:2 dataCodewords:37]]
                                                   ecBlocks3:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:20 ecBlocks1:[ZXQRCodeECB ecbWithCount:4 dataCodewords:16] ecBlocks2:[ZXQRCodeECB ecbWithCount:4 dataCodewords:17]]
                                                   ecBlocks4:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:24 ecBlocks1:[ZXQRCodeECB ecbWithCount:4 dataCodewords:12] ecBlocks2:[ZXQRCodeECB ecbWithCount:4 dataCodewords:13]]],

           [ZXQRCodeVersion ZXQRCodeVersionWithVersionNumber:10
                                     alignmentPatternCenters:@[@6, @28, @50]
                                                   ecBlocks1:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:18 ecBlocks1:[ZXQRCodeECB ecbWithCount:2 dataCodewords:68] ecBlocks2:[ZXQRCodeECB ecbWithCount:2 dataCodewords:69]]
                                                   ecBlocks2:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:26 ecBlocks1:[ZXQRCodeECB ecbWithCount:4 dataCodewords:43] ecBlocks2:[ZXQRCodeECB ecbWithCount:1 dataCodewords:44]]
                                                   ecBlocks3:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:24 ecBlocks1:[ZXQRCodeECB ecbWithCount:6 dataCodewords:19] ecBlocks2:[ZXQRCodeECB ecbWithCount:2 dataCodewords:20]]
                                                   ecBlocks4:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:28 ecBlocks1:[ZXQRCodeECB ecbWithCount:6 dataCodewords:15] ecBlocks2:[ZXQRCodeECB ecbWithCount:2 dataCodewords:16]]],

           [ZXQRCodeVersion ZXQRCodeVersionWithVersionNumber:11
                                     alignmentPatternCenters:@[@6, @30, @54]
                                                   ecBlocks1:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:20 ecBlocks:[ZXQRCodeECB ecbWithCount:4 dataCodewords:81]]
                                                   ecBlocks2:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:30 ecBlocks1:[ZXQRCodeECB ecbWithCount:1 dataCodewords:50] ecBlocks2:[ZXQRCodeECB ecbWithCount:4 dataCodewords:51]]
                                                   ecBlocks3:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:28 ecBlocks1:[ZXQRCodeECB ecbWithCount:4 dataCodewords:22] ecBlocks2:[ZXQRCodeECB ecbWithCount:4 dataCodewords:23]]
                                                   ecBlocks4:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:24 ecBlocks1:[ZXQRCodeECB ecbWithCount:3 dataCodewords:12] ecBlocks2:[ZXQRCodeECB ecbWithCount:8 dataCodewords:13]]],

           [ZXQRCodeVersion ZXQRCodeVersionWithVersionNumber:12
                                     alignmentPatternCenters:@[@6, @32, @58]
                                                   ecBlocks1:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:24 ecBlocks1:[ZXQRCodeECB ecbWithCount:2 dataCodewords:92] ecBlocks2:[ZXQRCodeECB ecbWithCount:2 dataCodewords:93]]
                                                   ecBlocks2:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:22 ecBlocks1:[ZXQRCodeECB ecbWithCount:6 dataCodewords:36] ecBlocks2:[ZXQRCodeECB ecbWithCount:2 dataCodewords:37]]
                                                   ecBlocks3:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:26 ecBlocks1:[ZXQRCodeECB ecbWithCount:4 dataCodewords:20] ecBlocks2:[ZXQRCodeECB ecbWithCount:6 dataCodewords:21]]
                                                   ecBlocks4:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:28 ecBlocks1:[ZXQRCodeECB ecbWithCount:7 dataCodewords:14] ecBlocks2:[ZXQRCodeECB ecbWithCount:4 dataCodewords:15]]],

           [ZXQRCodeVersion ZXQRCodeVersionWithVersionNumber:13
                                     alignmentPatternCenters:@[@6, @34, @62]
                                                   ecBlocks1:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:26 ecBlocks:[ZXQRCodeECB ecbWithCount:4 dataCodewords:107]]
                                                   ecBlocks2:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:22 ecBlocks1:[ZXQRCodeECB ecbWithCount:8 dataCodewords:37] ecBlocks2:[ZXQRCodeECB ecbWithCount:1 dataCodewords:38]]
                                                   ecBlocks3:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:24 ecBlocks1:[ZXQRCodeECB ecbWithCount:8 dataCodewords:20] ecBlocks2:[ZXQRCodeECB ecbWithCount:4 dataCodewords:21]]
                                                   ecBlocks4:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:22 ecBlocks1:[ZXQRCodeECB ecbWithCount:12 dataCodewords:11] ecBlocks2:[ZXQRCodeECB ecbWithCount:4 dataCodewords:12]]],

           [ZXQRCodeVersion ZXQRCodeVersionWithVersionNumber:14
                                     alignmentPatternCenters:@[@6, @26, @46, @66]
                                                   ecBlocks1:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:30 ecBlocks1:[ZXQRCodeECB ecbWithCount:3 dataCodewords:115] ecBlocks2:[ZXQRCodeECB ecbWithCount:1 dataCodewords:116]]
                                                   ecBlocks2:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:24 ecBlocks1:[ZXQRCodeECB ecbWithCount:4 dataCodewords:40] ecBlocks2:[ZXQRCodeECB ecbWithCount:5 dataCodewords:41]]
                                                   ecBlocks3:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:20 ecBlocks1:[ZXQRCodeECB ecbWithCount:11 dataCodewords:16] ecBlocks2:[ZXQRCodeECB ecbWithCount:5 dataCodewords:17]]
                                                   ecBlocks4:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:24 ecBlocks1:[ZXQRCodeECB ecbWithCount:11 dataCodewords:12] ecBlocks2:[ZXQRCodeECB ecbWithCount:5 dataCodewords:13]]],

           [ZXQRCodeVersion ZXQRCodeVersionWithVersionNumber:15
                                     alignmentPatternCenters:@[@6, @26, @48, @70]
                                                   ecBlocks1:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:22 ecBlocks1:[ZXQRCodeECB ecbWithCount:5 dataCodewords:87] ecBlocks2:[ZXQRCodeECB ecbWithCount:1 dataCodewords:88]]
                                                   ecBlocks2:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:24 ecBlocks1:[ZXQRCodeECB ecbWithCount:5 dataCodewords:41] ecBlocks2:[ZXQRCodeECB ecbWithCount:5 dataCodewords:42]]
                                                   ecBlocks3:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:30 ecBlocks1:[ZXQRCodeECB ecbWithCount:5 dataCodewords:24] ecBlocks2:[ZXQRCodeECB ecbWithCount:7 dataCodewords:25]]
                                                   ecBlocks4:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:24 ecBlocks1:[ZXQRCodeECB ecbWithCount:11 dataCodewords:12] ecBlocks2:[ZXQRCodeECB ecbWithCount:7 dataCodewords:13]]],

           [ZXQRCodeVersion ZXQRCodeVersionWithVersionNumber:16
                                     alignmentPatternCenters:@[@6, @26, @50, @74]
                                                   ecBlocks1:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:24 ecBlocks1:[ZXQRCodeECB ecbWithCount:5 dataCodewords:98] ecBlocks2:[ZXQRCodeECB ecbWithCount:1 dataCodewords:99]]
                                                   ecBlocks2:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:28 ecBlocks1:[ZXQRCodeECB ecbWithCount:7 dataCodewords:45] ecBlocks2:[ZXQRCodeECB ecbWithCount:3 dataCodewords:46]]
                                                   ecBlocks3:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:24 ecBlocks1:[ZXQRCodeECB ecbWithCount:15 dataCodewords:19] ecBlocks2:[ZXQRCodeECB ecbWithCount:2 dataCodewords:20]]
                                                   ecBlocks4:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:30 ecBlocks1:[ZXQRCodeECB ecbWithCount:3 dataCodewords:15] ecBlocks2:[ZXQRCodeECB ecbWithCount:13 dataCodewords:16]]],

           [ZXQRCodeVersion ZXQRCodeVersionWithVersionNumber:17
                                     alignmentPatternCenters:@[@6, @30, @54, @78]
                                                   ecBlocks1:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:28 ecBlocks1:[ZXQRCodeECB ecbWithCount:1 dataCodewords:107] ecBlocks2:[ZXQRCodeECB ecbWithCount:5 dataCodewords:108]]
                                                   ecBlocks2:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:28 ecBlocks1:[ZXQRCodeECB ecbWithCount:10 dataCodewords:46] ecBlocks2:[ZXQRCodeECB ecbWithCount:1 dataCodewords:47]]
                                                   ecBlocks3:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:28 ecBlocks1:[ZXQRCodeECB ecbWithCount:1 dataCodewords:22] ecBlocks2:[ZXQRCodeECB ecbWithCount:15 dataCodewords:23]]
                                                   ecBlocks4:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:28 ecBlocks1:[ZXQRCodeECB ecbWithCount:2 dataCodewords:14] ecBlocks2:[ZXQRCodeECB ecbWithCount:17 dataCodewords:15]]],

           [ZXQRCodeVersion ZXQRCodeVersionWithVersionNumber:18
                                     alignmentPatternCenters:@[@6, @30, @56, @82]
                                                   ecBlocks1:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:30 ecBlocks1:[ZXQRCodeECB ecbWithCount:5 dataCodewords:120] ecBlocks2:[ZXQRCodeECB ecbWithCount:1 dataCodewords:121]]
                                                   ecBlocks2:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:26 ecBlocks1:[ZXQRCodeECB ecbWithCount:9 dataCodewords:43] ecBlocks2:[ZXQRCodeECB ecbWithCount:4 dataCodewords:44]]
                                                   ecBlocks3:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:28 ecBlocks1:[ZXQRCodeECB ecbWithCount:17 dataCodewords:22] ecBlocks2:[ZXQRCodeECB ecbWithCount:1 dataCodewords:23]]
                                                   ecBlocks4:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:28 ecBlocks1:[ZXQRCodeECB ecbWithCount:2 dataCodewords:14] ecBlocks2:[ZXQRCodeECB ecbWithCount:19 dataCodewords:15]]],

           [ZXQRCodeVersion ZXQRCodeVersionWithVersionNumber:19
                                     alignmentPatternCenters:@[@6, @30, @58, @86]
                                                   ecBlocks1:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:28 ecBlocks1:[ZXQRCodeECB ecbWithCount:3 dataCodewords:113] ecBlocks2:[ZXQRCodeECB ecbWithCount:4 dataCodewords:114]]
                                                   ecBlocks2:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:26 ecBlocks1:[ZXQRCodeECB ecbWithCount:3 dataCodewords:44] ecBlocks2:[ZXQRCodeECB ecbWithCount:11 dataCodewords:45]]
                                                   ecBlocks3:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:26 ecBlocks1:[ZXQRCodeECB ecbWithCount:17 dataCodewords:21] ecBlocks2:[ZXQRCodeECB ecbWithCount:4 dataCodewords:22]]
                                                   ecBlocks4:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:26 ecBlocks1:[ZXQRCodeECB ecbWithCount:9 dataCodewords:13] ecBlocks2:[ZXQRCodeECB ecbWithCount:16 dataCodewords:14]]],

           [ZXQRCodeVersion ZXQRCodeVersionWithVersionNumber:20
                                     alignmentPatternCenters:@[@6, @34, @62, @90]
                                                   ecBlocks1:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:28 ecBlocks1:[ZXQRCodeECB ecbWithCount:3 dataCodewords:107] ecBlocks2:[ZXQRCodeECB ecbWithCount:5 dataCodewords:108]]
                                                   ecBlocks2:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:26 ecBlocks1:[ZXQRCodeECB ecbWithCount:3 dataCodewords:41] ecBlocks2:[ZXQRCodeECB ecbWithCount:13 dataCodewords:42]]
                                                   ecBlocks3:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:30 ecBlocks1:[ZXQRCodeECB ecbWithCount:15 dataCodewords:24] ecBlocks2:[ZXQRCodeECB ecbWithCount:5 dataCodewords:25]]
                                                   ecBlocks4:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:28 ecBlocks1:[ZXQRCodeECB ecbWithCount:15 dataCodewords:15] ecBlocks2:[ZXQRCodeECB ecbWithCount:10 dataCodewords:16]]],

           [ZXQRCodeVersion ZXQRCodeVersionWithVersionNumber:21
                                     alignmentPatternCenters:@[@6, @28, @50, @72, @94]
                                                   ecBlocks1:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:28 ecBlocks1:[ZXQRCodeECB ecbWithCount:4 dataCodewords:116] ecBlocks2:[ZXQRCodeECB ecbWithCount:4 dataCodewords:117]]
                                                   ecBlocks2:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:26 ecBlocks:[ZXQRCodeECB ecbWithCount:17 dataCodewords:42]]
                                                   ecBlocks3:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:28 ecBlocks1:[ZXQRCodeECB ecbWithCount:17 dataCodewords:22] ecBlocks2:[ZXQRCodeECB ecbWithCount:6 dataCodewords:23]]
                                                   ecBlocks4:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:30 ecBlocks1:[ZXQRCodeECB ecbWithCount:19 dataCodewords:16] ecBlocks2:[ZXQRCodeECB ecbWithCount:6 dataCodewords:17]]],

           [ZXQRCodeVersion ZXQRCodeVersionWithVersionNumber:22
                                     alignmentPatternCenters:@[@6, @26, @50, @74, @98]
                                                   ecBlocks1:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:28 ecBlocks1:[ZXQRCodeECB ecbWithCount:2 dataCodewords:111] ecBlocks2:[ZXQRCodeECB ecbWithCount:7 dataCodewords:112]]
                                                   ecBlocks2:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:28 ecBlocks:[ZXQRCodeECB ecbWithCount:17 dataCodewords:46]]
                                                   ecBlocks3:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:30 ecBlocks1:[ZXQRCodeECB ecbWithCount:7 dataCodewords:24] ecBlocks2:[ZXQRCodeECB ecbWithCount:16 dataCodewords:25]]
                                                   ecBlocks4:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:24 ecBlocks:[ZXQRCodeECB ecbWithCount:34 dataCodewords:13]]],

           [ZXQRCodeVersion ZXQRCodeVersionWithVersionNumber:23
                                     alignmentPatternCenters:@[@6, @30, @54, @78, @102]
                                                   ecBlocks1:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:30 ecBlocks1:[ZXQRCodeECB ecbWithCount:4 dataCodewords:121] ecBlocks2:[ZXQRCodeECB ecbWithCount:5 dataCodewords:122]]
                                                   ecBlocks2:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:28 ecBlocks1:[ZXQRCodeECB ecbWithCount:4 dataCodewords:47] ecBlocks2:[ZXQRCodeECB ecbWithCount:14 dataCodewords:48]]
                                                   ecBlocks3:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:30 ecBlocks1:[ZXQRCodeECB ecbWithCount:11 dataCodewords:24] ecBlocks2:[ZXQRCodeECB ecbWithCount:14 dataCodewords:25]]
                                                   ecBlocks4:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:30 ecBlocks1:[ZXQRCodeECB ecbWithCount:16 dataCodewords:15] ecBlocks2:[ZXQRCodeECB ecbWithCount:14 dataCodewords:16]]],

           [ZXQRCodeVersion ZXQRCodeVersionWithVersionNumber:24
                                     alignmentPatternCenters:@[@6, @28, @54, @80, @106]
                                                   ecBlocks1:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:30 ecBlocks1:[ZXQRCodeECB ecbWithCount:6 dataCodewords:117] ecBlocks2:[ZXQRCodeECB ecbWithCount:4 dataCodewords:118]]
                                                   ecBlocks2:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:28 ecBlocks1:[ZXQRCodeECB ecbWithCount:6 dataCodewords:45] ecBlocks2:[ZXQRCodeECB ecbWithCount:14 dataCodewords:46]]
                                                   ecBlocks3:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:30 ecBlocks1:[ZXQRCodeECB ecbWithCount:11 dataCodewords:24] ecBlocks2:[ZXQRCodeECB ecbWithCount:16 dataCodewords:25]]
                                                   ecBlocks4:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:30 ecBlocks1:[ZXQRCodeECB ecbWithCount:30 dataCodewords:16] ecBlocks2:[ZXQRCodeECB ecbWithCount:2 dataCodewords:17]]],

           [ZXQRCodeVersion ZXQRCodeVersionWithVersionNumber:25
                                     alignmentPatternCenters:@[@6, @32, @58, @84, @110]
                                                   ecBlocks1:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:26 ecBlocks1:[ZXQRCodeECB ecbWithCount:8 dataCodewords:106] ecBlocks2:[ZXQRCodeECB ecbWithCount:4 dataCodewords:107]]
                                                   ecBlocks2:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:28 ecBlocks1:[ZXQRCodeECB ecbWithCount:8 dataCodewords:47] ecBlocks2:[ZXQRCodeECB ecbWithCount:13 dataCodewords:48]]
                                                   ecBlocks3:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:30 ecBlocks1:[ZXQRCodeECB ecbWithCount:7 dataCodewords:24] ecBlocks2:[ZXQRCodeECB ecbWithCount:22 dataCodewords:25]]
                                                   ecBlocks4:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:30 ecBlocks1:[ZXQRCodeECB ecbWithCount:22 dataCodewords:15] ecBlocks2:[ZXQRCodeECB ecbWithCount:13 dataCodewords:16]]],

           [ZXQRCodeVersion ZXQRCodeVersionWithVersionNumber:26
                                     alignmentPatternCenters:@[@6, @30, @58, @86, @114]
                                                   ecBlocks1:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:28 ecBlocks1:[ZXQRCodeECB ecbWithCount:10 dataCodewords:114] ecBlocks2:[ZXQRCodeECB ecbWithCount:2 dataCodewords:115]]
                                                   ecBlocks2:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:28 ecBlocks1:[ZXQRCodeECB ecbWithCount:19 dataCodewords:46] ecBlocks2:[ZXQRCodeECB ecbWithCount:4 dataCodewords:47]]
                                                   ecBlocks3:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:28 ecBlocks1:[ZXQRCodeECB ecbWithCount:28 dataCodewords:22] ecBlocks2:[ZXQRCodeECB ecbWithCount:6 dataCodewords:23]]
                                                   ecBlocks4:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:30 ecBlocks1:[ZXQRCodeECB ecbWithCount:33 dataCodewords:16] ecBlocks2:[ZXQRCodeECB ecbWithCount:4 dataCodewords:17]]],

           [ZXQRCodeVersion ZXQRCodeVersionWithVersionNumber:27
                                     alignmentPatternCenters:@[@6, @34, @62, @90, @118]
                                                   ecBlocks1:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:30 ecBlocks1:[ZXQRCodeECB ecbWithCount:8 dataCodewords:122] ecBlocks2:[ZXQRCodeECB ecbWithCount:4 dataCodewords:123]]
                                                   ecBlocks2:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:28 ecBlocks1:[ZXQRCodeECB ecbWithCount:22 dataCodewords:45] ecBlocks2:[ZXQRCodeECB ecbWithCount:3 dataCodewords:46]]
                                                   ecBlocks3:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:30 ecBlocks1:[ZXQRCodeECB ecbWithCount:8 dataCodewords:23] ecBlocks2:[ZXQRCodeECB ecbWithCount:26 dataCodewords:24]]
                                                   ecBlocks4:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:30 ecBlocks1:[ZXQRCodeECB ecbWithCount:12 dataCodewords:15] ecBlocks2:[ZXQRCodeECB ecbWithCount:28 dataCodewords:16]]],

           [ZXQRCodeVersion ZXQRCodeVersionWithVersionNumber:28
                                     alignmentPatternCenters:@[@6, @26, @50, @74, @98, @122]
                                                   ecBlocks1:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:30 ecBlocks1:[ZXQRCodeECB ecbWithCount:3 dataCodewords:117] ecBlocks2:[ZXQRCodeECB ecbWithCount:10 dataCodewords:118]]
                                                   ecBlocks2:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:28 ecBlocks1:[ZXQRCodeECB ecbWithCount:3 dataCodewords:45] ecBlocks2:[ZXQRCodeECB ecbWithCount:23 dataCodewords:46]]
                                                   ecBlocks3:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:30 ecBlocks1:[ZXQRCodeECB ecbWithCount:4 dataCodewords:24] ecBlocks2:[ZXQRCodeECB ecbWithCount:31 dataCodewords:25]]
                                                   ecBlocks4:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:30 ecBlocks1:[ZXQRCodeECB ecbWithCount:11 dataCodewords:15] ecBlocks2:[ZXQRCodeECB ecbWithCount:31 dataCodewords:16]]],

           [ZXQRCodeVersion ZXQRCodeVersionWithVersionNumber:29
                                     alignmentPatternCenters:@[@6, @30, @54, @78, @102, @126]
                                                   ecBlocks1:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:30 ecBlocks1:[ZXQRCodeECB ecbWithCount:7 dataCodewords:116] ecBlocks2:[ZXQRCodeECB ecbWithCount:7 dataCodewords:117]]
                                                   ecBlocks2:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:28 ecBlocks1:[ZXQRCodeECB ecbWithCount:21 dataCodewords:45] ecBlocks2:[ZXQRCodeECB ecbWithCount:7 dataCodewords:46]]
                                                   ecBlocks3:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:30 ecBlocks1:[ZXQRCodeECB ecbWithCount:1 dataCodewords:23] ecBlocks2:[ZXQRCodeECB ecbWithCount:37 dataCodewords:24]]
                                                   ecBlocks4:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:30 ecBlocks1:[ZXQRCodeECB ecbWithCount:19 dataCodewords:15] ecBlocks2:[ZXQRCodeECB ecbWithCount:26 dataCodewords:16]]],

           [ZXQRCodeVersion ZXQRCodeVersionWithVersionNumber:30
                                     alignmentPatternCenters:@[@6, @26, @52, @78, @104, @130]
                                                   ecBlocks1:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:30 ecBlocks1:[ZXQRCodeECB ecbWithCount:5 dataCodewords:115] ecBlocks2:[ZXQRCodeECB ecbWithCount:10 dataCodewords:116]]
                                                   ecBlocks2:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:28 ecBlocks1:[ZXQRCodeECB ecbWithCount:19 dataCodewords:47] ecBlocks2:[ZXQRCodeECB ecbWithCount:10 dataCodewords:48]]
                                                   ecBlocks3:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:30 ecBlocks1:[ZXQRCodeECB ecbWithCount:15 dataCodewords:24] ecBlocks2:[ZXQRCodeECB ecbWithCount:25 dataCodewords:25]]
                                                   ecBlocks4:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:30 ecBlocks1:[ZXQRCodeECB ecbWithCount:23 dataCodewords:15] ecBlocks2:[ZXQRCodeECB ecbWithCount:25 dataCodewords:16]]],

           [ZXQRCodeVersion ZXQRCodeVersionWithVersionNumber:31
                                     alignmentPatternCenters:@[@6, @30, @56, @82, @108, @134]
                                                   ecBlocks1:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:30 ecBlocks1:[ZXQRCodeECB ecbWithCount:13 dataCodewords:115] ecBlocks2:[ZXQRCodeECB ecbWithCount:3 dataCodewords:116]]
                                                   ecBlocks2:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:28 ecBlocks1:[ZXQRCodeECB ecbWithCount:2 dataCodewords:46] ecBlocks2:[ZXQRCodeECB ecbWithCount:29 dataCodewords:47]]
                                                   ecBlocks3:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:30 ecBlocks1:[ZXQRCodeECB ecbWithCount:42 dataCodewords:24] ecBlocks2:[ZXQRCodeECB ecbWithCount:1 dataCodewords:25]]
                                                   ecBlocks4:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:30 ecBlocks1:[ZXQRCodeECB ecbWithCount:23 dataCodewords:15] ecBlocks2:[ZXQRCodeECB ecbWithCount:28 dataCodewords:16]]],

           [ZXQRCodeVersion ZXQRCodeVersionWithVersionNumber:32
                                     alignmentPatternCenters:@[@6, @34, @60, @86, @112, @138]
                                                   ecBlocks1:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:30 ecBlocks:[ZXQRCodeECB ecbWithCount:17 dataCodewords:115]]
                                                   ecBlocks2:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:28 ecBlocks1:[ZXQRCodeECB ecbWithCount:10 dataCodewords:46] ecBlocks2:[ZXQRCodeECB ecbWithCount:23 dataCodewords:47]]
                                                   ecBlocks3:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:30 ecBlocks1:[ZXQRCodeECB ecbWithCount:10 dataCodewords:24] ecBlocks2:[ZXQRCodeECB ecbWithCount:35 dataCodewords:25]]
                                                   ecBlocks4:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:30 ecBlocks1:[ZXQRCodeECB ecbWithCount:19 dataCodewords:15] ecBlocks2:[ZXQRCodeECB ecbWithCount:35 dataCodewords:16]]],

           [ZXQRCodeVersion ZXQRCodeVersionWithVersionNumber:33
                                     alignmentPatternCenters:@[@6, @30, @58, @86, @114, @142]
                                                   ecBlocks1:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:30 ecBlocks1:[ZXQRCodeECB ecbWithCount:17 dataCodewords:115] ecBlocks2:[ZXQRCodeECB ecbWithCount:1 dataCodewords:116]]
                                                   ecBlocks2:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:28 ecBlocks1:[ZXQRCodeECB ecbWithCount:14 dataCodewords:46] ecBlocks2:[ZXQRCodeECB ecbWithCount:21 dataCodewords:47]]
                                                   ecBlocks3:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:30 ecBlocks1:[ZXQRCodeECB ecbWithCount:29 dataCodewords:24] ecBlocks2:[ZXQRCodeECB ecbWithCount:19 dataCodewords:25]]
                                                   ecBlocks4:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:30 ecBlocks1:[ZXQRCodeECB ecbWithCount:11 dataCodewords:15] ecBlocks2:[ZXQRCodeECB ecbWithCount:46 dataCodewords:16]]],

           [ZXQRCodeVersion ZXQRCodeVersionWithVersionNumber:34
                                     alignmentPatternCenters:@[@6, @34, @62, @90, @118, @146]
                                                   ecBlocks1:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:30 ecBlocks1:[ZXQRCodeECB ecbWithCount:13 dataCodewords:115] ecBlocks2:[ZXQRCodeECB ecbWithCount:6 dataCodewords:116]]
                                                   ecBlocks2:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:28 ecBlocks1:[ZXQRCodeECB ecbWithCount:14 dataCodewords:46] ecBlocks2:[ZXQRCodeECB ecbWithCount:23 dataCodewords:47]]
                                                   ecBlocks3:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:30 ecBlocks1:[ZXQRCodeECB ecbWithCount:44 dataCodewords:24] ecBlocks2:[ZXQRCodeECB ecbWithCount:7 dataCodewords:25]]
                                                   ecBlocks4:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:30 ecBlocks1:[ZXQRCodeECB ecbWithCount:59 dataCodewords:16] ecBlocks2:[ZXQRCodeECB ecbWithCount:1 dataCodewords:17]]],

           [ZXQRCodeVersion ZXQRCodeVersionWithVersionNumber:35
                                     alignmentPatternCenters:@[@6, @30, @54, @78, @102, @126, @150]
                                                   ecBlocks1:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:30 ecBlocks1:[ZXQRCodeECB ecbWithCount:12 dataCodewords:121] ecBlocks2:[ZXQRCodeECB ecbWithCount:7 dataCodewords:122]]
                                                   ecBlocks2:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:28 ecBlocks1:[ZXQRCodeECB ecbWithCount:12 dataCodewords:47] ecBlocks2:[ZXQRCodeECB ecbWithCount:26 dataCodewords:48]]
                                                   ecBlocks3:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:30 ecBlocks1:[ZXQRCodeECB ecbWithCount:39 dataCodewords:24] ecBlocks2:[ZXQRCodeECB ecbWithCount:14 dataCodewords:25]]
                                                   ecBlocks4:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:30 ecBlocks1:[ZXQRCodeECB ecbWithCount:22 dataCodewords:15] ecBlocks2:[ZXQRCodeECB ecbWithCount:41 dataCodewords:16]]],

           [ZXQRCodeVersion ZXQRCodeVersionWithVersionNumber:36
                                     alignmentPatternCenters:@[@6, @24, @50, @76, @102, @128, @154]
                                                   ecBlocks1:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:30 ecBlocks1:[ZXQRCodeECB ecbWithCount:6 dataCodewords:121] ecBlocks2:[ZXQRCodeECB ecbWithCount:14 dataCodewords:122]]
                                                   ecBlocks2:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:28 ecBlocks1:[ZXQRCodeECB ecbWithCount:6 dataCodewords:47] ecBlocks2:[ZXQRCodeECB ecbWithCount:34 dataCodewords:48]]
                                                   ecBlocks3:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:30 ecBlocks1:[ZXQRCodeECB ecbWithCount:46 dataCodewords:24] ecBlocks2:[ZXQRCodeECB ecbWithCount:10 dataCodewords:25]]
                                                   ecBlocks4:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:30 ecBlocks1:[ZXQRCodeECB ecbWithCount:2 dataCodewords:15] ecBlocks2:[ZXQRCodeECB ecbWithCount:64 dataCodewords:16]]],

          [ZXQRCodeVersion ZXQRCodeVersionWithVersionNumber:37
                                alignmentPatternCenters:@[@6, @28, @54, @80, @106, @132, @158]
                                              ecBlocks1:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:30 ecBlocks1:[ZXQRCodeECB ecbWithCount:17 dataCodewords:122] ecBlocks2:[ZXQRCodeECB ecbWithCount:4 dataCodewords:123]]
                                              ecBlocks2:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:28 ecBlocks1:[ZXQRCodeECB ecbWithCount:29 dataCodewords:46] ecBlocks2:[ZXQRCodeECB ecbWithCount:14 dataCodewords:47]]
                                              ecBlocks3:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:30 ecBlocks1:[ZXQRCodeECB ecbWithCount:49 dataCodewords:24] ecBlocks2:[ZXQRCodeECB ecbWithCount:10 dataCodewords:25]]
                                              ecBlocks4:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:30 ecBlocks1:[ZXQRCodeECB ecbWithCount:24 dataCodewords:15] ecBlocks2:[ZXQRCodeECB ecbWithCount:46 dataCodewords:16]]],

           [ZXQRCodeVersion ZXQRCodeVersionWithVersionNumber:38
                                     alignmentPatternCenters:@[@6, @32, @58, @84, @110, @136, @162]
                                                   ecBlocks1:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:30 ecBlocks1:[ZXQRCodeECB ecbWithCount:4 dataCodewords:122] ecBlocks2:[ZXQRCodeECB ecbWithCount:18 dataCodewords:123]]
                                                   ecBlocks2:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:28 ecBlocks1:[ZXQRCodeECB ecbWithCount:13 dataCodewords:46] ecBlocks2:[ZXQRCodeECB ecbWithCount:32 dataCodewords:47]]
                                                   ecBlocks3:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:30 ecBlocks1:[ZXQRCodeECB ecbWithCount:48 dataCodewords:24] ecBlocks2:[ZXQRCodeECB ecbWithCount:14 dataCodewords:25]]
                                                   ecBlocks4:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:30 ecBlocks1:[ZXQRCodeECB ecbWithCount:42 dataCodewords:15] ecBlocks2:[ZXQRCodeECB ecbWithCount:32 dataCodewords:16]]],

           [ZXQRCodeVersion ZXQRCodeVersionWithVersionNumber:39
                                     alignmentPatternCenters:@[@6, @26, @54, @82, @110, @138, @166]
                                                   ecBlocks1:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:30 ecBlocks1:[ZXQRCodeECB ecbWithCount:20 dataCodewords:117] ecBlocks2:[ZXQRCodeECB ecbWithCount:4 dataCodewords:118]]
                                                   ecBlocks2:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:28 ecBlocks1:[ZXQRCodeECB ecbWithCount:40 dataCodewords:47] ecBlocks2:[ZXQRCodeECB ecbWithCount:7 dataCodewords:48]]
                                                   ecBlocks3:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:30 ecBlocks1:[ZXQRCodeECB ecbWithCount:43 dataCodewords:24] ecBlocks2:[ZXQRCodeECB ecbWithCount:22 dataCodewords:25]]
                                                   ecBlocks4:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:30 ecBlocks1:[ZXQRCodeECB ecbWithCount:10 dataCodewords:15] ecBlocks2:[ZXQRCodeECB ecbWithCount:67 dataCodewords:16]]],

           [ZXQRCodeVersion ZXQRCodeVersionWithVersionNumber:40
                                     alignmentPatternCenters:@[@6, @30, @58, @86, @114, @142, @170]
                                                   ecBlocks1:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:30 ecBlocks1:[ZXQRCodeECB ecbWithCount:19 dataCodewords:118] ecBlocks2:[ZXQRCodeECB ecbWithCount:6 dataCodewords:119]]
                                                   ecBlocks2:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:28 ecBlocks1:[ZXQRCodeECB ecbWithCount:18 dataCodewords:47] ecBlocks2:[ZXQRCodeECB ecbWithCount:31 dataCodewords:48]]
                                                   ecBlocks3:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:30 ecBlocks1:[ZXQRCodeECB ecbWithCount:34 dataCodewords:24] ecBlocks2:[ZXQRCodeECB ecbWithCount:34 dataCodewords:25]]
                                                   ecBlocks4:[ZXQRCodeECBlocks ecBlocksWithEcCodewordsPerBlock:30 ecBlocks1:[ZXQRCodeECB ecbWithCount:20 dataCodewords:15] ecBlocks2:[ZXQRCodeECB ecbWithCount:61 dataCodewords:16]]]];
}

@end
