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

@interface TabController (Private)
- (UIViewController *)createViewController: (Class)class nibName: (NSString*)nibName tabIconName: (NSString *)iconName tabTitle: (NSString *)tabTitle;
- (void)initTabBarController;
@end

@implementation TabController

- (id)init
{
    if ((self = [super init]))
    {
        //_tabBarController = [[UITabBarController alloc] init];
        //_tabBarController.delegate = self;
        //self.view = _tabBarController.view;
        [self initTabBarController];
        //self.delegate = self;
    }
    return self;
}

- (void)dealloc 
{
    //_tabBarController.delegate = nil;
    //[_tabBarController release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning 
{
    [super didReceiveMemoryWarning];
}

- (void)viewDidLoad
{
    _moreNavigationController = self.navigationController;
    /*
    UITabBar *tab = _tabBarController.tabBar;
    
    MessageListController *theController = (MessageListController *)[tab.items objectAtIndex:0];
    theController.rootNavigationController = self.navigationController;
     */
}

- (void)viewDidUnload 
{
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController
{
    //_moreNavigationController = nil;
    if (viewController.tabBarItem.tag > 3)
        [self.navigationController pushViewController:viewController animated:YES];
    return YES;
}

@end

@implementation TabController (Private)

- (UIViewController *)createViewController: (Class)class nibName: (NSString*)nibName tabIconName: (NSString *)iconName tabTitle: (NSString *)tabTitle
{
    UIViewController *theController = [[[class alloc] initWithNibName:nibName bundle: nil] autorelease];
    theController.tabBarItem.image = [UIImage imageNamed:iconName];
    theController.title = NSLocalizedString(tabTitle, @"");
    return theController;
}

- (void)initTabBarController
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    UIViewController *theController = nil;
    NSMutableArray *controllers = [[NSMutableArray alloc] initWithCapacity:4];
    
    theController = [self createViewController: [HomeViewController class] 
                                       nibName: nil 
                                   tabIconName: @"HomeTabIcon.tiff" 
                                      tabTitle: @"Home"];
    theController.tabBarItem.tag = 0;
    [controllers addObject:theController];
    
	theController = [self createViewController: [RepliesListController class] 
                                       nibName: @"UserMessageList" 
                                   tabIconName: @"Replies.tiff" 
                                      tabTitle: @"Replies"];
    theController.tabBarItem.tag = 1;
    [controllers addObject:theController];
	
	theController = [self createViewController: [DirectMessagesController class] 
                                       nibName: @"UserMessageList" 
                                   tabIconName: @"Messages.tiff" 
                                      tabTitle: @"Messages"];
    theController.tabBarItem.tag = 2;
    [controllers addObject:theController];
	
	theController = [self createViewController: [TweetQueueController class] 
                                       nibName: @"TweetQueue" 
                                   tabIconName: @"Queue.tiff" 
                                      tabTitle: [TweetQueueController queueTitle]];
    theController.tabBarItem.tag = 3;
    [controllers addObject:theController];
    
	theController = [self createViewController: [MyTweetViewController class] 
                                       nibName: @"UserMessageList" 
                                   tabIconName: @"mytweets.tiff" 
                                      tabTitle: @"My Tweets"];
    theController.tabBarItem.tag = 4;
    [controllers addObject:theController];
    
	theController = [self createViewController: [FollowersController class] 
                                       nibName: @"UserMessageList" 
                                   tabIconName: @"followers.tiff" 
                                      tabTitle: @"Followers"];
    theController.tabBarItem.tag = 5;
    [controllers addObject:theController];
	
	theController = [self createViewController: [FollowingController class] 
                                       nibName: @"UserMessageList" 
                                   tabIconName: @"following.tiff" 
                                      tabTitle: @"Following"];
    theController.tabBarItem.tag = 6;
    [controllers addObject:theController];
	
	theController = [self createViewController: [SettingsController class]
                                       nibName: @"SettingsView"
                                   tabIconName: @"SettingsTabIcon.tiff"
                                      tabTitle: @"Settings"];
    theController.tabBarItem.tag = 7;
    [controllers addObject:theController];
	
	theController = [self createViewController: [AboutController class]
                                       nibName: @"About"
                                   tabIconName: @"About.tiff"
                                      tabTitle: @"About"];
    theController.tabBarItem.tag = 8;
    [controllers addObject:theController];
    
	// Set controllers array
	self.viewControllers = controllers;
    //_tabBarController.customizableViewControllers = nil;
    //_tabBarController.moreNavigationController.navigationBar.hidden = YES;
	[controllers release];
    
    [pool release];
}

@end
