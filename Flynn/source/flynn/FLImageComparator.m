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

#import "FLImageComparator.h"
#import "FLUtility.h"
#import "FLImage.h"
#import "FLCodec.h"
#import "FLError.h"

@implementation FLImageComparator

@synthesize codecSettings = _codecSettings;
@synthesize currentImage = _currentImage;
@synthesize blockLength = _blockLength;
@synthesize blockThreshold = _blockThreshold;
@synthesize bytesPerPixel = _bytesPerPixel;
@synthesize bitmapInfo = _bitmapInfo;

/**
 * Clean up
 */
-(void)dealloc {
  if(_currentImage) CFRelease(_currentImage);
  [_codecSettings release];
  [super dealloc];
}

/**
 * Initialize with a keyframe
 */
-(id)initWithKeyframeImage:(CGImageRef)keyframe codecSettings:(NSDictionary *)codecSettings error:(NSError **)error {
  if((self = [super init]) != nil){
    NSNumber *number;
    
    _codecSettings = [codecSettings retain];
    
    if((number = [codecSettings objectForKey:kFLCodecBlockSizeKey]) != nil){
      _blockLength = [number integerValue];
    }else{
      if(error) *error = NSERROR(kFLFlynnErrorDomain, kFLStatusError, @"Codec settings does not define a block size (%@)", kFLCodecBlockSizeKey);
      goto error;
    }
    
    if((number = [codecSettings objectForKey:kFLCodecBlockPixelDiscrepancyThresholdKey]) != nil){
      _blockThreshold = [number integerValue];
    }else{
      _blockThreshold = 0;
    }
    
    if(keyframe != NULL){
      _currentImage = CGImageRetain(keyframe);
      _bytesPerPixel = CGImageGetBitsPerPixel(keyframe) / CGImageGetBitsPerComponent(keyframe);
      _bitmapInfo = CGImageGetBitmapInfo(keyframe);
    }
    
  }
  return self;
error:
  [self release]; return nil;
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
      if(error) *error = [NSError errorWithDomain:kFLFlynnErrorDomain code:kFLStatusError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"Frame images in an animation must be exactly the same size (%zdx%zd)", CGImageGetWidth(_currentImage), CGImageGetHeight(_currentImage)], NSLocalizedDescriptionKey, nil]];
      return nil;
    }
    
    // make sure the image is has dimensions in multiples of blocks
    if((width % _blockLength) != 0 || (height % _blockLength) != 0){
      if(error) *error = [NSError errorWithDomain:kFLFlynnErrorDomain code:kFLStatusError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"Frame image must have dimensions in multiples of blocks: %ldx%ld is not a multiple of %ldx%ld", width, height, _blockLength, _blockLength], NSLocalizedDescriptionKey, nil]];
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
    ssize_t position = -1, count = 0;
    size_t x = 0, y = 0;
    
    for(y = 0; y < hblocks; y++){
      for(x = 0; x < wblocks; x++){
        if(!FLImageBlocksEqual(&currentBuffer, &updateBuffer, bytesPerPixel, _blockThreshold, x, y, _blockLength)){
          if(position < 0) position = (y * wblocks) + x;
          count++; // increment the run count
        }else if(position >= 0){
          [ranges addObject:[FLRange rangeWithPosition:position count:count]];
          position = -1; count = 0; // clear the run position and count
        }
      }
    }
    
    // handle the last row
    if(position >= 0){
      [ranges addObject:[FLRange rangeWithPosition:position count:count]];
    }
    
    [currData release];
    [nextData release];
    
    CGImageRelease(_currentImage);
    _currentImage = CGImageRetain(image);
    
  }
  return ranges;
}

@end

