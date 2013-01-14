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

#import <ImageIO/ImageIO.h>

#import "SCRange.h"

/**
 * A block encoder. Encoders accumulate update blocks until there are enough
 * to render an image at which time an image is composited, written to disk,
 * and the process starts over.
 * 
 * @author Brian William Wolter
 */
@interface SCBlockEncoder : NSObject {
  
  uint8_t * _blockBuffer;
  uint8_t * _imageBuffer;
  size_t    _length;
  size_t    _offset;
  size_t    _encodedImages;
  
}

-(id)initWithDirectoryPath:(NSString *)directory prefix:(NSString *)prefix blockLength:(NSUInteger)blockLength bytesPerPixel:(NSUInteger)bytesPerPixel;

-(BOOL)open:(NSError **)error;
-(BOOL)close:(NSError **)error;

-(BOOL)encodeBlocks:(NSArray *)blocks forImage:(CGImageRef)image error:(NSError **)error;

@property (readonly) NSString * directory;
@property (readonly) NSString * prefix;
@property (readonly) NSUInteger blockLength;
@property (readonly) NSUInteger bytesPerPixel;

@end

