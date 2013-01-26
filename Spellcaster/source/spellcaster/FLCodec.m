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

#import "FLCodec.h"
#import "FLError.h"

BOOL FLCodecSettingsValid(NSDictionary *settings, NSError **error) {
  NSNumber *number1, *number2;
  NSString *string1;
  
  if((number1 = [settings objectForKey:kFLCodecVersionKey]) == nil){
    if(error) *error = NSERROR(kFLFlynnErrorDomain, kFLStatusError, @"Settings must include a codec version (%@)", kFLCodecVersionKey);
    return FALSE;
  }
  
  if([number1 integerValue] != 2){
    if(error) *error = NSERROR(kFLFlynnErrorDomain, kFLStatusError, @"Settings codec version is not supported (%ld)", [number1 integerValue]);
    return FALSE;
  }
  
  if((number1 = [settings objectForKey:kFLCodecBlockSizeKey]) == nil){
    if(error) *error = NSERROR(kFLFlynnErrorDomain, kFLStatusError, @"Settings must include a block size (%@)", kFLCodecBlockSizeKey);
    return FALSE;
  }
  
  if([number1 integerValue] < 2){
    if(error) *error = NSERROR(kFLFlynnErrorDomain, kFLStatusError, @"Settings stream block size is invalid (%ldx%ld)", [number1 integerValue], [number1 integerValue]);
    return FALSE;
  }
  
  if((number2 = [settings objectForKey:kFLCodecImageSizeKey]) == nil){
    if(error) *error = NSERROR(kFLFlynnErrorDomain, kFLStatusError, @"Settings must include a stream image size (%@)", kFLCodecImageSizeKey);
    return FALSE;
  }
  
  if([number2 integerValue] < [number1 integerValue]){
    if(error) *error = NSERROR(kFLFlynnErrorDomain, kFLStatusError, @"Settings stream image size is smaller than a single block (%ldx%ld)", [number1 integerValue], [number1 integerValue]);
    return FALSE;
  }
  
  if(([number2 integerValue] % [number1 integerValue]) != 0){
    if(error) *error = NSERROR(kFLFlynnErrorDomain, kFLStatusError, @"Settings stream image size must be a multiple of blocks (%ldx%ld)", [number1 integerValue], [number1 integerValue]);
    return FALSE;
  }
  
  if((string1 = [settings objectForKey:kFLCodecImageFormatKey]) == nil){
    if(error) *error = NSERROR(kFLFlynnErrorDomain, kFLStatusError, @"Settings must include an image format (%@)", kFLCodecImageFormatKey);
    return FALSE;
  }
  
  if(![string1 isEqualToString:(NSString *)kUTTypePNG] && ![string1 isEqualToString:(NSString *)kUTTypeJPEG]){
    if(error) *error = NSERROR(kFLFlynnErrorDomain, kFLStatusError, @"Settings stream image format must be either PNG (%@) or JPEG (%@)", kUTTypePNG, kUTTypeJPEG);
    return FALSE;
  }
  
  return TRUE;
}


