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

#import "SCManifest.h"
#import "JSONKit.h"

static const char * kSCManifestBase64Lookup = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

@implementation SCManifest

@synthesize version = _version;
@synthesize blockLength = _blockLength;
@synthesize encodedImages = _encodedImages;
@synthesize frames = _frames;

/**
 * Clean up
 */
-(void)dealloc {
  [_frames release];
  [super dealloc];
}

/**
 * Initialize an empty manifest
 */
-(id)init {
  if((self = [super init]) != nil){
    _frames = [[NSMutableArray alloc] init];
  }
  return self;
}

/**
 * Obtain mutable frames
 */
-(NSMutableArray *)mutableFrames {
  return (NSMutableArray *)_frames;
}

/**
 * Obtain the current frame
 */
-(NSMutableString *)currentFrame {
  return ([_frames count] > 0) ? [_frames lastObject] : nil;
}

/**
 * Start a new frame
 */
-(BOOL)startFrame {
  [self.mutableFrames addObject:[NSMutableString string]];
  return TRUE;
}

/**
 * Encode a command
 */
-(BOOL)encodeCopyBlocks:(SCRange *)range {
  return [self encodeCopyBlocksAtPosition:range.position count:range.count];
}

/**
 * Encode a command
 */
-(BOOL)encodeCopyBlocksAtPosition:(size_t)position count:(size_t)blocks {
  NSMutableString *frame;
  if((frame = self.currentFrame) != nil){
    if(![self encodeValue:position length:3 buffer:frame]) return FALSE;
    if(![self encodeValue:blocks length:2 buffer:frame]) return FALSE;
  }
  return TRUE;
}

/**
 * Encode a value and append it to the provided buffer
 */
-(BOOL)encodeValue:(size_t)value length:(size_t)length buffer:(NSMutableString *)buffer {
  if(value > powl(64, length) - 1) return FALSE;
  for(int i = 0; i < length; i++){
    UniChar z = kSCManifestBase64Lookup[(value >> ((length - i - 1) * 6)) & 0x3f];
    CFStringAppendCharacters((CFMutableStringRef)buffer, &z, 1);
  }
  return TRUE;
}

/**
 * Obtain this manifest encoded in its external representation
 */
-(NSString *)externalRepresentation {
  NSMutableDictionary *external = [NSMutableDictionary dictionary];
  [external setObject:[NSNumber numberWithInteger:2] forKey:@"version"];
  [external setObject:[NSNumber numberWithInteger:self.blockLength] forKey:@"blockSize"];
  [external setObject:[NSNumber numberWithInteger:self.encodedImages] forKey:@"imagesRequired"];
  [external setObject:[NSNumber numberWithInteger:[self.frames count]] forKey:@"frameCount"];
  [external setObject:self.frames forKey:@"frames"];
  return [external JSONString];
}

@end

