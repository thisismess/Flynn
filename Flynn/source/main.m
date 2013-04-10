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

#import "FLManifest.h"
#import "FLImageFrameSequence.h"
#import "FLImageComparator.h"
#import "FLSequentialBlockEncoder.h"
#import "FLDebuggingBlockEncoder.h"
#import "FLUtility.h"
#import "FLCodec.h"
#import "FLError.h"
#import "FLLog.h"

enum {
  kSCOptionNone     = 0,
  kSCOptionVerbose  = 1 << 0,
  kSCOptionDebug    = 1 << 1
};

typedef uint32_t SCOptions;

void FLFlynnExportDirectory(NSString *inputDirectory, NSString *outputDirectory, NSString *namespace, NSDictionary *settings, SCOptions options);
void FLFlynnExportSequence(FLFrameSequence *inputSequence, NSString *outputDirectory, NSString *namespace, NSDictionary *settings, SCOptions options);
void FLFlynnUsage(FILE *stream);

/**
 * Main
 */
int main(int argc, const char * argv[]) {
  @autoreleasepool {
    NSMutableDictionary *settings = [[NSMutableDictionary alloc] init];
    NSString *namespace = @"flynn";
    NSString *outputDirectory = nil;
    SCOptions options = FALSE;
    NSError *error = nil;
    
    // the default codec version (2, the only version)
    [settings setObject:[NSNumber numberWithInt:2] forKey:kFLCodecVersionKey];
    // the default encoding block size (8x8, the same as JPEG macro blocks)
    [settings setObject:[NSNumber numberWithInt:8] forKey:kFLCodecBlockSizeKey];
    // the default stream image maximum dimension (1624, due to iOS image size constraints)
    [settings setObject:[NSNumber numberWithInt:1624] forKey:kFLCodecImageSizeKey];
    // the default stream image format (JPEG, much better compression)
    [settings setObject:(NSString *)kUTTypeJPEG forKey:kFLCodecImageFormatKey];
    
    static struct option longopts[] = {
      { "name",             required_argument,  NULL,         'n' },  // name of the animation
      { "output",           required_argument,  NULL,         'o' },  // base path for output
      { "block-threshold",  required_argument,  NULL,         't' },  // block pixel discrepency threshold
      { "block-size",       required_argument,  NULL,         'b' },  // block size
      { "image-size",       required_argument,  NULL,         'I' },  // maximum image size
      { "format",           required_argument,  NULL,         'f' },  // output image format
      { "debug",            no_argument,        NULL,         'D' },  // debug mode
      { "verbose",          no_argument,        NULL,         'v' },  // be more verbose
      { NULL,               0,                  NULL,          0  }
    };
    
    int flag;
    while((flag = getopt_long(argc, (char **)argv, "n:o:b:I:f:t:vD", longopts, NULL)) != -1){
      switch(flag){
        
        case 'n':
          namespace = [NSString stringWithUTF8String:optarg];
          break;
          
        case 'o':
          outputDirectory = [NSString stringWithUTF8String:optarg];
          break;
          
        case 'b':
          [settings setObject:[NSNumber numberWithInt:atoi(optarg)] forKey:kFLCodecBlockSizeKey];
          break;
          
        case 'I':
          [settings setObject:[NSNumber numberWithInt:atoi(optarg)] forKey:kFLCodecImageSizeKey];
          break;
          
        case 'f':
          [settings setObject:[NSString stringWithUTF8String:optarg] forKey:kFLCodecImageFormatKey];
          break;
          
        case 't':
          [settings setObject:[NSNumber numberWithInt:atoi(optarg)] forKey:kFLCodecBlockPixelDiscrepancyThresholdKey];
          break;
          
        case 'D':
          options |= kSCOptionDebug;
          break;
          
        case 'v':
          options |= kSCOptionVerbose; __FLSetLogLevel(kFLLogLevelVerbose);
          break;
          
        default:
          FLFlynnUsage(stderr);
          exit(0);
          
      }
    }
    
    if(!FLCodecSettingsValid(settings, &error)){
      FLLog(@"Codec settings are invalid");
      FLErrorDisplayBacktrace(error);
      exit(-1);
    }
    
    argv += optind;
    argc -= optind;
    
    if(argc < 1){
      FLFlynnUsage(stderr);
      exit(0);
    }
    
    for(int i = 0; i < argc; i++){
      NSString *inputDirectory = [[NSString alloc] initWithUTF8String:argv[i]];
      FLFlynnExportDirectory(inputDirectory, (outputDirectory != nil) ? outputDirectory : [inputDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_output", namespace]], namespace, settings, options);
      [inputDirectory release];
    }
    
    [settings release];
  }
  return 0;
}

/**
 * Export
 */
void FLFlynnExportDirectory(NSString *inputDirectory, NSString *outputDirectory, NSString *namespace, NSDictionary *settings, SCOptions options) {
  FLFrameSequence *inputSequence = nil;
  NSError *error = nil;
  
  if((options & kSCOptionDebug) == kSCOptionDebug){
    fprintf(stderr,
      "\n"
      "Exporting frame sequence:\n"
      "  %s\n"
      "   \u21b3 %s\n"
      "\n"
      "Settings:\n"
      "%s\n"
      "\n",
      [inputDirectory UTF8String],
      [outputDirectory UTF8String],
      [[settings description] UTF8String]
    );
  }
  
  if((inputSequence = [[FLImageFrameSequence alloc] initWithImagesInDirectory:inputDirectory error:&error]) == nil){
    FLLog(@"Could not create image sequence");
    FLErrorDisplayBacktrace(error);
    goto error;
  }
  
  if(![inputSequence open:&error]){
    FLLog(@"Could not open frame sequence");
    FLErrorDisplayBacktrace(error);
    goto error;
  }
  
  FLFlynnExportSequence(inputSequence, outputDirectory, namespace, settings, options);
  
  if(![inputSequence close:&error]){
    FLLog(@"Could not close frame sequence");
    FLErrorDisplayBacktrace(error);
    goto error;
  }
  
error:
  [inputSequence release];
  
}

/**
 * Export
 */
void FLFlynnExportSequence(FLFrameSequence *inputSequence, NSString *outputDirectory, NSString *namespace, NSDictionary *settings, SCOptions options) {
  
  FLImageComparator *comparator = nil;
  FLBlockEncoder *encoder = nil;
  FLManifest *manifest = nil;
  CGImageRef keyframe = NULL, image;
  NSError *error = nil;
  
  if((manifest = [[FLManifest alloc] initWithCodecSettings:settings error:&error]) == nil){
    FLLog(@"Could not create manifest");
    FLErrorDisplayBacktrace(error);
    goto error;
  }
  
  if((keyframe = [inputSequence copyNextFrameImageWithError:&error]) == NULL){
    FLLog(@"Could not read keyframe image");
    FLErrorDisplayBacktrace(error);
    goto error;
  }
  
  if((comparator = [[FLImageComparator alloc] initWithKeyframeImage:keyframe codecSettings:settings error:&error]) == nil){
    FLLog(@"Could not create image comparator");
    FLErrorDisplayBacktrace(error);
    goto error;
  }
  
  if((options & kSCOptionDebug) == kSCOptionDebug){
    if((encoder = [[FLDebuggingBlockEncoder alloc] initWithKeyframeImage:keyframe outputDirectory:outputDirectory namespace:namespace codecSettings:settings error:&error]) == nil){
      FLLog(@"Could not create debugging block encoder");
      FLErrorDisplayBacktrace(error);
      goto error;
    }
  }else{
    if((encoder = [[FLSequentialBlockEncoder alloc] initWithKeyframeImage:keyframe outputDirectory:outputDirectory namespace:namespace codecSettings:settings error:&error]) == nil){
      FLLog(@"Could not create sequential block encoder");
      FLErrorDisplayBacktrace(error);
      goto error;
    }
  }
  
  if(![encoder open:&error]){
    FLLog(@"Could not open block encoder");
    FLErrorDisplayBacktrace(error);
    goto error;
  }
  
  size_t frames = 0;
  while((image = [inputSequence copyNextFrameImageWithError:&error]) != NULL){
    size_t diffblocks = 0, totalblocks = (CGImageGetWidth(image) / encoder.blockLength) * (CGImageGetHeight(image) / encoder.blockLength);
    BOOL more = TRUE;
    
    NSArray *blocks;
    if((blocks = [comparator updateBlocksForImage:image error:&error]) == nil){
      FLLog(@"Could not determine update blocks from frame image");
      FLErrorDisplayBacktrace(error);
      more = FALSE; error = nil;
      goto done;
    }
    
    if(![encoder encodeBlocks:blocks forImage:image error:&error]){
      FLLog(@"Could not encode update blocks from frame image");
      FLErrorDisplayBacktrace(error);
      more = FALSE; error = nil;
      goto done;
    }
    
    if(![manifest startFrame]){
      FLLog(@"Could not start a manifest frame");
      more = FALSE; error = nil;
      goto done;
    }
    
    for(FLRange *range in blocks){
      diffblocks += range.count;
      if(![manifest encodeCopyBlocks:range]){
        FLLog(@"Could not encode copy-block command");
        more = FALSE; error = nil;
        goto done;
      }
    }
    
    FLVerbose(@"%04ld: updated %ld of %ld blocks in %ld ranges (%.1f%%)", frames++, diffblocks, totalblocks, [blocks count], ((double)diffblocks / (double)totalblocks) * 100.0);
    
    done:
    CGImageRelease(image);
    if(!more) break;
  }
  
  if(error != nil){
    FLLog(@"Could not process frame image");
    FLErrorDisplayBacktrace(error);
    goto error;
  }
  
  if(![encoder close:&error]){
    FLLog(@"Could not close block encoder");
    FLErrorDisplayBacktrace(error);
    goto error;
  }
  
  if(!FLImageWriteToPathWithExtensionAppended(keyframe, [settings objectForKey:kFLCodecImageFormatKey], [outputDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_keyframe", namespace]], &error)){
    FLLog(@"Could not write keyframe");
    FLErrorDisplayBacktrace(error);
    goto error;
  }
  
  if(![[manifest externalRepresentationWithImageCount:encoder.encodedImages] writeToFile:[outputDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_manifest.json", namespace]]  atomically:TRUE encoding:NSUTF8StringEncoding error:&error]){
    FLLog(@"Could not write manifest file");
    FLErrorDisplayBacktrace(error);
    goto error;
  }
  
error:
  if(keyframe) CFRelease(keyframe);
  [encoder release];
  [comparator release];
  [manifest release];
}

/**
 * Display usage information
 */
void FLFlynnUsage(FILE *stream) {
  fputs(
    "Flynn - A block differential animation encoder\n"
    "Copyright 2013 Mess  -  http://thisismess.com/\n"
    "\n"
    "Usage: flynn [options] <file1> [... <fileN>]\n"
    " Help: man flynn\n"
    "\n"
    "Options:\n"
    " -n --name <name>              Specify a namespace for the animation (default: 'flynn')\n"
    " -o --output <path>            Specify the directory under which the encoded animation is output\n"
    " -b --block-size <size>        Specify the encoding block size (default: 8)\n"
    " -t --block-threshold <count>  Specify a threshold for block discrepencies between frames (default: 0)\n"
    " -I --image-size <size>        Specify the encoded stream image size (default: 1624)\n"
    " -f --format <uti>             Specify the encoded stream image format as a UTI (default: 'public.png')\n"
    " -v --verbose                  Be more verbose\n"
    "\n"
  , stderr);
}

