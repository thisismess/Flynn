// 
// @COPYRIGHT_NOTICE@
// 
// @MESS_LICENSE_START@
// 
// This software is provided to you by Kaart Marketing, LLC, d/b/a Mess
// Marketing ('Mess') in consideration of your acceptance of the terms
// under which it was developed for or licensed to you (the 'Agreement').
// You may not use this software except in compliance with the Agreement.
// 
// The Mess Software is provided by Mess on an "AS IS" basis.  MESS MAKES NO
// WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
// WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A
// PARTICULAR PURPOSE, REGARDING THE MESS SOFTWARE OR ITS USE AND OPERATION
// ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
// 
// IN NO EVENT SHALL MESS BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION
// AND/OR DISTRIBUTION OF THE MESS SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER
// THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR
// OTHERWISE, EVEN IF MESS HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
// 
// @MESS_LICENSE_END@
// 
// Designed and developed by Mess - http://thisismess.com/
// 

#import "SCImage.h"

static const size_t kSCImageBytesPerPixel_ARGB8888 = 4;

/**
 * Compare a pixel between two images
 */
BOOL SCImagePixelsEqual(const vImage_Buffer *data1, const vImage_Buffer *data2, size_t bytesPerPixel, float threshold, size_t x, size_t y) {
  assert(data1 != NULL);
  assert(data2 != NULL);
  const uint8_t *a = SCImageGetPixel(data1, bytesPerPixel, x, y);
  const uint8_t *b = SCImageGetPixel(data2, bytesPerPixel, x, y);
  if(a == b) return TRUE; // same memory, must be the same
  if(a == NULL || b == NULL) return FALSE;
  for(int i = 0; i < bytesPerPixel; i++){ if(abs(a[i] - b[i]) > threshold) return FALSE; }
  return TRUE; // we've processed the pixel and all's well
}

/**
 * Compare a block of pixel between two images
 */
BOOL SCImageBlocksEqual(const vImage_Buffer *data1, const vImage_Buffer *data2, size_t bytesPerPixel, float threshold, size_t xblock, size_t yblock, size_t blocksize) {
  for(int y = 0; y < blocksize; y++){
    for(int x = 0; x < blocksize; x++){
      if(!SCImagePixelsEqual(data1, data2, bytesPerPixel, threshold, (xblock * blocksize) + x, (yblock * blocksize) + y)){
        // pixels don't match, so blocks don't match, return false
        return FALSE;
      }
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
BOOL SCImagePixelsEqual_ARGB8888(const vImage_Buffer *data1, const vImage_Buffer *data2, float threshold, size_t x, size_t y) {
  return SCImagePixelsEqual(data1, data2, kSCImageBytesPerPixel_ARGB8888, threshold, x, y);
}

/**
 * Compare a block of pixel between two images
 */
BOOL SCImageBlocksEqual_ARGB8888(const vImage_Buffer *data1, const vImage_Buffer *data2, float threshold, size_t xblock, size_t yblock, size_t blocksize) {
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

