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

#import "SCUtility.h"
#import "SCError.h"

/**
 * Write an image to disk
 */
BOOL SCImageWriteToPath(CGImageRef image, NSString *format, NSString *path, NSError **error) {
  CGImageDestinationRef imageDestination = NULL;
  BOOL status = FALSE;
  
  // create a destination for our image
  if((imageDestination = CGImageDestinationCreateWithURL((CFURLRef)[NSURL fileURLWithPath:path], kUTTypePNG, 1, nil)) == NULL){
    if(error) *error = [NSError errorWithDomain:kSCSpellcasterErrorDomain code:kSCStatusError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Could not create image destination", NSLocalizedDescriptionKey, nil]];
    goto error;
  }
  
  // add our image to the destination
  CGImageDestinationAddImage(imageDestination, image, NULL);
  
  // finalize our image destination
  if(!CGImageDestinationFinalize(imageDestination)){
    if(error) *error = [NSError errorWithDomain:kSCSpellcasterErrorDomain code:kSCStatusError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Could not finalize image destination", NSLocalizedDescriptionKey, nil]];
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
BOOL SCImageWritePNGToPath(CGImageRef image, NSString *path, NSError **error) {
  return SCImageWriteToPath(image, (NSString *)kUTTypePNG, path, error);
}

/**
 * Write a JPEG image to disk
 */
BOOL SCImageWriteJPEGToPath(CGImageRef image, NSString *path, NSError **error) {
  return SCImageWriteToPath(image, (NSString *)kUTTypeJPEG, path, error);
}

