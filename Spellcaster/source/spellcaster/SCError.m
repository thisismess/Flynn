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

#import "SCError.h"

/**
 * Display an error "backtrace"
 */
void SCErrorDisplayBacktrace(NSError *error) {
  
  // display the error message
  fputs([[NSString stringWithFormat:@"    because: %@\n", [error localizedDescription]] UTF8String], stderr);
  
  // if the error has a related file, display it
  NSString *path;
  if((path = [[error userInfo] objectForKey:NSFilePathErrorKey]) != nil){
    fputs([[NSString stringWithFormat:@"       file: %@\n", path] UTF8String], stderr);
  }
  
  // if the error has a cause, recurse
  NSError *cause;
  if((cause = [[error userInfo] objectForKey:NSUnderlyingErrorKey]) != nil){
    SCErrorDisplayBacktrace(cause);
  }
  
}

