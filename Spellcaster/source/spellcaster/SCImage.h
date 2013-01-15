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
static inline const uint8_t * SCImageGetPixel(const vImage_Buffer *data, size_t bytesPerPixel, size_t x, size_t y) {
  size_t offset = (y * data->rowBytes) + (x * bytesPerPixel);
  return (offset < ((data->rowBytes * data->height) - bytesPerPixel)) ? (data->data + offset) : NULL;
}

BOOL SCImagePixelsEqual(const vImage_Buffer *data1, const vImage_Buffer *data2, size_t bytesPerPixel, size_t threshold, size_t x, size_t y);
BOOL SCImageBlocksEqual(const vImage_Buffer *data1, const vImage_Buffer *data2, size_t bytesPerPixel, size_t threshold, size_t xblock, size_t yblock, size_t blocksize);
BOOL SCImageCopyOutSequentialBlock(const vImage_Buffer *data, uint8_t *block, size_t bytesPerPixel, size_t xblock, size_t yblock, size_t blocksize);
BOOL SCImageCopyInSequentialBlock(const uint8_t *block, vImage_Buffer *data, size_t bytesPerPixel, size_t xblock, size_t yblock, size_t blocksize);

const uint8_t * SCImageGetPixel_ARGB8888(const vImage_Buffer *data, size_t x, size_t y);
BOOL SCImagePixelsEqual_ARGB8888(const vImage_Buffer *data1, const vImage_Buffer *data2, size_t threshold, size_t x, size_t y);
BOOL SCImageBlocksEqual_ARGB8888(const vImage_Buffer *data1, const vImage_Buffer *data2, size_t threshold, size_t xblock, size_t yblock, size_t blocksize);
BOOL SCImageCopyOutSequentialBlock_ARGB8888(const vImage_Buffer *data, uint8_t *block, size_t xblock, size_t yblock, size_t blocksize);
BOOL SCImageCopyInSequentialBlock_ARGB8888(const uint8_t *block, vImage_Buffer *data, size_t xblock, size_t yblock, size_t blocksize);

