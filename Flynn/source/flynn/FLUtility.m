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
 * Obtain an extension for an image format UTI
 */
NSString * FLImageGetExtensionForFormat(NSString *format) {
  NSString *extension = nil;
  if((extension = (NSString *)UTTypeCopyPreferredTagWithClass((CFStringRef)format, kUTTagClassFilenameExtension)) != nil){
    return [extension autorelease];
  }else{
    return nil;
  }
}

/**
 * Append the correct extension to the provided path based on its format and write the specified image
 * to that path. If the image does not already use the provided colorspace it is converted before writing.
 * Use NULL for the colorspace parameter to use the image's existing colorspace without conversion.
 */
BOOL FLImageWriteToPathWithExtensionAppended(CGImageRef image, CGColorSpaceRef colorspace, NSString *format, NSString *path, NSError **error) {
  NSString *extension = nil;
  BOOL status = FALSE;
  
  // obtain the extension for our output format
  if((extension = FLImageGetExtensionForFormat(format)) == nil){
    if(error) *error = [NSError errorWithDomain:kFLFlynnErrorDomain code:kFLStatusError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Could not obtain file extension for output format UTI", NSLocalizedDescriptionKey, nil]];
    goto error;
  }
  
  // append the extension and write our image
  status = FLImageWriteToPathUsingColorspace(image, colorspace, format, [[path stringByDeletingPathExtension] stringByAppendingPathExtension:extension], error);
  
error:
  return status;
}

/**
 * Write an image to disk
 */
BOOL FLImageWriteToPath(CGImageRef image, NSString *format, NSString *path, NSError **error) {
  return FLImageWriteToPathUsingColorspace(image, NULL, format, path, error);
}

/**
 * Write the image to the provided path using the provided colorspace. If the image does not
 * already use the provided colorspace it is converted before writing. Use NULL for the
 * colorspace parameter to use the image's existing colorspace without conversion.
 */
BOOL FLImageWriteToPathUsingColorspace(CGImageRef image, CGColorSpaceRef colorspace, NSString *format, NSString *path, NSError **error) {
  CGImageDestinationRef imageDestination = NULL;
  CGColorSpaceRef imageColorspace = NULL;
  CGImageRef outputImage = NULL;
  BOOL status = FALSE;
  
  // make sure our image is valid
  if(image == NULL){
    if(error) *error = [NSError errorWithDomain:kFLFlynnErrorDomain code:kFLStatusError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Cannot write null image to disk", NSLocalizedDescriptionKey, nil]];
    goto error;
  }
  
  // determine if we need to convert our colorspace
  if(colorspace != NULL && (imageColorspace = CGImageGetColorSpace(image)) != NULL && !CFEqual(colorspace, imageColorspace)){
    outputImage = CGImageCreateCopyWithColorSpace(image, colorspace);
  }else{
    outputImage = CGImageRetain(image); // retain so we can release our image at the end of this routine in either case
  }
  
  // make sure our output image is (still) valid
  if(outputImage == NULL){
    if(error) *error = [NSError errorWithDomain:kFLFlynnErrorDomain code:kFLStatusError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Could not convert image to destination colorspace", NSLocalizedDescriptionKey, nil]];
    goto error;
  }
  
  // create a destination for our image
  if((imageDestination = CGImageDestinationCreateWithURL((CFURLRef)[NSURL fileURLWithPath:path], (CFStringRef)format, 1, nil)) == NULL){
    if(error) *error = [NSError errorWithDomain:kFLFlynnErrorDomain code:kFLStatusError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Could not create image destination", NSLocalizedDescriptionKey, nil]];
    goto error;
  }
  
  // add our image to the destination
  CGImageDestinationAddImage(imageDestination, outputImage, NULL);
  
  // finalize our image destination
  if(!CGImageDestinationFinalize(imageDestination)){
    if(error) *error = [NSError errorWithDomain:kFLFlynnErrorDomain code:kFLStatusError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Could not finalize image destination", NSLocalizedDescriptionKey, nil]];
    goto error;
  }
  
  status = TRUE;
error:
  if(imageDestination) CFRelease(imageDestination);
  if(outputImage) CFRelease(outputImage);
  
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
 * Obtain the default colorspace
 */
CGColorSpaceRef FLImageGetDefaultColorSpace(void) {
  static CGColorSpaceRef __shared = NULL;
  if(__shared == NULL) __shared = CGColorSpaceCreateWithName(kFLColorSpaceDefault);
  return __shared;
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

