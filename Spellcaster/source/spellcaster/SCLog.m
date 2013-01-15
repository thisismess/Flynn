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

#import "SCLog.h"

static SCLogLevel __SCLogLevel = kSCLogLevelInfo;

/**
 * Obtain the application wide log level
 */
SCLogLevel __SCGetLogLevel(void) {
  return __SCLogLevel;
}

/**
 * Obtain the application wide log level
 */
void __SCSetLogLevel(SCLogLevel level) {
  __SCLogLevel = level;
}

/**
 * Log a message
 */
void __SCLog(int level, NSString *format, ...) {
  if(level <= __SCLogLevel){
    va_list ap;
    va_start(ap, format);
    fputs([[[NSProcessInfo processInfo] processName] UTF8String], stderr);
    fputs(": ", stderr);
    fputs([[[[NSString alloc] initWithFormat:format arguments:ap] autorelease] UTF8String], stderr);
    fputc('\n', stderr);
    va_end(ap);
  }
}

