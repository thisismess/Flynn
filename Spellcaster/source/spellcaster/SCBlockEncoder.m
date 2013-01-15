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

#import "SCBlockEncoder.h"
#import "SCImage.h"
#import "SCError.h"

static const NSUInteger kSCBlockEncoderMaxImageLength = 1624;

@implementation SCBlockEncoder

@synthesize directory = _directory;
@synthesize prefix = _prefix;
@synthesize blockLength = _blockLength;
@synthesize bytesPerPixel = _bytesPerPixel;

/**
 * Clean up
 */
-(void)dealloc {
  if(_blockBuffer) free(_blockBuffer);
  if(_imageBuffer) free(_imageBuffer);
  [_directory release];
  [_prefix release];
  [super dealloc];
}

/**
 * Initialize with an output directory and file prefix
 */
-(id)initWithDirectoryPath:(NSString *)directory prefix:(NSString *)prefix blockLength:(NSUInteger)blockLength bytesPerPixel:(NSUInteger)bytesPerPixel {
  if((self = [super init]) != nil){
    _directory = [directory copy];
    _prefix = [prefix copy];
    _blockLength = blockLength;
    _bytesPerPixel = bytesPerPixel;
    _length = kSCBlockEncoderMaxImageLength * kSCBlockEncoderMaxImageLength * bytesPerPixel;
    _blockBuffer = malloc(_length);
    _imageBuffer = malloc(_length);
  }
  return self;
}

/**
 * Open a frame sequence for reading
 */
-(BOOL)open:(NSError **)error {
  BOOL exists, isdir = FALSE;
  NSError *inner = nil;
  
  if((exists = [[NSFileManager defaultManager] fileExistsAtPath:_directory isDirectory:&isdir]) && !isdir){
    if(error) *error = [NSError errorWithDomain:kSCSpellcasterErrorDomain code:kSCStatusError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"File at path exists but does not represent a directory: %@", _directory], NSLocalizedDescriptionKey, nil]];
    return FALSE;
  }else if(!exists && ![[NSFileManager defaultManager] createDirectoryAtPath:_directory withIntermediateDirectories:TRUE attributes:nil error:&inner]){
    if(error) *error = [NSError errorWithDomain:kSCSpellcasterErrorDomain code:kSCStatusError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"Could not create export directory: %@", [inner localizedDescription]], NSLocalizedDescriptionKey, nil]];
    return FALSE;
  }
  
  // clear the offset
  _offset = 0;
  
  return TRUE;
}

/**
 * Open a previously opened frame sequence
 */
-(BOOL)close:(NSError **)error {
  return [self flushBufferWithError:error];
}

/**
 * Encode block ranges for the provided image. If an error occurs, NULL is returned and
 * the error is described in the @p error parameter, if present.
 */
-(BOOL)encodeBlocks:(NSArray *)blocks forImage:(CGImageRef)image error:(NSError **)error {
  NSData *imageData = nil;
  BOOL status = FALSE;
  
  // make sure the image is valid
  if(image == NULL){
    if(error) *error = [NSError errorWithDomain:kSCSpellcasterErrorDomain code:kSCStatusError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Frame image must not be null", NSLocalizedDescriptionKey, nil]];
    goto error;
  }
  
  // lookup image info
  size_t width  = CGImageGetWidth(image);
  size_t height = CGImageGetHeight(image);
  size_t bytesPerRow = CGImageGetBytesPerRow(image);
  size_t bytesPerPixel = CGImageGetBitsPerPixel(image) / CGImageGetBitsPerComponent(image);
  size_t bytesPerBlock = _bytesPerPixel * _blockLength * _blockLength;
  
  // make sure the image has the correct number of bytes per pixel
  if(bytesPerPixel != self.bytesPerPixel){
    if(error) *error = [NSError errorWithDomain:kSCSpellcasterErrorDomain code:kSCStatusError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"Frame image must use a pixel format with %ld bytes per pixel", self.bytesPerPixel], NSLocalizedDescriptionKey, nil]];
    goto error;
  }
  
  // make sure the image is has dimensions in multiples of blocks
  if((width % _blockLength) != 0 || (height % _blockLength) != 0){
    if(error) *error = [NSError errorWithDomain:kSCSpellcasterErrorDomain code:kSCStatusError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"Frame image must have dimensions in multiples of blocks (%ldx%ld)", _blockLength, _blockLength], NSLocalizedDescriptionKey, nil]];
    goto error;
  }
  
  // determine block dimensions
  size_t wblocks = width / _blockLength;
  
  // unpack our image data
  CGDataProviderRef dataProvider = CGImageGetDataProvider(image);
  imageData = (NSData *)CGDataProviderCopyData(dataProvider);
  
  vImage_Buffer buffer;
  buffer.data = (void *)[imageData bytes];
  buffer.width = width;
  buffer.height = height;
  buffer.rowBytes = bytesPerRow;
  
  // copy in blocks
  for(SCRange *block in blocks){
    for(size_t i = 0; i < block.count; i++){
      size_t position = block.position + i;
      
      // make sure we have room for our block
      if((_offset + bytesPerBlock) >= _length){
        if(![self flushBufferWithError:error]){
          return FALSE;
        }
      }
      
      // determine our block coordinates for the block offset
      size_t xblock = position % wblocks;
      size_t yblock = position / wblocks;
      
      // copy in our block
      if(!SCImageCopyOutSequentialBlock(&buffer, _blockBuffer + _offset, bytesPerPixel, xblock, yblock, _blockLength)){
        if(error) *error = [NSError errorWithDomain:kSCSpellcasterErrorDomain code:kSCStatusError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"Could not copy block at position %ld (%ld, %ld)", position, xblock, yblock], NSLocalizedDescriptionKey, nil]];
        goto error;
      }
      
      // increment our offset by one block
      _offset += bytesPerBlock;
      
    }
  }
  
  status = TRUE;
error:
  [imageData release];
  
  return status;
}

/**
 * Flush the buffer to disk as an image.
 */
-(BOOL)flushBufferWithError:(NSError **)error {
  BOOL status = FALSE;
  
  CGColorSpaceRef colorspace = NULL;
  CGDataProviderRef dataProvider = NULL;
  CGImageDestinationRef imageDestination = NULL;
  CGImageRef image = NULL;
  
  // make sure we have some data
  if(_offset < 1){
    if(error) *error = [NSError errorWithDomain:kSCSpellcasterErrorDomain code:kSCStatusError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Block buffer contains no data", NSLocalizedDescriptionKey, nil]];
    goto error;
  }
  
  // determine the dimensions required for our image, in blocks
  size_t blocks = _offset / _blockLength / _blockLength / _bytesPerPixel;
  // determine the smallest square image we can use to represent those blocks, in blocks (this could be a better)
  size_t imageLength = ceil(sqrt((double)blocks));
  // determine our pixel dimensions
  size_t width = imageLength * _blockLength, height = imageLength * _blockLength;
  // determine the length of a single block, in bytes
  size_t bytesPerBlock = _bytesPerPixel * _blockLength * _blockLength;
  
  // make sure we don't exceed our dimension constraints
  if(width > kSCBlockEncoderMaxImageLength || height > kSCBlockEncoderMaxImageLength){
    if(error) *error = [NSError errorWithDomain:kSCSpellcasterErrorDomain code:kSCStatusError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Block buffer is too large", NSLocalizedDescriptionKey, nil]];
    goto error;
  }
  
  // setup our image buffer
  vImage_Buffer buffer;
  buffer.width = width;
  buffer.height = height;
  buffer.data = _imageBuffer;
  buffer.rowBytes = _bytesPerPixel * buffer.width;
  
  // build our image by assembling sequential blocks
  for(int i = 0; i < blocks && (i * bytesPerBlock) < _length; i++){
    // determine our block coordinates for the block offset
    size_t xblock = i % imageLength, yblock = i / imageLength;
    // copy in the block
    if(!SCImageCopyInSequentialBlock(_blockBuffer + (i * bytesPerBlock), &buffer, _bytesPerPixel, xblock, yblock, _blockLength)){
      if(error) *error = [NSError errorWithDomain:kSCSpellcasterErrorDomain code:kSCStatusError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Could not copy image block", NSLocalizedDescriptionKey, nil]];
      goto error;
    }
  }
  
  // setup our output path
  NSString *outputPath = [self.directory stringByAppendingPathComponent:[NSString stringWithFormat:@"frame-%04zd.png", _encodedImages]];
  //
  NSLog(@"Export %ldx%ld for %ld bytes (%ld blocks): %@", width, height, _offset, blocks, outputPath);
  
  // setup our colorspace
  colorspace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
  
  // setup our data provider
  if((dataProvider = CGDataProviderCreateWithData(NULL, buffer.data, buffer.rowBytes * height, NULL)) == NULL){
    if(error) *error = [NSError errorWithDomain:kSCSpellcasterErrorDomain code:kSCStatusError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Could not create image data provider", NSLocalizedDescriptionKey, nil]];
    goto error;
  }
  
  // create an image from our buffer
  if((image = CGImageCreate(width, height, 8, _bytesPerPixel * 8, buffer.rowBytes, colorspace, kCGImageAlphaLast, dataProvider, NULL, FALSE, kCGRenderingIntentDefault)) == NULL){
    if(error) *error = [NSError errorWithDomain:kSCSpellcasterErrorDomain code:kSCStatusError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Could not create image from block data", NSLocalizedDescriptionKey, nil]];
    goto error;
  }
  
  // create a destination for our image
  if((imageDestination = CGImageDestinationCreateWithURL((CFURLRef)[NSURL fileURLWithPath:outputPath], kUTTypeJPEG, 1, nil)) == NULL){
    if(error) *error = [NSError errorWithDomain:kSCSpellcasterErrorDomain code:kSCStatusError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Could not create image destination", NSLocalizedDescriptionKey, nil]];
    goto error;
  }
  
  // add our image to the destination
  CGImageDestinationAddImage(imageDestination, image, NULL);
  
  // finalize our image destination
  if(!CGImageDestinationFinalize(imageDestination)){
    if(error) *error = [NSError errorWithDomain:kSCSpellcasterErrorDomain code:kSCStatusError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Could not finalize image destination", NSLocalizedDescriptionKey, nil]];
    goto error;
  }
  
  status = TRUE;
error:
  if(colorspace) CFRelease(colorspace);
  if(dataProvider) CFRelease(dataProvider);
  if(imageDestination) CFRelease(imageDestination);
  if(image) CFRelease(image);
  _encodedImages++; // increment the count
  _offset = 0; // clear the offset
  
  return status;
}

@end

