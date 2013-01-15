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

//BOOL SCImageCopyBlock_ARGB8888(const uint8_t *data, vImage_Buffer *block, size_t sblock, size_t xblock, size_t yblock, size_t width, size_t height, size_t bytesPerPixel, size_t bytesPerRow);

