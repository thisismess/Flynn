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

