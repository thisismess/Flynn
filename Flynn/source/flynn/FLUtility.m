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

#import "FLUtility.h"
#import "FLError.h"

/**
 * Append the correct extension to the provided path based on its format and write the specified image
 * to that path.
 */
BOOL FLImageWriteToPathWithExtensionAppended(CGImageRef image, NSString *format, NSString *path, NSError **error) {
  CFStringRef extension = NULL;
  BOOL status = FALSE;
  
  // obtain the extension for our output format
  if((extension = UTTypeCopyPreferredTagWithClass((CFStringRef)format, kUTTagClassFilenameExtension)) == NULL){
    if(error) *error = [NSError errorWithDomain:kFLFlynnErrorDomain code:kFLStatusError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Could not obtain file extension for output format UTI", NSLocalizedDescriptionKey, nil]];
    goto error;
  }
  
  // append the extension and write our image
  status = FLImageWriteToPath(image, format, [[path stringByDeletingPathExtension] stringByAppendingPathExtension:(NSString *)extension], error);
  
error:
  if(extension) CFRelease(extension);
  
  return status;
}

/**
 * Write an image to disk
 */
BOOL FLImageWriteToPath(CGImageRef image, NSString *format, NSString *path, NSError **error) {
  CGImageDestinationRef imageDestination = NULL;
  BOOL status = FALSE;
  
  // create a destination for our image
  if((imageDestination = CGImageDestinationCreateWithURL((CFURLRef)[NSURL fileURLWithPath:path], (CFStringRef)format, 1, nil)) == NULL){
    if(error) *error = [NSError errorWithDomain:kFLFlynnErrorDomain code:kFLStatusError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Could not create image destination", NSLocalizedDescriptionKey, nil]];
    goto error;
  }
  
  // add our image to the destination
  CGImageDestinationAddImage(imageDestination, image, NULL);
  
  // finalize our image destination
  if(!CGImageDestinationFinalize(imageDestination)){
    if(error) *error = [NSError errorWithDomain:kFLFlynnErrorDomain code:kFLStatusError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Could not finalize image destination", NSLocalizedDescriptionKey, nil]];
    goto error;
  }
  
  status = TRUE;
error:
  if(imageDestination) CFRelease(imageDestination);
  
  return status;
}

/**
 * Write a PNG image to disk
 */
BOOL FLImageWritePNGToPath(CGImageRef image, NSString *path, NSError **error) {
  return FLImageWriteToPath(image, (NSString *)kUTTypePNG, path, error);
}

/**
 * Write a JPEG image to disk
 */
BOOL FLImageWriteJPEGToPath(CGImageRef image, NSString *path, NSError **error) {
  return FLImageWriteToPath(image, (NSString *)kUTTypeJPEG, path, error);
}

/**
 * Display attributes for an image
 */
void FLImageShowAttributes(CGImageRef image) {
  if(image != nil){
    size_t bpp = CGImageGetBitsPerPixel(image) / 8;
    fprintf(stderr, "%p - ", image);
    
    fprintf(stderr, "%ld x %ld (", CGImageGetWidth(image), CGImageGetHeight(image));
    for(int i = 0; i < bpp; i++) fprintf(stderr, "%ld", CGImageGetBitsPerComponent(image));
    fprintf(stderr, ") ");
    
    switch(CGImageGetAlphaInfo(image)){
      case kCGImageAlphaNone:               fprintf(stderr, "no alpha component");        break;
      case kCGImageAlphaPremultipliedFirst: fprintf(stderr, "premultiplied alpha first"); break;
      case kCGImageAlphaPremultipliedLast:  fprintf(stderr, "premultiplied alpha last");  break;
      case kCGImageAlphaFirst:              fprintf(stderr, "alpha first");               break;
      case kCGImageAlphaLast:               fprintf(stderr, "alpha last");                break;
      case kCGImageAlphaNoneSkipFirst:      fprintf(stderr, "no alpha, skip first");      break;
      case kCGImageAlphaNoneSkipLast:       fprintf(stderr, "no alpha, skip last");       break;
      case kCGImageAlphaOnly:               fprintf(stderr, "alpha only");                break;
    }
    
    fputc('\n', stderr);
  }
}

