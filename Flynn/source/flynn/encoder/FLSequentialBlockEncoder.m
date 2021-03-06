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

#import "FLSequentialBlockEncoder.h"
#import "FLUtility.h"
#import "FLCodec.h"
#import "FLImage.h"
#import "FLError.h"
#import "FLLog.h"

@implementation FLSequentialBlockEncoder

/**
 * Clean up
 */
-(void)dealloc {
  if(_blockBuffer) free(_blockBuffer);
  if(_imageBuffer) free(_imageBuffer);
  [super dealloc];
}

/**
 * Initialize with an output directory and file prefix
 */
-(id)initWithKeyframeImage:(CGImageRef)keyframe outputDirectory:(NSString *)directory namespace:(NSString *)namespace codecSettings:(NSDictionary *)codecSettings error:(NSError **)error {
  if((self = [super initWithKeyframeImage:keyframe outputDirectory:directory namespace:namespace codecSettings:codecSettings error:error]) != nil){
    _length = self.imageLength * self.imageLength * self.bytesPerPixel;
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
  
  // clear the offset
  _offset = 0;
  
  // setup our output directory
  if((exists = [[NSFileManager defaultManager] fileExistsAtPath:_directory isDirectory:&isdir]) && !isdir){
    if(error) *error = NSERROR_WITH_FILE(kFLFlynnErrorDomain, kFLStatusError, _directory, @"File at path exists but does not represent a directory");
    return FALSE;
  }else if(!exists && ![[NSFileManager defaultManager] createDirectoryAtPath:_directory withIntermediateDirectories:TRUE attributes:nil error:&inner]){
    if(error) *error = NSERROR_WITH_FILE(kFLFlynnErrorDomain, kFLStatusError, _directory, @"Could not create export directory");
    return FALSE;
  }
  
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
    if(error) *error = NSERROR(kFLFlynnErrorDomain, kFLStatusError, @"Frame image is null");
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
    if(error) *error = [NSError errorWithDomain:kFLFlynnErrorDomain code:kFLStatusError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"Frame image must use a pixel format with %ld bytes per pixel", self.bytesPerPixel], NSLocalizedDescriptionKey, nil]];
    goto error;
  }
  
  // make sure the image is has dimensions in multiples of blocks
  if((width % _blockLength) != 0 || (height % _blockLength) != 0){
    if(error) *error = [NSError errorWithDomain:kFLFlynnErrorDomain code:kFLStatusError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"Frame image must have dimensions in multiples of blocks: %ldx%ld is not a multiple of %ldx%ld", width, height, _blockLength, _blockLength], NSLocalizedDescriptionKey, nil]];
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
  for(FLRange *block in blocks){
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
      if(!FLImageCopyOutSequentialBlock(&buffer, _blockBuffer + _offset, bytesPerPixel, xblock, yblock, _blockLength)){
        if(error) *error = [NSError errorWithDomain:kFLFlynnErrorDomain code:kFLStatusError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"Could not copy block at position %ld (%ld, %ld)", position, xblock, yblock], NSLocalizedDescriptionKey, nil]];
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
  
  CGDataProviderRef dataProvider = NULL;
  CGImageRef image = NULL;
  
  // make sure we have some data
  if(_offset < 1) return TRUE;
  
  // determine the dimensions required for our image, in blocks
  size_t blocks = _offset / _blockLength / _blockLength / _bytesPerPixel;
  // determine the smallest square image we can use to represent those blocks, in blocks (this could be a better)
  size_t imageLength = ceil(sqrt((double)blocks));
  // determine our pixel dimensions
  size_t width = imageLength * _blockLength, height = imageLength * _blockLength;
  // determine the length of a single block, in bytes
  size_t bytesPerBlock = _bytesPerPixel * _blockLength * _blockLength;
  
  // make sure we don't exceed our dimension constraints
  if(width > self.imageLength || height > self.imageLength){
    if(error) *error = [NSError errorWithDomain:kFLFlynnErrorDomain code:kFLStatusError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Block buffer is too large", NSLocalizedDescriptionKey, nil]];
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
    if(!FLImageCopyInSequentialBlock(_blockBuffer + (i * bytesPerBlock), &buffer, _bytesPerPixel, xblock, yblock, _blockLength)){
      if(error) *error = [NSError errorWithDomain:kFLFlynnErrorDomain code:kFLStatusError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Could not copy image block", NSLocalizedDescriptionKey, nil]];
      goto error;
    }
  }
  
  // setup our output format UTI
  NSString *outputFormat;
  if((outputFormat = [self.codecSettings objectForKey:kFLCodecImageFormatKey]) == nil){
    if(error) *error = [NSError errorWithDomain:kFLFlynnErrorDomain code:kFLStatusError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Codec settings contain no output format", NSLocalizedDescriptionKey, nil]];
    goto error;
  }
  
  // setup our output path
  NSString *outputPath = [self.directory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_%03zd", self.namespace, _encodedImages + 1]];
  
  // setup our data provider
  if((dataProvider = CGDataProviderCreateWithData(NULL, buffer.data, buffer.rowBytes * height, NULL)) == NULL){
    if(error) *error = [NSError errorWithDomain:kFLFlynnErrorDomain code:kFLStatusError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Could not create image data provider", NSLocalizedDescriptionKey, nil]];
    goto error;
  }
  
  // create an image from our buffer
  if((image = CGImageCreate(width, height, 8, _bytesPerPixel * 8, buffer.rowBytes, FLImageGetDefaultColorSpace(), kCGImageAlphaLast, dataProvider, NULL, FALSE, kCGRenderingIntentDefault)) == NULL){
    if(error) *error = [NSError errorWithDomain:kFLFlynnErrorDomain code:kFLStatusError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Could not create image from block data", NSLocalizedDescriptionKey, nil]];
    goto error;
  }
  
  // write our image to disk
  status = FLImageWriteToPathWithExtensionAppended(image, NULL, outputFormat, outputPath, error);
  
error:
  if(image) CFRelease(image);
  _encodedImages++; // increment the count
  _offset = 0; // clear the offset
  
  return status;
}

@end

