// 
// @COPYRIGHT_NOTICE@
// 
// @MESS_LICENSE_START@
// 
// This software is provided to you by Kaart Marketing, LLC, d/b/a Mess
// Marketing ('Mess') in consideration of your acceptance of the terms
// under which it was developed for or licensed to you (the 'Agreement').
// You may not use this software except in compliance with the Agreement.
// 
// The Mess Software is provided by Mess on an "AS IS" basis.  MESS MAKES NO
// WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
// WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A
// PARTICULAR PURPOSE, REGARDING THE MESS SOFTWARE OR ITS USE AND OPERATION
// ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
// 
// IN NO EVENT SHALL MESS BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION
// AND/OR DISTRIBUTION OF THE MESS SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER
// THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR
// OTHERWISE, EVEN IF MESS HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
// 
// @MESS_LICENSE_END@
// 
// Designed and developed by Mess - http://thisismess.com/
// 

#import "SCManifest.h"
#import "JSONKit.h"

static const char * kSCManifestBase64Lookup = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

@implementation SCManifest

@synthesize version = _version;
@synthesize block = _block;
@synthesize images = _images;
@synthesize frames = _frames;

/**
 * Clean up
 */
-(void)dealloc {
  [_frames release];
  [super dealloc];
}

/**
 * Initialize an empty manifest
 */
-(id)init {
  if((self = [super init]) != nil){
    _frames = [[NSMutableArray alloc] init];
  }
  return self;
}

/**
 * Obtain mutable frames
 */
-(NSMutableArray *)mutableFrames {
  return (NSMutableArray *)_frames;
}

/**
 * Obtain the current frame
 */
-(NSMutableString *)currentFrame {
  return ([_frames count] > 0) ? [_frames lastObject] : nil;
}

/**
 * Start a new frame
 */
-(BOOL)startFrame {
  [self.mutableFrames addObject:[NSMutableString string]];
  return TRUE;
}

/**
 * Encode a command
 */
-(BOOL)encodeCopyBlocks:(SCRange *)range {
  return [self encodeCopyBlocksAtPosition:range.position count:range.count];
}

/**
 * Encode a command
 */
-(BOOL)encodeCopyBlocksAtPosition:(size_t)position count:(size_t)blocks {
  NSMutableString *frame;
  if((frame = self.currentFrame) != nil){
    if(![self encodeValue:position length:3 buffer:frame]) return FALSE;
    if(![self encodeValue:blocks length:2 buffer:frame]) return FALSE;
  }
  return TRUE;
}

/**
 * Encode a value and append it to the provided buffer
 */
-(BOOL)encodeValue:(size_t)value length:(size_t)length buffer:(NSMutableString *)buffer {
  if(value > powl(64, length) - 1) return FALSE;
  for(int i = 0; i < length; i++){
    UniChar z = kSCManifestBase64Lookup[(value >> ((length - i - 1) * 6)) & 0x3f];
    CFStringAppendCharacters((CFMutableStringRef)buffer, &z, 1);
  }
  return TRUE;
}

/**
 * Obtain this manifest encoded in its external representation
 */
-(NSString *)externalRepresentation {
  NSMutableDictionary *external = [NSMutableDictionary dictionary];
  [external setObject:[NSNumber numberWithInteger:self.version] forKey:@"version"];
  [external setObject:[NSNumber numberWithInteger:self.block] forKey:@"blockSize"];
  [external setObject:[NSNumber numberWithInteger:self.images] forKey:@"imagesRequired"];
  [external setObject:[NSNumber numberWithInteger:[self.frames count]] forKey:@"frameCount"];
  [external setObject:self.frames forKey:@"frames"];
  return [external JSONString];
}

@end

