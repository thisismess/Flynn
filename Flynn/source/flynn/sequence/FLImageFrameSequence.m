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

#import "FLImageFrameSequence.h"
#import "FLError.h"

@implementation FLImageFrameSequence

@synthesize imagePaths = _imagePaths;

/**
 * Obtain the set of supported images extensions
 */
+(NSSet *)supportedImageExtensions {
  static NSSet *__shared = nil;
  if(__shared == nil) __shared = [[NSSet alloc] initWithObjects:@"png", @"jpg", @"jpeg", nil];
  return __shared;
}

/**
 * Obtain image paths for the provided directory
 */
+(NSArray *)imagePathsForDirectoryPath:(NSString *)directory error:(NSError **)error {
  NSMutableArray *imagePaths = [NSMutableArray array];
  NSError *inner = nil;
  BOOL isdir = FALSE;
  
  if(![[NSFileManager defaultManager] fileExistsAtPath:directory isDirectory:&isdir] || !isdir){
    if(error) *error = NSERROR_WITH_FILE(kFLFlynnErrorDomain, kFLStatusError, directory, @"No such path or path does not represent a directory");
    return nil;
  }
  
  NSArray *contents;
  if((contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directory error:&inner]) == nil){
    if(error) *error = NSERROR_WITH_FILE(kFLFlynnErrorDomain, kFLStatusError, directory, @"Could not list directory directory");
    return nil;
  }
  
  for(NSString *filename in contents){
    NSString *extension;
    if((extension = [[filename pathExtension] lowercaseString]) != nil && [extension length] > 0){
      if([[[self class] supportedImageExtensions] containsObject:extension]){
        [imagePaths addObject:[directory stringByAppendingPathComponent:filename]];
      }
    }
  }
  
  return [imagePaths sortedArrayUsingComparator:^(id a, id b) { return [a compare:b]; }];
}

/**
 * Clean up
 */
-(void)dealloc {
  [_imagePaths release];
  [super dealloc];
}

/**
 * Initialize with a directory and frame image filename prefix
 */
-(id)initWithImagesInDirectory:(NSString *)directory error:(NSError **)error {
  NSArray *paths;
  if((paths = [[self class] imagePathsForDirectoryPath:directory error:error]) != nil){
    return [self initWithImagesAtPaths:paths error:error];
  }else{
    [self release]; return nil;
  }
}

/**
 * Initialize with a sequence of image paths
 */
-(id)initWithImagesAtPaths:(NSArray *)paths error:(NSError **)error {
  if((self = [super init]) != nil){
    if((_imagePaths = [paths retain]) == nil || [_imagePaths count] < 1){
      if(error) *error = NSERROR(kFLFlynnErrorDomain, kFLStatusError, @"No images in sequence");
      goto error;
    }
  }
  return self;
error:
  [self release]; return nil;
}

/**
 * Open a frame sequence for reading
 */
-(BOOL)open:(NSError **)error {
  _currentFrame = 0;
  return TRUE;
}

/**
 * Open a previously opened frame sequence
 */
-(BOOL)close:(NSError **)error {
  _currentFrame = 0;
  return TRUE;
}

/**
 * Copy the next frame in the sequence. If an error occurs, NULL is returned and
 * the error is described in the @p error parameter, if present.
 */
-(CGImageRef)copyNextFrameImageWithError:(NSError **)error {
  CGImageRef image = NULL;
  CGDataProviderRef dataProvider = NULL;
  NSString *path, *extension;
  
  if(_currentFrame >= [_imagePaths count]){
    if(error) *error = nil; // not a real error
    goto error;
  }
  
  if((path = [_imagePaths objectAtIndex:_currentFrame]) == nil || [path length] < 1){
    if(error) *error = NSERROR(kFLFlynnErrorDomain, kFLStatusError, @"Invalid path for frame at index %ld", _currentFrame);
    goto error;
  }
  
  if((extension = [path pathExtension]) == nil || [extension length] < 1){
    if(error) *error = NSERROR_WITH_FILE(kFLFlynnErrorDomain, kFLStatusError, path, @"Frame at path has no extension, cannot determine image type");
    goto error;
  }
  
  if((dataProvider = CGDataProviderCreateWithURL((CFURLRef)[NSURL fileURLWithPath:path])) == NULL){
    if(error) *error = NSERROR_WITH_FILE(kFLFlynnErrorDomain, kFLStatusError, path, @"Could not create data provider for frame");
    goto error;
  }
  
  if([extension caseInsensitiveCompare:@"png"] == NSOrderedSame){
    image = CGImageCreateWithPNGDataProvider(dataProvider, NULL, FALSE, kCGRenderingIntentDefault);
  }else if([extension caseInsensitiveCompare:@"jpg"] == NSOrderedSame || [extension caseInsensitiveCompare:@"jpeg"] == NSOrderedSame){
    image = CGImageCreateWithJPEGDataProvider(dataProvider, NULL, FALSE, kCGRenderingIntentDefault);
  }
  
  if(image == NULL){
    if(error) *error = NSERROR_WITH_FILE(kFLFlynnErrorDomain, kFLStatusError, path, @"Unsupported image type for frame");
    goto error;
  }
  
error:
  if(dataProvider) CFRelease(dataProvider);
  _currentFrame++;
  
  return image;
}

@end

