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

#import "SCFrameSequence.h"
#import "SCError.h"

@implementation SCFrameSequence

/**
 * Open a frame sequence for reading
 */
-(BOOL)open:(NSError **)error {
  if(error) *error = [NSError errorWithDomain:kSCSpellcasterErrorDomain code:kSCStatusNotImplemented userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"Subclasses must override %s", __PRETTY_FUNCTION__], NSLocalizedDescriptionKey, nil]];
  return FALSE;
}

/**
 * Open a previously opened frame sequence
 */
-(BOOL)close:(NSError **)error {
  if(error) *error = [NSError errorWithDomain:kSCSpellcasterErrorDomain code:kSCStatusNotImplemented userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"Subclasses must override %s", __PRETTY_FUNCTION__], NSLocalizedDescriptionKey, nil]];
  return FALSE;
}

/**
 * Copy the next frame in the sequence. If an error occurs, NULL is returned and
 * the error is described in the @p error parameter, if present.
 */
-(CGImageRef)copyNextFrameImageWithError:(NSError **)error {
  if(error) *error = [NSError errorWithDomain:kSCSpellcasterErrorDomain code:kSCStatusNotImplemented userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"Subclasses must override %s", __PRETTY_FUNCTION__], NSLocalizedDescriptionKey, nil]];
  return nil;
}

@end

