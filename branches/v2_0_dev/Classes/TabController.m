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

@implementation TabController

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
    
    theController = [self createViewController: [HomeViewController class] 
                                       nibName: nil 
                                   tabIconName: @"HomeTabIcon.tiff" 
                                      tabTitle: @"Home"];
    theController.tabBarItem.tag = 0;
    [self addViewController:theController];
    [controllers addObject:theController.tabBarItem];
    
	theController = [self createViewController: [RepliesListController class] 
                                       nibName: @"UserMessageList" 
                                   tabIconName: @"Replies.tiff" 
                                      tabTitle: @"Replies"];
    theController.tabBarItem.tag = 1;
    [self addViewController:theController];
    [controllers addObject:theController.tabBarItem];
    
	theController = [self createViewController: [DirectMessagesController class] 
                                       nibName: @"UserMessageList" 
                                   tabIconName: @"Messages.tiff" 
                                      tabTitle: @"Messages"];
    theController.tabBarItem.tag = 2;
    [self addViewController:theController];
    [controllers addObject:theController.tabBarItem];
    
	theController = [self createViewController: [TweetQueueController class] 
                                       nibName: @"TweetQueue" 
                                   tabIconName: @"Queue.tiff" 
                                      tabTitle: [TweetQueueController queueTitle]];
    theController.tabBarItem.tag = 3;
    [self addViewController:theController];
    [controllers addObject:theController.tabBarItem];
    
	theController = [self createViewController: [MyTweetViewController class] 
                                       nibName: @"UserMessageList" 
                                   tabIconName: @"mytweets.tiff" 
                                      tabTitle: @"My Tweets"];
    theController.tabBarItem.tag = 4;
    [self addViewController:theController];
    [controllers addObject:theController.tabBarItem];
    
	theController = [self createViewController: [FollowersController class] 
                                       nibName: @"UserMessageList" 
                                   tabIconName: @"followers.tiff" 
                                      tabTitle: @"Followers"];
    theController.tabBarItem.tag = 5;
    [self addViewController:theController];
    [controllers addObject:theController.tabBarItem];
    
	theController = [self createViewController: [FollowingController class] 
                                       nibName: @"UserMessageList" 
                                   tabIconName: @"following.tiff" 
                                      tabTitle: @"Following"];
    theController.tabBarItem.tag = 6;
    [self addViewController:theController];
    [controllers addObject:theController.tabBarItem];
    
	theController = [self createViewController: [SettingsController class]
                                       nibName: @"SettingsView"
                                   tabIconName: @"SettingsTabIcon.tiff"
                                      tabTitle: @"Settings"];
    theController.tabBarItem.tag = 7;
    [self addViewController:theController];
    [controllers addObject:theController.tabBarItem];
    
	theController = [self createViewController: [AboutController class]
                                       nibName: @"About"
                                   tabIconName: @"About.tiff"
                                      tabTitle: @"About"];
    theController.tabBarItem.tag = 8;
    [self addViewController:theController];
    [controllers addObject:theController.tabBarItem];
    
	return [controllers autorelease];
}

@end