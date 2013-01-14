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

#import "SCBlockEncoder.h"
#import "SCError.h"

@implementation SCBlockEncoder

@synthesize directory = _directory;
@synthesize prefix = _prefix;

/**
 * Clean up
 */
-(void)dealloc {
  [_directory release];
  [_prefix release];
  [super dealloc];
}

/**
 * Initialize with an output directory and file prefix
 */
-(id)initWithDirectoryPath:(NSString *)directory prefix:(NSString *)prefix {
  if((self = [super init]) != nil){
    _directory = [directory copy];
    _prefix = [prefix copy];
  }
  return self;
}

/**
 * Open a frame sequence for reading
 */
-(BOOL)open:(NSError **)error {
  BOOL exists, isdir = FALSE;
  NSError *inner = nil;
  
  if((exists = [[NSFileManager defaultManager] fileExistsAtPath:_directory isDirectory:&isdir]) && !isdir){
    if(error) *error = [NSError errorWithDomain:kSCSpellcasterErrorDomain code:kSCStatusError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"File at path exists but does not represent a directory: %@", _directory], NSLocalizedDescriptionKey, nil]];
    return FALSE;
  }else if(!exists && ![[NSFileManager defaultManager] createDirectoryAtPath:_directory withIntermediateDirectories:TRUE attributes:nil error:&inner]){
    if(error) *error = [NSError errorWithDomain:kSCSpellcasterErrorDomain code:kSCStatusError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"Could not create export directory: %@", [inner localizedDescription]], NSLocalizedDescriptionKey, nil]];
    return FALSE;
  }
  
  return TRUE;
}

/**
 * Open a previously opened frame sequence
 */
-(BOOL)close:(NSError **)error {
  // nothing special to do here...
  return TRUE;
}

/**
 * Encode block ranges for the provided image. If an error occurs, NULL is returned and
 * the error is described in the @p error parameter, if present.
 */
-(BOOL)encodeBlocks:(NSArray *)blocks forImage:(CGImageRef)image error:(NSError **)error {
  if(error) *error = [NSError errorWithDomain:kSCSpellcasterErrorDomain code:kSCStatusError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"Could not encode blocks"], NSLocalizedDescriptionKey, nil]];
  return FALSE;
}

@end

