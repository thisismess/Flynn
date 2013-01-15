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

#import <getopt.h>

#import "SCManifest.h"
#import "SCImageSequence.h"
#import "SCImageComparator.h"
#import "SCBlockEncoder.h"
#import "SCCodec.h"
#import "SCLog.h"

void SCProcessDirectory(NSString *inputDirectory, NSString *outputDirectory, NSDictionary *settings);

int main(int argc, const char * argv[]) {
  @autoreleasepool {
    NSMutableDictionary *options = [[NSMutableDictionary alloc] init];
    NSString *outputDirectory = nil;
    NSString *prefix = nil;
    NSString *name = nil;
    
    static struct option longopts[] = {
      { "name",             required_argument,  NULL,         'n' },  // name of the animation
      { "prefix",           required_argument,  NULL,         'p' },  // input frame prefix
      { "output",           required_argument,  NULL,         'o' },  // base path for output
      { "block-threshold",  required_argument,  NULL,         't' },  // block pixel discrepency threshold
      { "block-size",       required_argument,  NULL,         'b' },  // block size
      { "image-size",       required_argument,  NULL,         'I' },  // maximum image size
      { "verbose",          no_argument,        NULL,         'v' },  // be more verbose
      { NULL,               0,                  NULL,          0  }
    };
    
    int flag;
    while((flag = getopt_long(argc, (char **)argv, "n:p:o:b:I:t:v", longopts, NULL)) != -1){
      switch(flag){
        
        case 'n':
          name = [NSString stringWithUTF8String:optarg];
          break;
          
        case 'p':
          prefix = [NSString stringWithUTF8String:optarg];
          break;
          
        case 'o':
          outputDirectory = [NSString stringWithUTF8String:optarg];
          break;
          
        case 'b':
          [options setObject:[NSNumber numberWithInt:atoi(optarg)] forKey:kSCCodecBlockSizeKey];
          break;
          
        case 'I':
          [options setObject:[NSNumber numberWithInt:atoi(optarg)] forKey:kSCCodecImageSizeKey];
          break;
          
        case 't':
          [options setObject:[NSNumber numberWithInt:atoi(optarg)] forKey:kSCCodecBlockPixelDiscrepancyThresholdKey];
          break;
          
        case 'v':
          __SCSetLogLevel(kSCLogLevelVerbose);
          break;
          
        default:
          exit(0);
          
      }
    }
    
    /*
    if((options.imageLength % options.blockLength) != 0){
      SCLog(@"Encoded images must have dimensions that are a multiple of the block size (%ldx%ld)", options.blockLength, options.blockLength);
      exit(-1);
    }
    */
    
    argv += optind;
    argc -= optind;
    
    for(int i = 0; i < argc; i++){
      NSString *inputDirectory = [[NSString alloc] initWithUTF8String:argv[i]];
      SCProcessDirectory(inputDirectory, (outputDirectory != nil) ? outputDirectory : [outputDirectory stringByAppendingPathComponent:@"spellcaster"], options);
      [inputDirectory release];
    }
    
    [options release];
  }
  return 0;
}

/**
 * Process a directory
 */
void SCProcessDirectory(NSString *inputDirectory, NSString *outputDirectory, NSDictionary *settings) {
  size_t blockLength = 8;
  size_t imageLength = 1624;
  
  SCManifest *manifest = [[SCManifest alloc] init];
  SCImageSequence *sequence = [[SCImageSequence alloc] initWithDirectoryPath:inputDirectory prefix:@""];
  SCImageComparator *comparator = nil;
  SCBlockEncoder *encoder = nil;
  NSError *error = nil;
  CGImageRef image;
  
  if(![sequence open:&error]){
    SCLog(@"Could not open frame sequence: %@", [error localizedDescription]);
    goto error;
  }
  
  if((image = [sequence copyNextFrameImageWithError:&error]) != NULL){
    comparator = [[SCImageComparator alloc] initWithKeyframeImage:image blockLength:blockLength];
    encoder = [[SCBlockEncoder alloc] initWithDirectoryPath:outputDirectory prefix:@"spellcaster_" imageLength:imageLength blockLength:blockLength bytesPerPixel:CGImageGetBitsPerPixel(image) / CGImageGetBitsPerComponent(image)];
    CGImageRelease(image);
  }else{
    SCLog(@"Could not read keyframe image: %@", [error localizedDescription]);
    goto error;
  }
  
  if(![encoder open:&error]){
    SCLog(@"Could not open block encoder: %@", [error localizedDescription]);
    goto error;
  }
  
  size_t frames = 0;
  while((image = [sequence copyNextFrameImageWithError:&error]) != NULL){
    size_t diffblocks = 0;
    BOOL more = TRUE;
    
    NSArray *blocks;
    if((blocks = [comparator updateBlocksForImage:image error:&error]) == nil){
      SCLog(@"Could not determine update blocks from frame image: %@", [error localizedDescription]);
      more = FALSE; error = nil;
      goto done;
    }
    
    if(![encoder encodeBlocks:blocks forImage:image error:&error]){
      SCLog(@"Could not encode update blocks from frame image: %@", [error localizedDescription]);
      more = FALSE; error = nil;
      goto done;
    }
    
    if(![manifest startFrame]){
      SCLog(@"Could not start a manifest frame");
      more = FALSE; error = nil;
      goto done;
    }
    
    for(SCRange *range in blocks){
      diffblocks += range.count;
      if(![manifest encodeCopyBlocks:range]){
        SCLog(@"Could not encode copy-block command");
        more = FALSE; error = nil;
        goto done;
      }
    }
    
    SCVerbose(@"%04ld: updated %ld blocks in %ld ranges", frames++, diffblocks, [blocks count]);
    
    done:
    CGImageRelease(image);
    if(!more) break;
  }
  
  if(error != nil){
    SCLog(@"Could not process frame image: %@", [error localizedDescription]);
    goto error;
  }
  
  if(![[manifest externalRepresentation] writeToFile:[outputDirectory stringByAppendingPathComponent:@"spellcaster_manifest.json"]  atomically:TRUE encoding:NSUTF8StringEncoding error:&error]){
    SCLog(@"Could not write manifest file: %@", [error localizedDescription]);
    goto error;
  }
  
  if(![encoder close:&error]){
    SCLog(@"Could not close block encoder: %@", [error localizedDescription]);
    goto error;
  }
  
  if(![sequence close:&error]){
    SCLog(@"Could not close frame sequence: %@", [error localizedDescription]);
    goto error;
  }
  
error:
  [encoder release];
  [comparator release];
  [sequence release];
  [manifest release];
}

