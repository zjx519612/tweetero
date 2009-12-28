//
//  MyTweetViewController.m
//  Tweetero
//
//  Created by Sergey Shkrabak on 9/10/09.
//  Copyright 2009 Codeminders. All rights reserved.
//

#import "MyTweetViewController.h"
#import "MGTwitterEngine.h"
#import "TweetterAppDelegate.h"

@implementation MyTweetViewController

- (void)viewDidLoad 
{
    [super viewDidLoad];
    
	self.navigationItem.title = @"MyTweets";
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(twittsUpdatedNotificationHandler:) name:@"TwittsUpdated" object:nil];
}

- (void)dealloc 
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void)loadMessagesStaringAtPage:(int)numPage count:(int)count
{
	[super loadMessagesStaringAtPage:numPage count:count];
    if ([[AccountManager manager] isValidLoggedUser])
	{
		[TweetterAppDelegate increaseNetworkActivityIndicator];
		[_twitter getUserTimelineFor:nil since:nil startingAtPage:numPage count:count];
	}
}

- (NSString*)noMessagesString
{
	return NSLocalizedString(@"No Tweets", @"");
}

- (NSString*)loadingMessagesString
{
	return NSLocalizedString(@"Loading Tweets...", @"");
}

- (void)reload
{
    [self reloadAll];
}

- (void)twittsUpdatedNotificationHandler:(NSNotification*)note
{
    id object = [note object];
    
    if ([object respondsToSelector:@selector(dataSourceClass)])
    {
        Class ds_class = [object dataSourceClass];
        if (ds_class == [self class])
            [self reload];
    }
}

@end
