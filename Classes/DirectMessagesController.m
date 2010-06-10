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

#import "DirectMessagesController.h"
#import "MGTwitterEngine.h"
#import "TweetterAppDelegate.h"
#import "AccountManager.h"

NSComparisonResult sortByDate(id num1, id num2, void *context)
{
	NSDate *d1 = [num1 objectForKey:@"created_at"];
	NSDate *d2 = [num2 objectForKey:@"created_at"];
	return [d2 compare:d1];
}

@implementation DirectMessagesController

- (void)didReceiveMemoryWarning 
{
	[super didReceiveMemoryWarning];
    [self.tableView reloadData];
}

- (void)dealloc
{
    if (_connections) {
        [_connections release];
        _connections = nil;
    }
  	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [_topBarItem release];
    [super dealloc];
}

- (void)viewDidLoad 
{
    [super viewDidLoad];
    if (_topBarItem != nil)
        [_topBarItem release];
    _topBarItem =[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"refresh.tif"] style:UIBarButtonItemStyleBordered target:self action:@selector(reload)];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload) name:@"DirectMessageSent" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(twittsUpdatedNotificationHandler:) name:@"TwittsUpdated" object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.parentViewController.navigationItem.title = NSLocalizedString(@"Direct Messages", @"");    
    self.parentViewController.navigationItem.rightBarButtonItem = _topBarItem;
}

- (void)accountChanged:(NSNotification*)notification
{
	[self reloadAll];
}

- (NSString*)noMessagesString
{
	return NSLocalizedString(@"No Direct Messages", @"");
}

- (NSString*)loadingMessagesString
{
	return NSLocalizedString(@"Loading Direct Messages...", @"");
}

- (void)loadMessagesStaringAtPage:(int)numPage count:(int)count
{
	[super loadMessagesStaringAtPage:numPage count:count];

    if ([[AccountManager manager] isValidLoggedUser]) {
        if (!_connections) {
            _connections = [[NSMutableArray alloc] init];
        } else {
            [_connections removeAllObjects];
        }
		//[self retainActivityIndicator];
		[TweetterAppDelegate increaseNetworkActivityIndicator];
		[_connections addObject:[_twitter getDirectMessagesSince:nil startingAtPage:numPage]];
		[TweetterAppDelegate increaseNetworkActivityIndicator];
		[_connections addObject:[_twitter getSentDirectMessagesSince:nil startingAtPage:numPage]];
	}
}

- (void)reload
{
	[self reloadAll];
}

- (void)reloadAll
{
    [_allStatuses release];
    _allStatuses = nil;
    [super reloadAll];
}

- (void)twittsUpdatedNotificationHandler:(NSNotification*)note
{
    id object = [note object];
    
    if ([object respondsToSelector:@selector(dataSourceClass)]) {
        Class ds_class = [object dataSourceClass];
        if (ds_class == [self class])
            [self reload];
    }
}

- (void)removeRepeatedMessage:(NSMutableArray*)arr
{
    NSMutableArray *ids = [NSMutableArray array];
    NSMutableArray *invalid = [NSMutableArray array];
    for (int idx = 0; idx < arr.count; ++idx) {
        NSDictionary *obj = [arr objectAtIndex:idx];
        NSString *obj_id = [[obj objectForKey:@"id"] stringValue];
        if ([ids indexOfObject:obj_id] != NSNotFound) {
            [invalid addObject:[NSNumber numberWithInt:idx]];
        } else {
            [ids addObject:obj_id];
        }
    }
    NSEnumerator *it = [invalid reverseObjectEnumerator];
    NSNumber *index;
    while (index = [it nextObject]) {
        [arr removeObjectAtIndex:[index intValue]];
    }
}

- (void)updateParentData
{
    if (_connections.count == 0) {
        [_allStatuses sortUsingFunction:sortByDate context:nil];
        [self removeRepeatedMessage:_allStatuses];
        [super updateDirectMessages:_allStatuses];
    }
}

- (void)requestSucceeded:(NSString *)connectionIdentifier
{
    [super requestSucceeded:connectionIdentifier];
}

- (void)requestFailed:(NSString *)connectionIdentifier withError:(NSError *)error
{
    [super requestFailed:connectionIdentifier withError:error];
    if ([_connections indexOfObject:connectionIdentifier] != NSNotFound) {
        [_connections removeObject:connectionIdentifier];
        [self updateParentData];
    }
}

- (void)directMessagesReceived:(NSArray *)statuses forRequest:(NSString *)connectionIdentifier
{
	if(!_allStatuses) {
		if([statuses count] > 0)
			_allStatuses = [[NSMutableArray alloc] initWithArray:statuses];
	} else {
        [_allStatuses addObjectsFromArray:statuses];
	}
    if ([_connections indexOfObject:connectionIdentifier] != NSNotFound) {
        [_connections removeObject:connectionIdentifier];
        [self updateParentData];
    }
}

@end
