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

#import <getopt.h>

#import "SCManifest.h"
#import "SCImageSequence.h"
#import "SCImageComparator.h"
#import "SCBlockEncoder.h"
#import "SCOptions.h"

void SCProcessDirectory(NSString *path);

int main(int argc, const char * argv[]) {
  @autoreleasepool {
    SCMutableOptions *options = [[SCMutableOptions alloc] init];
    /*
    static struct option longopts[] = {
      { "output",       required_argument,  NULL,         'o' },  // base path for output
      { "block-size",   required_argument,  NULL,         'b' },  // block size
      { "image-size",   required_argument,  NULL,         'I' },  // maximum image size
      { "verbose",      no_argument,        NULL,         'v' },  // be more verbose
      { NULL,           0,                  NULL,          0  }
    };
    
    int flag;
    while((flag = getopt_long(argc, (char **)argv, "o:b:I:v", longopts, NULL)) != -1){
      switch(flag){
        
        case 'o':
          //options |= kWGOptionWrite;
          break;
          
        case 'b':
          options.blockLength = atoi(optarg);
          break;
          
        case 'I':
          options.imageLength = atoi(optarg);
          break;
          
        case 'v':
          options.verbose = TRUE;
          break;
          
        default:
          NSLog(@"* * * Invalid?");
          exit(0);
          
      }
    }
    */
    if((options.imageLength % options.blockLength) != 0){
      NSLog(@"* * * Encoded images must have dimensions that are a multiple of the block size");
      exit(-1);
    }
    
    //argv += optind;
    //argc -= optind;
    
    for(int i = 1; i < argc; i++){
      NSString *path = [[NSString alloc] initWithUTF8String:argv[i]];
      SCProcessDirectory(path);
      [path release];
    }
    
    [options release];
  }
  return 0;
}

/**
 * Process a directory
 */
void SCProcessDirectory(NSString *path) {
  size_t maxImageSize = 1624;
  size_t blockLength  = 8;
  
  SCManifest *manifest = [[SCManifest alloc] init];
  SCImageSequence *sequence = [[SCImageSequence alloc] initWithDirectoryPath:path prefix:@"_t-frame-"];
  SCImageComparator *comparator = nil;
  SCBlockEncoder *encoder = nil;
  NSError *error = nil;
  CGImageRef image;
  
  if(![sequence open:&error]){
    NSLog(@"* * * Could not open frame sequence: %@", [error localizedDescription]);
    goto error;
  }
  
  if((image = [sequence copyNextFrameImageWithError:&error]) != NULL){
    comparator = [[SCImageComparator alloc] initWithKeyframeImage:image blockLength:blockLength];
    encoder = [[SCBlockEncoder alloc] initWithDirectoryPath:[path stringByAppendingPathComponent:@"spellcaster"] prefix:@"frame-" imageLength:maxImageSize blockLength:blockLength bytesPerPixel:CGImageGetBitsPerPixel(image) / CGImageGetBitsPerComponent(image)];
    CGImageRelease(image);
  }else{
    NSLog(@"* * * Could not read keyframe image: %@", [error localizedDescription]);
    goto error;
  }
  
  if(![encoder open:&error]){
    NSLog(@"* * * Could not open block encoder: %@", [error localizedDescription]);
    goto error;
  }
  
  size_t frames = 0;
  while((image = [sequence copyNextFrameImageWithError:&error]) != NULL){
    size_t diffblocks = 0;
    BOOL more = TRUE;
    
    NSArray *blocks;
    if((blocks = [comparator updateBlocksForImage:image error:&error]) == nil){
      NSLog(@"* * * Could not determine update blocks from frame image: %@", [error localizedDescription]);
      more = FALSE; error = nil;
      goto done;
    }
    
    if(![encoder encodeBlocks:blocks forImage:image error:&error]){
      NSLog(@"* * * Could not encode update blocks from frame image: %@", [error localizedDescription]);
      more = FALSE; error = nil;
      goto done;
    }
    
    if(![manifest startFrame]){
      NSLog(@"* * * Could not start a manifest frame");
      more = FALSE; error = nil;
      goto done;
    }
    
    for(SCRange *range in blocks){
      diffblocks += range.count;
      if(![manifest encodeCopyBlocks:range]){
        NSLog(@"* * * Could not encode copy-block command");
        more = FALSE; error = nil;
        goto done;
      }
    }
    
    fprintf(stderr, "%04ld: %ld updated blocks in %ld ranges\n", frames++, diffblocks, [blocks count]);
    
    done:
    CGImageRelease(image);
    if(!more) break;
  }
  
  if(error != nil){
    NSLog(@"* * * Could not process frame image: %@", [error localizedDescription]);
    goto error;
  }
  
  if(![[manifest externalRepresentation] writeToFile:[path stringByAppendingPathComponent:@"spellcaster/manifest.json"]  atomically:TRUE encoding:NSUTF8StringEncoding error:&error]){
    NSLog(@"* * * Could not write manifest file: %@", [error localizedDescription]);
    goto error;
  }
  
  if(![encoder close:&error]){
    NSLog(@"* * * Could not close block encoder: %@", [error localizedDescription]);
    goto error;
  }
  
  if(![sequence close:&error]){
    NSLog(@"* * * Could not close frame sequence: %@", [error localizedDescription]);
    goto error;
  }
  
error:
  [encoder release];
  [comparator release];
  [sequence release];
  [manifest release];
}

