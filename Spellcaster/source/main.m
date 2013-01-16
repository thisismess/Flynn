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
#import "SCSequentialBlockEncoder.h"
#import "SCDebugBlockEncoder.h"
#import "SCUtility.h"
#import "SCCodec.h"
#import "SCLog.h"

enum {
  kSCOptionNone     = 0,
  kSCOptionVerbose  = 1 << 0,
  kSCOptionDebug    = 1 << 1
};

typedef uint32_t SCOptions;

void SCSpellExport(NSString *inputDirectory, NSString *outputDirectory, NSDictionary *settings, SCOptions options);
void SCSpellUsage(FILE *stream);

/**
 * Main
 */
int main(int argc, const char * argv[]) {
  @autoreleasepool {
    NSMutableDictionary *settings = [[NSMutableDictionary alloc] init];
    SCOptions options = FALSE;
    NSString *outputDirectory = nil;
    NSString *prefix = nil;
    NSString *name = nil;
    NSError *error = nil;
    
    [settings setObject:[NSNumber numberWithInt:8] forKey:kSCCodecBlockSizeKey];
    [settings setObject:[NSNumber numberWithInt:1624] forKey:kSCCodecImageSizeKey];
    [settings setObject:(NSString *)kUTTypeJPEG forKey:kSCCodecImageFormatKey];
    
    static struct option longopts[] = {
      { "name",             required_argument,  NULL,         'n' },  // name of the animation
      { "prefix",           required_argument,  NULL,         'p' },  // input frame prefix
      { "output",           required_argument,  NULL,         'o' },  // base path for output
      { "block-threshold",  required_argument,  NULL,         't' },  // block pixel discrepency threshold
      { "block-size",       required_argument,  NULL,         'b' },  // block size
      { "image-size",       required_argument,  NULL,         'I' },  // maximum image size
      { "debug",            no_argument,        NULL,         'D' },  // debug mode
      { "verbose",          no_argument,        NULL,         'v' },  // be more verbose
      { NULL,               0,                  NULL,          0  }
    };
    
    int flag;
    while((flag = getopt_long(argc, (char **)argv, "n:p:o:b:I:t:vD", longopts, NULL)) != -1){
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
          [settings setObject:[NSNumber numberWithInt:atoi(optarg)] forKey:kSCCodecBlockSizeKey];
          break;
          
        case 'I':
          [settings setObject:[NSNumber numberWithInt:atoi(optarg)] forKey:kSCCodecImageSizeKey];
          break;
          
        case 't':
          [settings setObject:[NSNumber numberWithInt:atoi(optarg)] forKey:kSCCodecBlockPixelDiscrepancyThresholdKey];
          break;
          
        case 'D':
          options |= kSCOptionDebug;
          break;
          
        case 'v':
          options |= kSCOptionVerbose; __SCSetLogLevel(kSCLogLevelVerbose);
          break;
          
        default:
          SCSpellUsage(stderr);
          exit(0);
          
      }
    }
    
    if(!SCCodecSettingsIsValid(settings, &error)){
      SCLog(@"Invalid options: %@", [error localizedDescription]);
      exit(-1);
    }
    
    argv += optind;
    argc -= optind;
    
    if(argc < 1){
      SCSpellUsage(stderr);
      exit(0);
    }
    
    for(int i = 0; i < argc; i++){
      NSString *inputDirectory = [[NSString alloc] initWithUTF8String:argv[i]];
      SCSpellExport(inputDirectory, (outputDirectory != nil) ? outputDirectory : [outputDirectory stringByAppendingPathComponent:@"spellcaster"], settings, options);
      [inputDirectory release];
    }
    
    [settings release];
  }
  return 0;
}

/**
 * Export
 */
void SCSpellExport(NSString *inputDirectory, NSString *outputDirectory, NSDictionary *settings, SCOptions options) {
  size_t blockLength = 8;
  size_t imageLength = 1624;
  
  SCManifest *manifest = [[SCManifest alloc] init];
  SCImageSequence *sequence = [[SCImageSequence alloc] initWithDirectoryPath:inputDirectory prefix:@""];
  SCImageComparator *comparator = nil;
  SCBlockEncoder *encoder = nil;
  NSError *error = nil;
  CGImageRef keyframe = NULL, image;
  
  if(![sequence open:&error]){
    SCLog(@"Could not open frame sequence: %@", [error localizedDescription]);
    goto error;
  }
  
  if((keyframe = [sequence copyNextFrameImageWithError:&error]) == NULL){
    SCLog(@"Could not read keyframe image: %@", [error localizedDescription]);
    goto error;
  }
  
  comparator = [[SCImageComparator alloc] initWithKeyframeImage:keyframe blockLength:blockLength];
  
  if((options & kSCOptionDebug) == kSCOptionDebug){
    encoder = [[SCDebugBlockEncoder alloc] initWithDirectoryPath:outputDirectory prefix:@"spellcaster_" imageLength:imageLength blockLength:blockLength bytesPerPixel:CGImageGetBitsPerPixel(keyframe) / CGImageGetBitsPerComponent(keyframe)];
  }else{
    encoder = [[SCSequentialBlockEncoder alloc] initWithDirectoryPath:outputDirectory prefix:@"spellcaster_" imageLength:imageLength blockLength:blockLength bytesPerPixel:CGImageGetBitsPerPixel(keyframe) / CGImageGetBitsPerComponent(keyframe)];
  }
  
  if(![encoder open:&error]){
    SCLog(@"Could not open block encoder: %@", [error localizedDescription]);
    goto error;
  }
  
  size_t frames = 0;
  while((image = [sequence copyNextFrameImageWithError:&error]) != NULL){
    size_t diffblocks = 0, totalblocks = (CGImageGetWidth(image) / blockLength) * (CGImageGetHeight(image) / blockLength);
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
    
    SCVerbose(@"%04ld: updated %ld of %ld blocks in %ld ranges (%.1f%%)", frames++, diffblocks, totalblocks, [blocks count], ((double)diffblocks / (double)totalblocks) * 100.0);
    
    done:
    CGImageRelease(image);
    if(!more) break;
  }
  
  if(error != nil){
    SCLog(@"Could not process frame image: %@", [error localizedDescription]);
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
  
  if(!SCImageWritePNGToPath(keyframe, [outputDirectory stringByAppendingPathComponent:@"spellcaster_keyframe.png"], &error)){
    SCLog(@"Could not write keyframe: %@", [error localizedDescription]);
    goto error;
  }
  
  manifest.version = 2;
  manifest.blockLength = blockLength;
  manifest.encodedImages = encoder.encodedImages;
  
  if(![[manifest externalRepresentation] writeToFile:[outputDirectory stringByAppendingPathComponent:@"spellcaster_manifest.json"]  atomically:TRUE encoding:NSUTF8StringEncoding error:&error]){
    SCLog(@"Could not write manifest file: %@", [error localizedDescription]);
    goto error;
  }
  
error:
  if(keyframe) CFRelease(keyframe);
  [encoder release];
  [comparator release];
  [sequence release];
  [manifest release];
}

/**
 * Display usage information
 */
void SCSpellUsage(FILE *stream) {
  fputs(
    "Spellcaster - A block differential animation encoder\n"
    "Copyright 2013 Mess\n"
    "\n"
    "Usage: spellcaster [options] <file1> [... <fileN>]\n"
    "\n"
    "Options:\n"
    " -n --name <name>              Specify a namespace for the animation (default: 'spellcaster')\n"
    " -o --output <path>            Specify the directory under which the encoded animation is output\n"
    " -b --block-size <size>        Specify the encoding block size (default: 8)\n"
    " -t --block-threshold <count>  Specify a threshold for block discrepencies between frames (default: 0)\n"
    " -I --image-size <size>        Specify the encoded stream image size (default: 1624)\n"
    " -v --verbose                  Be more verbose\n"
    "\n"
  , stderr);
}

