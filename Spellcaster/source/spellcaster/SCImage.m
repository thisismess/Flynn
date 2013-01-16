// 
// Copyright 2013 Mess, All rights reserved.
// 
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
// THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.
// 
// Made by Mess - http://thisismess.com/
// 

#import "SCImage.h"

static const size_t kSCImageBytesPerPixel_ARGB8888 = 4;

/**
 * Compare a pixel between two images
 */
BOOL SCImagePixelsEqual(const vImage_Buffer *data1, const vImage_Buffer *data2, size_t bytesPerPixel, size_t threshold, size_t x, size_t y) {
  assert(data1 != NULL);
  assert(data2 != NULL);
  const uint8_t *a = SCImageGetPixel(data1, bytesPerPixel, x, y);
  const uint8_t *b = SCImageGetPixel(data2, bytesPerPixel, x, y);
  if(a == b) return TRUE; // same memory, must be the same
  if(a == NULL || b == NULL) return FALSE;
  size_t misses = 0;
  for(int i = 0; i < bytesPerPixel; i++){ if(a[i] != b[i] && ++misses > threshold) return FALSE; }
  return TRUE; // we've processed the pixel and all's well
}

/**
 * Compare a block row of pixel between two images
 */
BOOL SCImageStripesEqual(const vImage_Buffer *data1, const vImage_Buffer *data2, size_t bytesPerPixel, size_t threshold, size_t x, size_t y, size_t blocksize) {
  assert(data1 != NULL);
  assert(data2 != NULL);
  const uint8_t *a = SCImageGetPixel(data1, bytesPerPixel, x, y);
  const uint8_t *b = SCImageGetPixel(data2, bytesPerPixel, x, y);
  if(a == b) return TRUE; // same memory, must be the same
  if(a == NULL || b == NULL) return FALSE;
  size_t misses = 0;
  for(int i = 0; i < (bytesPerPixel * blocksize); i++){
    if((*a++ != *b++) && ++misses > threshold){ return FALSE; }
  }
  return TRUE;
}

/**
 * Compare a block of pixel between two images
 */
BOOL SCImageBlocksEqual(const vImage_Buffer *data1, const vImage_Buffer *data2, size_t bytesPerPixel, size_t threshold, size_t xblock, size_t yblock, size_t blocksize) {
  for(int y = 0; y < blocksize; y++){
    if(!SCImageStripesEqual(data1, data2, bytesPerPixel, threshold, (xblock * blocksize), (yblock * blocksize) + y, blocksize)){
      return FALSE;
    }
  }
  return TRUE;
}

/**
 * Copy a block from the provided image data into the provided buffer. The @p block buffer must
 * have enough room to store the block (bytesPerPixel * blocksize * blocksize). Data is copied
 * into the block sequentially from left to right, top to bottom.
 */
BOOL SCImageCopyOutSequentialBlock(const vImage_Buffer *data, uint8_t *block, size_t bytesPerPixel, size_t xblock, size_t yblock, size_t blocksize) {
  assert(data != NULL);
  assert(block != NULL);
  size_t index = 0, bytesPerRow = bytesPerPixel * blocksize;
  for(int y = 0; y < blocksize; y++){
    const uint8_t *row;
    if((row = SCImageGetPixel(data, bytesPerPixel, (xblock * blocksize), (yblock * blocksize) + y)) == NULL) return FALSE;
    memcpy(block + index, row, bytesPerRow);
    index += bytesPerRow;
  }
  return TRUE;
}

/**
 * Copy a block from the provided buffer into the provided image data. The image @p data must
 * have enough room to store the at its offset. Data is copied from the block sequentially into
 * the image.
 */
BOOL SCImageCopyInSequentialBlock(const uint8_t *block, vImage_Buffer *data, size_t bytesPerPixel, size_t xblock, size_t yblock, size_t blocksize) {
  assert(block != NULL);
  assert(data != NULL);
  size_t index = 0, bytesPerRow = bytesPerPixel * blocksize;
  for(int y = 0; y < blocksize; y++){
    uint8_t *row;
    if((row = (uint8_t *)SCImageGetPixel(data, bytesPerPixel, (xblock * blocksize), (yblock * blocksize) + y)) == NULL) return FALSE;
    memcpy(row, block + index, bytesPerRow);
    //for(int i = 0; i < blocksize; i++) fprintf(stderr, "%02x", *(block + index + i));
    //fputc('\n', stderr);
    index += bytesPerRow;
  }
  return TRUE;
}

/**
 * Obtain a pixel offset in the provided image data
 */
const uint8_t * SCImageGetPixel_ARGB8888(const vImage_Buffer *data, size_t x, size_t y) {
  return SCImageGetPixel(data, kSCImageBytesPerPixel_ARGB8888, x, y);
}

/**
 * Compare a pixel between two images
 */
BOOL SCImagePixelsEqual_ARGB8888(const vImage_Buffer *data1, const vImage_Buffer *data2, size_t threshold, size_t x, size_t y) {
  return SCImagePixelsEqual(data1, data2, kSCImageBytesPerPixel_ARGB8888, threshold, x, y);
}

/**
 * Compare a block of pixel between two images
 */
BOOL SCImageBlocksEqual_ARGB8888(const vImage_Buffer *data1, const vImage_Buffer *data2, size_t threshold, size_t xblock, size_t yblock, size_t blocksize) {
  return SCImageBlocksEqual(data1, data2, kSCImageBytesPerPixel_ARGB8888, threshold, xblock, yblock, blocksize);
}

/**
 * Copy a block of pixel from the provided image data into the provided buffer.
 */
BOOL SCImageCopyOutSequentialBlock_ARGB8888(const vImage_Buffer *data, uint8_t *block, size_t xblock, size_t yblock, size_t blocksize) {
  return SCImageCopyOutSequentialBlock(data, block, kSCImageBytesPerPixel_ARGB8888, xblock, yblock, blocksize);
}

/**
 * Copy a block from the provided buffer into the provided image data.
 */
BOOL SCImageCopyInSequentialBlock_ARGB8888(const uint8_t *block, vImage_Buffer *data, size_t xblock, size_t yblock, size_t blocksize) {
  return SCImageCopyInSequentialBlock(block, data, kSCImageBytesPerPixel_ARGB8888, xblock, yblock, blocksize);
}

