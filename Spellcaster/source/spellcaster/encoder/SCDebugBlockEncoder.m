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

#import "SCDebugBlockEncoder.h"
#import "SCUtility.h"
#import "SCImage.h"
#import "SCError.h"
#import "SCLog.h"

@implementation SCDebugBlockEncoder

/**
 * Clean up
 */
-(void)dealloc {
  [super dealloc];
}

/**
 * Initialize with an output directory and file prefix
 */
-(id)initWithDirectoryPath:(NSString *)directory prefix:(NSString *)prefix imageLength:(NSUInteger)imageLength blockLength:(NSUInteger)blockLength bytesPerPixel:(NSUInteger)bytesPerPixel {
  if((self = [super initWithDirectoryPath:directory prefix:prefix imageLength:imageLength blockLength:blockLength bytesPerPixel:bytesPerPixel]) != nil){
    // ...
  }
  return self;
}

/**
 * Open a frame sequence for reading
 */
-(BOOL)open:(NSError **)error {
  BOOL exists, isdir = FALSE;
  NSError *inner = nil;
  
  // setup our output directory
  if((exists = [[NSFileManager defaultManager] fileExistsAtPath:_directory isDirectory:&isdir]) && !isdir){
    if(error) *error = [NSError errorWithDomain:kSCSpellcasterErrorDomain code:kSCStatusError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"File at path exists but does not represent a directory: %@", _directory], NSLocalizedDescriptionKey, nil]];
    return FALSE;
  }else if(!exists && ![[NSFileManager defaultManager] createDirectoryAtPath:_directory withIntermediateDirectories:TRUE attributes:nil error:&inner]){
    if(error) *error = [NSError errorWithDomain:kSCSpellcasterErrorDomain code:kSCStatusError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"Could not create export directory: %@", [inner localizedDescription]], NSLocalizedDescriptionKey, nil]];
    return FALSE;
  }
  
  return TRUE;
}

/**
 * Open a previously opened frame sequence
 */
-(BOOL)close:(NSError **)error {
  return TRUE;
}

/**
 * Encode block ranges for the provided image. If an error occurs, NULL is returned and
 * the error is described in the @p error parameter, if present.
 */
-(BOOL)encodeBlocks:(NSArray *)blocks forImage:(CGImageRef)image error:(NSError **)error {
  NSData *imageData = nil;
  NSError *inner = nil;
  BOOL status = FALSE;
  
  CGColorSpaceRef colorspace = NULL;
  CGDataProviderRef outputDataProvider = NULL;
  CGImageRef outputImage = NULL;
  uint8_t *outputBuffer = NULL;
  
  // make sure the image is valid
  if(image == NULL){
    if(error) *error = [NSError errorWithDomain:kSCSpellcasterErrorDomain code:kSCStatusError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Frame image must not be null", NSLocalizedDescriptionKey, nil]];
    goto error;
  }
  
  // lookup image info
  size_t width  = CGImageGetWidth(image);
  size_t height = CGImageGetHeight(image);
  size_t bitsPerComponent = CGImageGetBitsPerComponent(image);
  size_t bitsPerPixel = CGImageGetBitsPerPixel(image);
  size_t bytesPerRow = CGImageGetBytesPerRow(image);
  size_t bytesPerPixel = bitsPerPixel / bitsPerComponent;
  
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
  
  // obtain our image data provider
  CGDataProviderRef dataProvider = CGImageGetDataProvider(image);
  // unpack our image data
  imageData = (NSData *)CGDataProviderCopyData(dataProvider);
  
  // note our buffer length
  size_t outputLength = height * bytesPerRow;
  // setup our output buffer
  outputBuffer = malloc(outputLength);
  // copy in our image data
  memcpy(outputBuffer, [imageData bytes], outputLength);
  
  // setup our image buffer
  vImage_Buffer buffer;
  buffer.data = outputBuffer;
  buffer.width = width;
  buffer.height = height;
  buffer.rowBytes = bytesPerRow;
  
  // copy in blocks
  for(SCRange *block in blocks){
    for(size_t i = 0; i < block.count; i++){
      size_t position = block.position + i;
      size_t xblock = position % wblocks;
      size_t yblock = position / wblocks;
      for(int y = 0; y < _blockLength; y++){
        for(int x = 0; x < _blockLength; x++){
          uint8_t *pixel = (uint8_t *)SCImageGetPixel(&buffer, _bytesPerPixel, (xblock * _blockLength) + x, (yblock * _blockLength) + y);
          memset(pixel, 0x7f, bytesPerPixel);
        }
      }
    }
  }
  
  // setup our colorspace
  colorspace = CGColorSpaceCreateDeviceRGB();
  // setup our data provider
  outputDataProvider = CGDataProviderCreateWithData(NULL, outputBuffer, height * bytesPerRow, NULL);
  
  // create our output image
  if((outputImage = CGImageCreate(width, height, bitsPerComponent, bitsPerPixel, bytesPerRow, colorspace, CGImageGetBitmapInfo(image), outputDataProvider, NULL, FALSE, kCGRenderingIntentDefault)) == NULL){
    if(error) *error = NSERROR(kSCSpellcasterErrorDomain, kSCStatusError, @"Could not create frame image: %@", [inner localizedDescription]);
    goto error;
  }
  
  // setup our output path
  NSString *outputPath = [self.directory stringByAppendingPathComponent:[NSString stringWithFormat:@"spellcaster_%03zd.png", _encodedImages + 1]];
  
  // write our diff frame out
  if(!SCImageWritePNGToPath(outputImage, outputPath, &inner)){
    if(error) *error = NSERROR(kSCSpellcasterErrorDomain, kSCStatusError, @"Could not write frame image: %@", [inner localizedDescription]);
    goto error;
  }
  
  status = TRUE;
error:
  if(colorspace) CFRelease(colorspace);
  if(outputDataProvider) CFRelease(outputDataProvider);
  if(outputImage) CFRelease(outputImage);
  if(outputBuffer) free(outputBuffer);
  [imageData release];
  _encodedImages++; // increment the count
  
  return status;
}

@end

