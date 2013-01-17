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
#import "SCImageFrameSequence.h"
#import "SCImageComparator.h"
#import "SCSequentialBlockEncoder.h"
#import "SCDebuggingBlockEncoder.h"
#import "SCUtility.h"
#import "SCCodec.h"
#import "SCError.h"
#import "SCLog.h"

enum {
  kSCOptionNone     = 0,
  kSCOptionVerbose  = 1 << 0,
  kSCOptionDebug    = 1 << 1
};

typedef uint32_t SCOptions;

void SCSpellExport(NSString *inputDirectory, NSString *outputDirectory, NSString *namespace, NSDictionary *settings, SCOptions options);
void SCSpellUsage(FILE *stream);

/**
 * Main
 */
int main(int argc, const char * argv[]) {
  @autoreleasepool {
    NSMutableDictionary *settings = [[NSMutableDictionary alloc] init];
    NSString *namespace = @"spellcaster";
    NSString *outputDirectory = nil;
    SCOptions options = FALSE;
    NSError *error = nil;
    
    // the default codec version (2, the only version)
    [settings setObject:[NSNumber numberWithInt:2] forKey:kSCCodecVersionKey];
    // the default encoding block size (8x8, the same as JPEG macro blocks)
    [settings setObject:[NSNumber numberWithInt:8] forKey:kSCCodecBlockSizeKey];
    // the default stream image maximum dimension (1624, due to iOS image size constraints)
    [settings setObject:[NSNumber numberWithInt:1624] forKey:kSCCodecImageSizeKey];
    // the default stream image format (JPEG, much better compression)
    [settings setObject:(NSString *)kUTTypeJPEG forKey:kSCCodecImageFormatKey];
    
    static struct option longopts[] = {
      { "name",             required_argument,  NULL,         'n' },  // name of the animation
      { "output",           required_argument,  NULL,         'o' },  // base path for output
      { "block-threshold",  required_argument,  NULL,         't' },  // block pixel discrepency threshold
      { "block-size",       required_argument,  NULL,         'b' },  // block size
      { "image-size",       required_argument,  NULL,         'I' },  // maximum image size
      { "debug",            no_argument,        NULL,         'D' },  // debug mode
      { "verbose",          no_argument,        NULL,         'v' },  // be more verbose
      { NULL,               0,                  NULL,          0  }
    };
    
    int flag;
    while((flag = getopt_long(argc, (char **)argv, "n:o:b:I:t:vD", longopts, NULL)) != -1){
      switch(flag){
        
        case 'n':
          namespace = [NSString stringWithUTF8String:optarg];
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
    
    if(!SCCodecSettingsValid(settings, &error)){
      SCLog(@"Codec settings are invalid");
      SCErrorDisplayBacktrace(error);
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
      SCSpellExport(inputDirectory, (outputDirectory != nil) ? outputDirectory : [inputDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_output", namespace]], namespace, settings, options);
      [inputDirectory release];
    }
    
    [settings release];
  }
  return 0;
}

/**
 * Export
 */
void SCSpellExport(NSString *inputDirectory, NSString *outputDirectory, NSString *namespace, NSDictionary *settings, SCOptions options) {
  
  SCFrameSequence *sequence = nil;
  SCImageComparator *comparator = nil;
  SCBlockEncoder *encoder = nil;
  SCManifest *manifest = nil;
  CGImageRef keyframe = NULL, image;
  NSError *error = nil;
  
  if((sequence = [[SCImageFrameSequence alloc] initWithImagesInDirectory:inputDirectory error:&error]) == nil){
    SCLog(@"Could not create image sequence");
    SCErrorDisplayBacktrace(error);
    goto error;
  }
  
  if((manifest = [[SCManifest alloc] initWithCodecSettings:settings error:&error]) == nil){
    SCLog(@"Could not create manifest");
    SCErrorDisplayBacktrace(error);
    goto error;
  }
  
  if(![sequence open:&error]){
    SCLog(@"Could not open frame sequence");
    SCErrorDisplayBacktrace(error);
    goto error;
  }
  
  if((keyframe = [sequence copyNextFrameImageWithError:&error]) == NULL){
    SCLog(@"Could not read keyframe image");
    SCErrorDisplayBacktrace(error);
    goto error;
  }
  
  if((comparator = [[SCImageComparator alloc] initWithKeyframeImage:keyframe codecSettings:settings error:&error]) == nil){
    SCLog(@"Could not create image comparator");
    SCErrorDisplayBacktrace(error);
    goto error;
  }
  
  if((options & kSCOptionDebug) == kSCOptionDebug){
    if((encoder = [[SCDebuggingBlockEncoder alloc] initWithKeyframeImage:keyframe outputDirectory:outputDirectory namespace:namespace codecSettings:settings error:&error]) == nil){
      SCLog(@"Could not create debugging block encoder");
      SCErrorDisplayBacktrace(error);
      goto error;
    }
  }else{
    if((encoder = [[SCSequentialBlockEncoder alloc] initWithKeyframeImage:keyframe outputDirectory:outputDirectory namespace:namespace codecSettings:settings error:&error]) == nil){
      SCLog(@"Could not create sequential block encoder");
      SCErrorDisplayBacktrace(error);
      goto error;
    }
  }
  
  if(![encoder open:&error]){
    SCLog(@"Could not open block encoder");
    SCErrorDisplayBacktrace(error);
    goto error;
  }
  
  size_t frames = 0;
  while((image = [sequence copyNextFrameImageWithError:&error]) != NULL){
    size_t diffblocks = 0, totalblocks = (CGImageGetWidth(image) / encoder.blockLength) * (CGImageGetHeight(image) / encoder.blockLength);
    BOOL more = TRUE;
    
    NSArray *blocks;
    if((blocks = [comparator updateBlocksForImage:image error:&error]) == nil){
      SCLog(@"Could not determine update blocks from frame image");
      SCErrorDisplayBacktrace(error);
      more = FALSE; error = nil;
      goto done;
    }
    
    if(![encoder encodeBlocks:blocks forImage:image error:&error]){
      SCLog(@"Could not encode update blocks from frame image");
      SCErrorDisplayBacktrace(error);
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
    SCLog(@"Could not process frame image");
    SCErrorDisplayBacktrace(error);
    goto error;
  }
  
  if(![encoder close:&error]){
    SCLog(@"Could not close block encoder");
    SCErrorDisplayBacktrace(error);
    goto error;
  }
  
  if(![sequence close:&error]){
    SCLog(@"Could not close frame sequence");
    SCErrorDisplayBacktrace(error);
    goto error;
  }
  
  if(!SCImageWritePNGToPath(keyframe, [outputDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_keyframe.png", namespace]], &error)){
    SCLog(@"Could not write keyframe");
    SCErrorDisplayBacktrace(error);
    goto error;
  }
  
  if(![[manifest externalRepresentation] writeToFile:[outputDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_manifest.json", namespace]]  atomically:TRUE encoding:NSUTF8StringEncoding error:&error]){
    SCLog(@"Could not write manifest file");
    SCErrorDisplayBacktrace(error);
    goto error;
  }
  
error:
  if(keyframe) CFRelease(keyframe);
  [encoder release];
  [comparator release];
  [manifest release];
  [sequence release];
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

