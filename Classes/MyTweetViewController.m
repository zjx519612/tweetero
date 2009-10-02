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
}

- (void)loadMessagesStaringAtPage:(int)numPage count:(int)count
{
	[super loadMessagesStaringAtPage:numPage count:count];
	if ([MGTwitterEngine password] != nil)
	{
		[TweetterAppDelegate increaseNetworkActivityIndicator];
		[_twitter getUserTimelineFor:nil since:nil startingAtPage:numPage count:count];
		self.navigationItem.title = [MGTwitterEngine username];
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

@end
