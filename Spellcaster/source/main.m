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
#import "SCImageSequence.h"
#import "SCImageComparator.h"
#import "SCBlockEncoder.h"

int main(int argc, const char * argv[]) {
  @autoreleasepool {
    
    for(int i = 1; i < argc; i++){
      NSString *path = [[NSString alloc] initWithUTF8String:argv[i]];
      SCImageSequence *sequence = [[SCImageSequence alloc] initWithDirectoryPath:path prefix:@"frame-"];
      SCBlockEncoder *encoder = [[SCBlockEncoder alloc] initWithDirectoryPath:[path stringByAppendingPathComponent:@"spellcaster"] prefix:@"frame-"];
      SCManifest *manifest = [[SCManifest alloc] init];
      SCImageComparator *comparator = nil;
      NSError *error = nil;
      CGImageRef image;
      
      if(![sequence open:&error]){
        NSLog(@"* * * %@", [error localizedDescription]);
        goto error;
      }
      
      if(![encoder open:&error]){
        NSLog(@"* * * %@", [error localizedDescription]);
        goto error;
      }
      
      if((image = [sequence copyNextFrameImageWithError:&error]) != NULL){
        comparator = [[SCImageComparator alloc] initWithKeyframeImage:image block:8];
        CGImageRelease(image);
      }else{
        NSLog(@"* * * %@", [error localizedDescription]);
        goto error;
      }
      
      while((image = [sequence copyNextFrameImageWithError:&error]) != NULL){
        NSLog(@"OK: %@", [comparator updateBlocksForImage:image]);
        CGImageRelease(image);
      }if(error != nil){
        NSLog(@"* * * %@", [error localizedDescription]);
        goto error;
      }
      
      if(![encoder close:&error]){
        NSLog(@"* * * %@", [error localizedDescription]);
        goto error;
      }
      
      if(![sequence close:&error]){
        NSLog(@"* * * %@", [error localizedDescription]);
        goto error;
      }
      
      error:
      [manifest release];
      [encoder release];
      [comparator release];
      [sequence release];
      [path release];
    }
    
  }
  return 0;
}

