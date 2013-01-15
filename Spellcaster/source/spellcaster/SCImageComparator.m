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

#import "SCImageComparator.h"
#import "SCImage.h"
#import "SCError.h"

@implementation SCImageComparator

@synthesize currentImage = _currentImage;
@synthesize blockLength = _blockLength;

/**
 * Clean up
 */
-(void)dealloc {
  if(_currentImage) CFRelease(_currentImage);
  [super dealloc];
}

/**
 * Initialize with a keyframe
 */
-(id)initWithKeyframeImage:(CGImageRef)keyframe blockLength:(NSUInteger)blockLength {
  if((self = [super init]) != nil){
    if(keyframe != NULL) _currentImage = CGImageRetain(keyframe);
    _blockLength = blockLength;
  }
  return self;
}

/**
 * Obtain block ranges that should be updated between the current frame and
 * the provided image. The parameter image is retained as the current frame
 * for use in a subsequent invocation.
 */
-(NSArray *)updateBlocksForImage:(CGImageRef)image error:(NSError **)error {
  NSMutableArray *ranges = [NSMutableArray array];
  if(_currentImage != NULL){
    CGDataProviderRef dataProvider;
    
    size_t width  = CGImageGetWidth(image);
    size_t height = CGImageGetHeight(image);
    size_t bytesPerRow = CGImageGetBytesPerRow(image);
    size_t bitsPerPixel = CGImageGetBitsPerPixel(image);
    size_t bitsPerComponent = CGImageGetBitsPerComponent(image);
    size_t bytesPerPixel = bitsPerPixel / bitsPerComponent;
    
    // make sure the next image matches the dimensions of the current image
    if(CGImageGetWidth(_currentImage) != width || CGImageGetWidth(_currentImage) != width){
      if(error) *error = [NSError errorWithDomain:kSCSpellcasterErrorDomain code:kSCStatusError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"Frame images in an animation must be exactly the same size (%zdx%zd)", CGImageGetWidth(_currentImage), CGImageGetHeight(_currentImage)], NSLocalizedDescriptionKey, nil]];
      return nil;
    }
    
    // make sure the image is has dimensions in multiples of blocks
    if((width % _blockLength) != 0 || (height & _blockLength) != 0){
      if(error) *error = [NSError errorWithDomain:kSCSpellcasterErrorDomain code:kSCStatusError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"Frame image must have dimensions in multiples of blocks (%ldx%ld)", _blockLength, _blockLength], NSLocalizedDescriptionKey, nil]];
      return nil;
    }
    
    dataProvider = CGImageGetDataProvider(_currentImage);
    NSData *currData = (NSData *)CGDataProviderCopyData(dataProvider);
    const uint8_t *currentPixels = [currData bytes];
    
    vImage_Buffer currentBuffer;
    currentBuffer.data = (void *)currentPixels;
    currentBuffer.width = width;
    currentBuffer.height = height;
    currentBuffer.rowBytes = bytesPerRow;
    
    dataProvider = CGImageGetDataProvider(image);
    NSData *nextData = (NSData *)CGDataProviderCopyData(dataProvider);
    const uint8_t *nextPixels = [nextData bytes];
    
    vImage_Buffer updateBuffer;
    updateBuffer.data = (void *)nextPixels;
    updateBuffer.width = width;
    updateBuffer.height = height;
    updateBuffer.rowBytes = bytesPerRow;
    
    size_t wblocks = width / _blockLength;
    size_t hblocks = height / _blockLength;
    ssize_t position = -1;
    size_t x = 0, y = 0;
    
    for(y = 0; y < hblocks; y++){
      for(x = 0; x < wblocks; x++){
        if(!SCImageBlocksEqual(&currentBuffer, &updateBuffer, bytesPerPixel, 1, x, y, _blockLength)){
          // update the range offset if we're not already in a run
          if(position < 0) position = (y * wblocks) + x;
        }else if(position >= 0){
          [ranges addObject:[SCRange rangeWithPosition:position count:((y * wblocks) + x) - position]];
          position = -1; // clear the run offset position
        }
      }
    }
    
    // handle the last row
    if(position >= 0){
      [ranges addObject:[SCRange rangeWithPosition:position count:((y * wblocks) + x) - position]];
    }
    
    [currData release];
    [nextData release];
    
    CGImageRelease(_currentImage);
    _currentImage = CGImageRetain(image);
    
  }
  return ranges;
}

@end

