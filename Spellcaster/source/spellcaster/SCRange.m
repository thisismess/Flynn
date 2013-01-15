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

#import "SCRange.h"

@implementation SCRange

@synthesize position = _position;
@synthesize count = _count;

/**
 * Create with a position and offset
 */
+(SCRange *)rangeWithPosition:(size_t)position count:(size_t)count {
  return [[[SCRange alloc] initWithPosition:position count:count] autorelease];
}

/**
 * Initialize with a position and offset
 */
-(id)initWithPosition:(size_t)position count:(size_t)count {
  if((self = [super init]) != nil){
    _position = position;
    _count = count;
  }
  return self;
}

/**
 * String description
 */
-(NSString *)description {
  return [NSString stringWithFormat:@"<%ld +%ld>", _position, _count];
}

@end

