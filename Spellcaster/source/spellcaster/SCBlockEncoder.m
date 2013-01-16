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

#import "SCBlockEncoder.h"
#import "SCImage.h"
#import "SCError.h"
#import "SCLog.h"

@implementation SCBlockEncoder

@synthesize directory = _directory;
@synthesize prefix = _prefix;
@synthesize imageLength = _imageLength;
@synthesize blockLength = _blockLength;
@synthesize bytesPerPixel = _bytesPerPixel;
@synthesize encodedImages = _encodedImages;

/**
 * Clean up
 */
-(void)dealloc {
  [_directory release];
  [_prefix release];
  [super dealloc];
}

/**
 * Initialize with an output directory and file prefix
 */
-(id)initWithDirectoryPath:(NSString *)directory prefix:(NSString *)prefix imageLength:(NSUInteger)imageLength blockLength:(NSUInteger)blockLength bytesPerPixel:(NSUInteger)bytesPerPixel {
  if((self = [super init]) != nil){
    _directory = [directory copy];
    _prefix = [prefix copy];
    _blockLength = blockLength;
    _imageLength = imageLength;
    _bytesPerPixel = bytesPerPixel;
  }
  return self;
}

/**
 * Open a frame sequence for reading
 */
-(BOOL)open:(NSError **)error {
  if(error) *error = NSERROR(kSCSpellcasterErrorDomain, kSCStatusError, @"Subclasses must override %s", __PRETTY_FUNCTION__);
  return FALSE;
}

/**
 * Open a previously opened frame sequence
 */
-(BOOL)close:(NSError **)error {
  if(error) *error = NSERROR(kSCSpellcasterErrorDomain, kSCStatusError, @"Subclasses must override %s", __PRETTY_FUNCTION__);
  return FALSE;
}

/**
 * Encode block ranges for the provided image. If an error occurs, NULL is returned and
 * the error is described in the @p error parameter, if present.
 */
-(BOOL)encodeBlocks:(NSArray *)blocks forImage:(CGImageRef)image error:(NSError **)error {
  if(error) *error = NSERROR(kSCSpellcasterErrorDomain, kSCStatusError, @"Subclasses must override %s", __PRETTY_FUNCTION__);
  return FALSE;
}

@end

