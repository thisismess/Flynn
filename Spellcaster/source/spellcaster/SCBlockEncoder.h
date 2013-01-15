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

#import <ImageIO/ImageIO.h>

#import "SCRange.h"

/**
 * A block encoder. Encoders accumulate update blocks until there are enough
 * to render an image at which time an image is composited, written to disk,
 * and the process starts over.
 * 
 * @author Brian William Wolter
 */
@interface SCBlockEncoder : NSObject {
  
  uint8_t * _blockBuffer;
  uint8_t * _imageBuffer;
  size_t    _length;
  size_t    _offset;
  
}

-(id)initWithDirectoryPath:(NSString *)directory prefix:(NSString *)prefix imageLength:(NSUInteger)imageLength blockLength:(NSUInteger)blockLength bytesPerPixel:(NSUInteger)bytesPerPixel;

-(BOOL)open:(NSError **)error;
-(BOOL)close:(NSError **)error;

-(BOOL)encodeBlocks:(NSArray *)blocks forImage:(CGImageRef)image error:(NSError **)error;

@property (readonly) NSString * directory;
@property (readonly) NSString * prefix;
@property (readonly) NSUInteger imageLength;
@property (readonly) NSUInteger blockLength;
@property (readonly) NSUInteger bytesPerPixel;
@property (readonly) NSUInteger encodedImages;

@end

