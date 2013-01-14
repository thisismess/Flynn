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

/**
 * Obtain a pixel offset in the provided image data
 */
const uint8_t * SCImageGetPixel_ARGB8888(const uint8_t *data, size_t x, size_t y, size_t width, size_t height, size_t bytesPerPixel, size_t bytesPerRow) {
  size_t offset = (y * bytesPerRow) + (x * bytesPerPixel);
  return (offset < ((bytesPerRow * height) - bytesPerPixel)) ? (data + offset) : NULL;
}

/**
 * Compare a pixel between two images
 */
BOOL SCImageComparePixels_ARGB8888(const uint8_t *data1, const uint8_t *data2, float threshold, size_t x, size_t y, size_t width, size_t height, size_t bytesPerPixel, size_t bytesPerRow) {
  const uint8_t *a = SCImageGetPixel_ARGB8888(data1, x, y, width, height, bytesPerPixel, bytesPerRow);
  const uint8_t *b = SCImageGetPixel_ARGB8888(data2, x, y, width, height, bytesPerPixel, bytesPerRow);
  if(a == b) return TRUE; // same memory or both null, must be the same
  if(a == NULL || b == NULL) return FALSE;
  for(int i = 0; i < bytesPerPixel; i++){ if(abs(a[i] - b[i]) > threshold) return FALSE; }
  return TRUE; // we've processed the entire pixel and all's well
}

/**
 * Compare a block of pixel between two images
 */
BOOL SCImageCompareBlocks_ARGB8888(const uint8_t *data1, const uint8_t *data2, float threshold, size_t sblock, size_t xblock, size_t yblock, size_t width, size_t height, size_t bytesPerPixel, size_t bytesPerRow) {
  for(int y = 0; y < sblock; y++){
    for(int x = 0; x < sblock; x++){
      if(!SCImageComparePixels_ARGB8888(data1, data2, threshold, (xblock * sblock) + x, (yblock * sblock) + y, width, height, bytesPerPixel, bytesPerRow)) return FALSE;
    }
  }
  return TRUE;
}


