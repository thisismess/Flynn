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

typedef enum {
  kSCLogLevelInfo,
  kSCLogLevelVerbose
} SCLogLevel;

#define SCLog(a...)     __SCLog(kSCLogLevelInfo, ##a)
#define SCVerbose(a...) __SCLog(kSCLogLevelVerbose, ##a)

SCLogLevel __SCGetLogLevel(void);
void __SCSetLogLevel(SCLogLevel level);
void __SCLog(int level, NSString *format, ...);
