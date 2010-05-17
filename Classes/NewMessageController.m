// Copyright (c) 2009 Imageshack Corp.
// All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
// 1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
// 3. The name of the author may not be used to endorse or promote products
//    derived from this software without specific prior written permission.
// 
// THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
// IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
// OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
// IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
// NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
// THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
// 

#import "NewMessageController.h"
#import "MGTwitterEngine.h"
#import "TweetterAppDelegate.h"
#import "TweetQueue.h"
#import "MGTwitterEngineFactory.h"

@implementation NewMessageController

- (id)init
{
    if ((self = [super initWithNibName:@"PostImage" bundle:nil]))
    {
        _user = nil;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _user = nil;
}

- (void)dealloc
{
    [_user release];
    [super dealloc];
}

- (void)setUser:(NSString*)user
{
	_user = [user retain];
}

- (NSString *)username
{
    return [[_user retain] autorelease];
}

- (NSString *)sendMessage:(NSString *)body
{
    int replyToId = 0;
	
	if(_message)
		replyToId = [[_message objectForKey:@"id"] intValue];
	
	NSString* connectionID = [_twitter sendDirectMessage:body to:_user];
	if(connectionID)
	{
		[cancelButton setEnabled:NO];
	}
    return connectionID;
}

- (BOOL)isDirectMessage
{
    return YES;
}

- (void)editUnsentMessage:(int)index
{	
    [super editUnsentMessage:index];
    
	NSString* text;
	NSData* imageData;
	NSURL* movieURL;
    NSString* username;
    
	if([[TweetQueue sharedQueue] getMessage:&text andImageData:&imageData movieURL:&movieURL inReplyTo:&_queuedReplyId forUser:&username atIndex:index])
        [self setUser:username];
}

@end
