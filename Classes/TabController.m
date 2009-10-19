//
//  TabController.m
//  Tweetero
//
//  Created by Sergey Shkrabak on 9/15/09.
//  Copyright 2009 Codeminders. All rights reserved.
//

#import "TweetterAppDelegate.h"
#import "MGTwitterEngine.h"
// Controllers
#import "TabController.h"
#import "TwitEditorController.h"
#import "HomeViewController.h"
#import "SelectImageSource.h"
#import "SettingsController.h"
#import "LocationManager.h"
#import "RepliesListController.h"
#import "DirectMessagesController.h"
#import "NavigationRotateController.h"
#import "TweetQueueController.h"
#import "AboutController.h"
#import "LoginController.h"
#import "FollowersController.h"
#import "MyTweetViewController.h"
#import "SearchController.h"

@implementation TabController

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self updateTabItemTitle];
    /*
    UIBarButtonItem *newMsgButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemCompose
                                                                                  target: self
                                                                                  action: @selector(clickNewMessage)];
    self.navigationItem.rightBarButtonItem = newMsgButton;
    [newMsgButton release];
     */
}

#pragma mark Actions
- (IBAction)clickNewMessage
{
	TwitEditorController *editController = [[TwitEditorController alloc] init];
	[self.navigationController pushViewController:editController animated:YES];
	[editController release];
}

- (void)updateTabItemTitle
{
    for (UITabBarItem *item in [_tabBar items])
    {
        id controller = [self controllerForTabItem:item];
        
        if ([controller respondsToSelector:@selector(getTitle)])
            item.title = [controller performSelector:@selector(getTitle)];
    }
}

#pragma mark Parent Methods
- (UIViewController *)createViewController: (Class)class nibName: (NSString*)nibName tabIconName: (NSString *)iconName tabTitle: (NSString *)tabTitle
{
    UIViewController *theController = [[[class alloc] initWithNibName:nibName bundle: nil] autorelease];
    theController.tabBarItem.image = [UIImage imageNamed:iconName];
    theController.title = NSLocalizedString(tabTitle, @"");
    return theController;
}

- (NSMutableArray *)createTabBarItems
{
    UIViewController *theController = nil;
    NSMutableArray *controllers = [[NSMutableArray alloc] initWithCapacity:4];
    int tag;
    
    theController = [self createViewController: [HomeViewController class] 
                                       nibName: nil 
                                   tabIconName: @"HomeTabIcon.tiff" 
                                      tabTitle: @"Home"];
    theController.tabBarItem.tag = tag++;
    [self addViewController:theController];
    [controllers addObject:theController.tabBarItem];
    
	theController = [self createViewController: [RepliesListController class] 
                                       nibName: @"UserMessageList" 
                                   tabIconName: @"Replies.tiff" 
                                      tabTitle: @"Replies"];
    theController.tabBarItem.tag = tag++;
    [self addViewController:theController];
    [controllers addObject:theController.tabBarItem];
    
	theController = [self createViewController: [DirectMessagesController class] 
                                       nibName: @"UserMessageList" 
                                   tabIconName: @"Messages.tiff" 
                                      tabTitle: @"Messages"];
    theController.tabBarItem.tag = tag++;
    [self addViewController:theController];
    [controllers addObject:theController.tabBarItem];
    
	theController = [self createViewController: [TweetQueueController class] 
                                       nibName: @"TweetQueue" 
                                   tabIconName: @"Queue.tiff" 
                                      tabTitle: [TweetQueueController queueTitle]];
    theController.tabBarItem.tag = tag++;
    [self addViewController:theController];
    [controllers addObject:theController.tabBarItem];
    
	theController = [self createViewController: [MyTweetViewController class] 
                                       nibName: @"UserMessageList" 
                                   tabIconName: @"mytweets.png" 
                                      tabTitle: @"My Tweets"];
    theController.tabBarItem.tag = tag++;
    [self addViewController:theController];
    [controllers addObject:theController.tabBarItem];
    
	theController = [self createViewController: [FollowersController class] 
                                       nibName: @"UserMessageList" 
                                   tabIconName: @"followers.png" 
                                      tabTitle: @"Followers"];
    theController.tabBarItem.tag = tag++;
    [self addViewController:theController];
    [controllers addObject:theController.tabBarItem];
    
	theController = [self createViewController: [FollowingController class] 
                                       nibName: @"UserMessageList" 
                                   tabIconName: @"following.png" 
                                      tabTitle: @"Following"];
    theController.tabBarItem.tag = tag++;
    [self addViewController:theController];
    [controllers addObject:theController.tabBarItem];
    
    theController = [self createViewController: [SearchController class]
                                       nibName: @"SearchController"
                                   tabIconName: @"search.png" 
                                      tabTitle: @"Search"];
    theController.tabBarItem.tag = tag++;
    [self addViewController:theController];
    [controllers addObject:theController.tabBarItem];
    
	theController = [self createViewController: [SettingsController class]
                                       nibName: @"SettingsView"
                                   tabIconName: @"settings.png"
                                      tabTitle: @"Settings"];
    theController.tabBarItem.tag = tag++;
    [self addViewController:theController];
    [controllers addObject:theController.tabBarItem];
    
	theController = [self createViewController: [AboutController class]
                                       nibName: @"About"
                                   tabIconName: @"about.png"
                                      tabTitle: @"About"];
    theController.tabBarItem.tag = tag++;
    [self addViewController:theController];
    [controllers addObject:theController.tabBarItem];
    
	return [controllers autorelease];
}

@end