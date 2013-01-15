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

#import "SCImageSequence.h"
#import "SCError.h"

@implementation SCImageSequence

@synthesize imagePaths = _imagePaths;

/**
 * Obtain image paths for the provided directory and prefix
 */
+(NSArray *)imagePathsForDirectoryPath:(NSString *)directory prefix:(NSString *)prefix error:(NSError **)error {
  BOOL isdir = FALSE;
  
  if(![[NSFileManager defaultManager] fileExistsAtPath:directory isDirectory:&isdir] || !isdir){
    if(error) *error = [NSError errorWithDomain:kSCSpellcasterErrorDomain code:kSCStatusError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"No such path or path does not represent a directory: %@", directory], NSLocalizedDescriptionKey, nil]];
    return nil;
  }
  
  NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:directory];
  NSMutableArray *imagePaths = [NSMutableArray array];
  
  NSString *filename;
  while((filename = [enumerator nextObject]) != nil){
    NSString *extension = [filename pathExtension];
    if([extension caseInsensitiveCompare:@"png"] == NSOrderedSame || [extension caseInsensitiveCompare:@"jpg"] == NSOrderedSame || [extension caseInsensitiveCompare:@"jpeg"] == NSOrderedSame){
      if([filename length] > ([prefix length]  + 1 + [extension length] + 1)){
        if([filename compare:prefix options:NSCaseInsensitiveSearch range:NSMakeRange(0, [prefix length])] == NSOrderedSame){
          [imagePaths addObject:[directory stringByAppendingPathComponent:filename]];
        }
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
-(id)initWithDirectoryPath:(NSString *)directory prefix:(NSString *)prefix {
  NSArray *paths;
  if((paths = [[self class] imagePathsForDirectoryPath:directory prefix:prefix error:nil]) != nil){
    return [self initWithImagePaths:paths];
  }else{
    [self release]; return nil;
  }
}

/**
 * Initialize with a sequence of image paths
 */
-(id)initWithImagePaths:(NSArray *)paths {
  if((self = [super init]) != nil){
    _imagePaths = [paths retain];
  }
  return self;
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
  
  if(_currentFrame > ([_imagePaths count] - 1)){
    if(error) *error = nil; // not a real error
    goto error;
  }
  
  if((path = [_imagePaths objectAtIndex:_currentFrame]) == nil || [path length] < 1){
    if(error) *error = [NSError errorWithDomain:kSCSpellcasterErrorDomain code:kSCStatusNotImplemented userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"Invalid path for frame at index %ld", _currentFrame], NSLocalizedDescriptionKey, nil]];
    goto error;
  }
  
  if((extension = [path pathExtension]) == nil || [extension length] < 1){
    if(error) *error = [NSError errorWithDomain:kSCSpellcasterErrorDomain code:kSCStatusNotImplemented userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"Frame at path has no extension, cannot determine image type: %@", path], NSLocalizedDescriptionKey, nil]];
    goto error;
  }
  
  if((dataProvider = CGDataProviderCreateWithURL((CFURLRef)[NSURL fileURLWithPath:path])) == NULL){
    if(error) *error = [NSError errorWithDomain:kSCSpellcasterErrorDomain code:kSCStatusNotImplemented userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"Could not create data provider for frame at path: %@", path], NSLocalizedDescriptionKey, nil]];
    goto error;
  }
  
  if([extension caseInsensitiveCompare:@"png"] == NSOrderedSame){
    image = CGImageCreateWithPNGDataProvider(dataProvider, NULL, FALSE, kCGRenderingIntentDefault);
  }else if([extension caseInsensitiveCompare:@"jpg"] == NSOrderedSame || [extension caseInsensitiveCompare:@"jpeg"] == NSOrderedSame){
    image = CGImageCreateWithJPEGDataProvider(dataProvider, NULL, FALSE, kCGRenderingIntentDefault);
  }
  
  if(image == NULL){
    if(error) *error = [NSError errorWithDomain:kSCSpellcasterErrorDomain code:kSCStatusNotImplemented userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"Unsupported image type for frame at path: %@", path], NSLocalizedDescriptionKey, nil]];
    goto error;
  }
  
error:
  if(dataProvider) CFRelease(dataProvider);
  _currentFrame++;
  
  return image;
}

@end

