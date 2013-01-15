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

#import "SCOptions.h"

@implementation SCOptions

@synthesize prefix = _prefix;
@synthesize verbose = _verbose;
@synthesize blockLength = _blockLength;
@synthesize imageLength = _imageLength;

-(void)dealloc {
  [_prefix release];
  [super dealloc];
}

-(id)init {
  if((self = [super init]) != nil){
    _blockLength = 8;
    _imageLength = 1624;
  }
  return self;
}

-(void)info:(NSString *)format, ... {
  if(self.verbose){
    va_list ap;
    va_start(ap, format);
    fputs([[[NSProcessInfo processInfo] processName] UTF8String], stderr);
    fputs(": ", stderr);
    fputs([[[[NSString alloc] initWithFormat:format arguments:ap] autorelease] UTF8String], stderr);
    fputc('\n', stderr);
    va_end(ap);
  }
}

-(void)error:(NSString *)format, ... {
  va_list ap;
  va_start(ap, format);
  fputs([[[NSProcessInfo processInfo] processName] UTF8String], stderr);
  fputs(": ", stderr);
  fputs([[[[NSString alloc] initWithFormat:format arguments:ap] autorelease] UTF8String], stderr);
  fputc('\n', stderr);
  va_end(ap);
}

@end

@implementation SCMutableOptions

-(void)setPrefix:(NSString *)prefix {
  [_prefix release];
  _prefix = [prefix copy];
}

-(void)setVerbose:(BOOL)verbose {
  _verbose = verbose;
}

-(void)setBlockLength:(size_t)blockLength {
  _blockLength = blockLength;
}

-(void)setImageLength:(size_t)imageLength {
  _imageLength = imageLength;
}

@end

