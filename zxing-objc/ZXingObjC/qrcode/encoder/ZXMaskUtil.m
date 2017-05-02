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

#import "ZXByteMatrix.h"
#import "ZXMaskUtil.h"
#import "ZXQRCode.h"

// Penalty weights from section 6.8.2.1
const int N1 = 3;
const int N2 = 3;
const int N3 = 40;
const int N4 = 10;

@implementation ZXMaskUtil

/**
 * Apply mask penalty rule 1 and return the penalty. Find repetitive cells with the same color and
 * give penalty to them. Example: 00000 or 11111.
 */
+ (int)applyMaskPenaltyRule1:(ZXByteMatrix *)matrix {
  return [self applyMaskPenaltyRule1Internal:matrix isHorizontal:YES] + [self applyMaskPenaltyRule1Internal:matrix isHorizontal:NO];
}

/**
 * Apply mask penalty rule 2 and return the penalty. Find 2x2 blocks with the same color and give
 * penalty to them. This is actually equivalent to the spec's rule, which is to find MxN blocks and give a
 * penalty proportional to (M-1)x(N-1), because this is the number of 2x2 blocks inside such a block.
 */
+ (int)applyMaskPenaltyRule2:(ZXByteMatrix *)matrix {
  int penalty = 0;
  int8_t **array = matrix.array;
  int width = matrix.width;
  int height = matrix.height;

  for (int y = 0; y < height - 1; y++) {
    for (int x = 0; x < width - 1; x++) {
      int value = array[y][x];
      if (value == array[y][x + 1] && value == array[y + 1][x] && value == array[y + 1][x + 1]) {
        penalty++;
      }
    }
  }

  return N2 * penalty;
}

/**
 * Apply mask penalty rule 3 and return the penalty. Find consecutive cells of 00001011101 or
 * 10111010000, and give penalty to them.  If we find patterns like 000010111010000, we give
 * penalties twice (i.e. 40 * 2).
 */
+ (int)applyMaskPenaltyRule3:(ZXByteMatrix *)matrix {
  int penalty = 0;
  int8_t **array = matrix.array;
  int width = matrix.width;
  int height = matrix.height;

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      if (x + 6 < width &&
          array[y][x] == 1 &&
          array[y][x +  1] == 0 &&
          array[y][x +  2] == 1 &&
          array[y][x +  3] == 1 &&
          array[y][x +  4] == 1 &&
          array[y][x +  5] == 0 &&
          array[y][x +  6] == 1 &&
          ((x + 10 < width &&
            array[y][x +  7] == 0 &&
            array[y][x +  8] == 0 &&
            array[y][x +  9] == 0 &&
            array[y][x + 10] == 0) ||
           (x - 4 >= 0 &&
            array[y][x -  1] == 0 &&
            array[y][x -  2] == 0 &&
            array[y][x -  3] == 0 &&
            array[y][x -  4] == 0))) {
             penalty += N3;
           }
      if (y + 6 < height &&
          array[y][x] == 1  &&
          array[y +  1][x] == 0  &&
          array[y +  2][x] == 1  &&
          array[y +  3][x] == 1  &&
          array[y +  4][x] == 1  &&
          array[y +  5][x] == 0  &&
          array[y +  6][x] == 1 &&
          ((y + 10 < height &&
            array[y +  7][x] == 0 &&
            array[y +  8][x] == 0 &&
            array[y +  9][x] == 0 &&
            array[y + 10][x] == 0) ||
           (y - 4 >= 0 &&
            array[y -  1][x] == 0 &&
            array[y -  2][x] == 0 &&
            array[y -  3][x] == 0 &&
            array[y -  4][x] == 0))) {
             penalty += N3;
           }
    }
  }
  return penalty;
}

/**
 * Apply mask penalty rule 4 and return the penalty. Calculate the ratio of dark cells and give
 * penalty if the ratio is far from 50%. It gives 10 penalty for 5% distance.
 */
+ (int)applyMaskPenaltyRule4:(ZXByteMatrix *)matrix {
  int numDarkCells = 0;
  int8_t **array = matrix.array;
  int width = matrix.width;
  int height = matrix.height;
  for (int y = 0; y < height; y++) {
    int8_t *arrayY = array[y];
    for (int x = 0; x < width; x++) {
      if (arrayY[x] == 1) {
        numDarkCells++;
      }
    }
  }
  int numTotalCells = [matrix height] * [matrix width];
  double darkRatio = (double) numDarkCells / numTotalCells;
  int fivePercentVariances = abs((int)(darkRatio * 100 - 50)) / 5; // * 100.0 / 5.0
  return fivePercentVariances * N4;
}

/**
 * Return the mask bit for "getMaskPattern" at "x" and "y". See 8.8 of JISX0510:2004 for mask
 * pattern conditions.
 */
+ (BOOL)dataMaskBit:(int)maskPattern x:(int)x y:(int)y {
  int intermediate;
  int temp;
  switch (maskPattern) {
  case 0:
    intermediate = (y + x) & 0x1;
    break;
  case 1:
    intermediate = y & 0x1;
    break;
  case 2:
    intermediate = x % 3;
    break;
  case 3:
    intermediate = (y + x) % 3;
    break;
  case 4:
    intermediate = ((int)((unsigned int)y >> 1) + (x / 3)) & 0x1;
    break;
  case 5:
    temp = y * x;
    intermediate = (temp & 0x1) + (temp % 3);
    break;
  case 6:
    temp = y * x;
    intermediate = ((temp & 0x1) + (temp % 3)) & 0x1;
    break;
  case 7:
    temp = y * x;
    intermediate = ((temp % 3) + ((y + x) & 0x1)) & 0x1;
    break;
  default:
      [NSException raise:NSInvalidArgumentException 
                  format:@"Invalid mask pattern: %d", maskPattern];
  }
  return intermediate == 0;
}

/**
 * Helper function for applyMaskPenaltyRule1. We need this for doing this calculation in both
 * vertical and horizontal orders respectively.
 */
+ (int)applyMaskPenaltyRule1Internal:(ZXByteMatrix *)matrix isHorizontal:(BOOL)isHorizontal {
  int penalty = 0;
  int iLimit = isHorizontal ? matrix.height : matrix.width;
  int jLimit = isHorizontal ? matrix.width : matrix.height;
  int8_t **array = matrix.array;
  for (int i = 0; i < iLimit; i++) {
    int numSameBitCells = 0;
    int prevBit = -1;
    for (int j = 0; j < jLimit; j++) {
      int bit = isHorizontal ? array[i][j] : array[j][i];
      if (bit == prevBit) {
        numSameBitCells++;
      } else {
        if (numSameBitCells >= 5) {
          penalty += N1 + (numSameBitCells - 5);
        }
        numSameBitCells = 1;  // Include the cell itself.
        prevBit = bit;
      }
    }
    if (numSameBitCells >= 5) {
      penalty += N1 + (numSameBitCells - 5);
    }
  }
  return penalty;
}

@end
