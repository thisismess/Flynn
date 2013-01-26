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

#import <Accelerate/Accelerate.h>

/**
 * Obtain a pixel offset in the provided image data
 */
static inline const uint8_t * FLImageGetPixel(const vImage_Buffer *data, size_t bytesPerPixel, size_t x, size_t y) {
  size_t offset = (y * data->rowBytes) + (x * bytesPerPixel);
  return (offset <= ((data->rowBytes * data->height) - bytesPerPixel)) ? (data->data + offset) : NULL;
}

/**
 * Display a range of pixels
 */
static inline void FLImageDisplayPixels(const vImage_Buffer *data, size_t bytesPerPixel, size_t x, size_t y, size_t count) {
  const uint8_t *row;
  if((row = FLImageGetPixel(data, bytesPerPixel, x, y)) != NULL){
    fprintf(stderr, "%ld @ %4ld, %4ld: ", count, x, y);
    for(int i = 0; i < count * bytesPerPixel; i++){
      fprintf(stderr, "%02x", *row++);
      if((i + 1) % bytesPerPixel == 0) fputc(' ', stderr);
    }
    fputc('\n', stderr);
  }
}

BOOL FLImagePixelsEqual(const vImage_Buffer *data1, const vImage_Buffer *data2, size_t bytesPerPixel, size_t threshold, size_t x, size_t y);
BOOL FLImageStripesEqual(const vImage_Buffer *data1, const vImage_Buffer *data2, size_t bytesPerPixel, size_t threshold, size_t x, size_t y, size_t blocksize);
BOOL FLImageBlocksEqual(const vImage_Buffer *data1, const vImage_Buffer *data2, size_t bytesPerPixel, size_t threshold, size_t xblock, size_t yblock, size_t blocksize);
BOOL FLImageCopyOutSequentialBlock(const vImage_Buffer *data, uint8_t *block, size_t bytesPerPixel, size_t xblock, size_t yblock, size_t blocksize);
BOOL FLImageCopyInSequentialBlock(const uint8_t *block, vImage_Buffer *data, size_t bytesPerPixel, size_t xblock, size_t yblock, size_t blocksize);

const uint8_t * FLImageGetPixel_ARGB8888(const vImage_Buffer *data, size_t x, size_t y);
BOOL FLImagePixelsEqual_ARGB8888(const vImage_Buffer *data1, const vImage_Buffer *data2, size_t threshold, size_t x, size_t y);
BOOL FLImageBlocksEqual_ARGB8888(const vImage_Buffer *data1, const vImage_Buffer *data2, size_t threshold, size_t xblock, size_t yblock, size_t blocksize);
BOOL FLImageCopyOutSequentialBlock_ARGB8888(const vImage_Buffer *data, uint8_t *block, size_t xblock, size_t yblock, size_t blocksize);
BOOL FLImageCopyInSequentialBlock_ARGB8888(const uint8_t *block, vImage_Buffer *data, size_t xblock, size_t yblock, size_t blocksize);

