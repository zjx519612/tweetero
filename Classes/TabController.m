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

- (UINavigationController *)createNavControllerWrappingViewControllerOfClass: (Class)cntrloller 
                                                                     nibName: (NSString*)nibName 
                                                                 tabIconName: (NSString*)iconName
                                                                    tabTitle: (NSString*)tabTitle;
- (UIViewController *)createViewController: (Class)class 
                                   nibName: (NSString*)nibName
                               tabIconName: (NSString *)iconName 
                                tabTitle: (NSString *)tabTitle;
- (void)initTabBarController;
- (void)setupPortraitUserInterface;

@end

@implementation TabController (Private)

- (UINavigationController *)createNavControllerWrappingViewControllerOfClass:(Class)cntrloller 
                                                                     nibName:(NSString*)nibName 
                                                                 tabIconName:(NSString*)iconName
                                                                    tabTitle:(NSString*)tabTitle
{
	UIViewController* viewController = [[cntrloller alloc] initWithNibName:nibName bundle:nil];
	
	NavigationRotateController *theNavigationController;
	theNavigationController = [[NavigationRotateController alloc] initWithRootViewController:viewController];
	viewController.tabBarItem.image = [UIImage imageNamed:iconName];
	viewController.title = NSLocalizedString(tabTitle, @""); 
	[viewController release];
	
	return theNavigationController;
}

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
    ((HomeViewController*)theController).rootNavigationController = self.navigationController;
    [controllers addObject:theController];
    
	theController = [self createViewController: [RepliesListController class] 
                                       nibName: @"UserMessageList" 
                                   tabIconName: @"Replies.tiff" 
                                      tabTitle: @"Replies"];
    [controllers addObject:theController];
	
	theController = [self createViewController: [DirectMessagesController class] 
                                       nibName: @"UserMessageList" 
                                   tabIconName: @"Messages.tiff" 
                                      tabTitle: @"Messages"];
    [controllers addObject:theController];
	
	theController = [self createViewController: [TweetQueueController class] 
                                       nibName: @"TweetQueue" 
                                   tabIconName: @"Queue.tiff" 
                                      tabTitle: [TweetQueueController queueTitle]];
    [controllers addObject:theController];
    
	theController = [self createViewController: [MyTweetViewController class] 
                                       nibName: @"UserMessageList" 
                                   tabIconName: @"mytweets.tiff" 
                                      tabTitle: @"My Tweets"];
    [controllers addObject:theController];
    
	theController = [self createViewController: [FollowersController class] 
                                       nibName: @"UserMessageList" 
                                   tabIconName: @"followers.tiff" 
                                      tabTitle: @"Followers"];
    [controllers addObject:theController];
	
	theController = [self createViewController: [FollowingController class] 
                                       nibName: @"UserMessageList" 
                                   tabIconName: @"following.tiff" 
                                      tabTitle: @"Following"];
    [controllers addObject:theController];
	
	theController = [self createViewController: [SettingsController class]
                                       nibName: @"SettingsView"
                                   tabIconName: @"SettingsTabIcon.tiff"
                                      tabTitle: @"Settings"];
    [controllers addObject:theController];
	
	theController = [self createViewController: [AboutController class]
                                       nibName: @"About"
                                   tabIconName: @"About.tiff"
                                      tabTitle: @"About"];
    [controllers addObject:theController];
	// Set controllers array
	_tabBarController.viewControllers = controllers;
	[controllers release];
    
    [pool release];
}

- (void)setupPortraitUserInterface 
{
	UINavigationController *localNavigationController = nil;
	
	NSMutableArray *localViewControllersArray = [[NSMutableArray alloc] initWithCapacity:4];
    
	localNavigationController = [self createNavControllerWrappingViewControllerOfClass: [HomeViewController class] 
                                                                               nibName: nil
                                                                           tabIconName: @"HomeTabIcon.tiff"
                                                                              tabTitle: @"Home"];
	[localViewControllersArray addObject:localNavigationController];
	[localNavigationController release];
	//if([MGTwitterEngine username] == nil)
	//	[LoginController showModeless:localNavigationController animated:NO];
    
	localNavigationController = [self createNavControllerWrappingViewControllerOfClass: [RepliesListController class]
                                                                               nibName: @"UserMessageList"
                                                                           tabIconName: @"Replies.tiff" 
                                                                              tabTitle: @"Replies"];
	[localViewControllersArray addObject:localNavigationController];
	[localNavigationController release];
	
	localNavigationController = [self createNavControllerWrappingViewControllerOfClass: [DirectMessagesController class]
                                                                               nibName: @"UserMessageList" 
                                                                           tabIconName: @"Messages.tiff" 
                                                                              tabTitle: @"Messages"];
	[localViewControllersArray addObject:localNavigationController];
	[localNavigationController release];
	
	localNavigationController = [self createNavControllerWrappingViewControllerOfClass: [TweetQueueController class]
                                                                               nibName: @"TweetQueue" 
                                                                           tabIconName: @"Queue.tiff"
                                                                              tabTitle: [TweetQueueController queueTitle]];
	[localViewControllersArray addObject:localNavigationController];
	[localNavigationController release];
    
	localNavigationController = [self createNavControllerWrappingViewControllerOfClass: [MyTweetViewController class]
                                                                               nibName: @"UserMessageList" 
                                                                           tabIconName: @"mytweets.tiff"
                                                                              tabTitle: @"My Tweets"];
	[localViewControllersArray addObject:localNavigationController];
	[localNavigationController release];
    
	localNavigationController = [self createNavControllerWrappingViewControllerOfClass: [FollowersController class]
                                                                               nibName: @"UserMessageList"
                                                                           tabIconName: @"followers.tiff"
                                                                              tabTitle: @"Followers"];
	[localViewControllersArray addObject:localNavigationController];
	[localNavigationController release];
	
	localNavigationController = [self createNavControllerWrappingViewControllerOfClass: [FollowingController class]
                                                                               nibName: @"UserMessageList"
                                                                           tabIconName: @"following.tiff"
                                                                              tabTitle: @"Following"];
	[localViewControllersArray addObject:localNavigationController];
	[localNavigationController release];
	
	localNavigationController = [self createNavControllerWrappingViewControllerOfClass: [SettingsController class]
                                                                               nibName: @"SettingsView"
                                                                           tabIconName: @"SettingsTabIcon.tiff"
                                                                              tabTitle: @"Settings"];
	[localViewControllersArray addObject:localNavigationController];
	[localNavigationController release];
	
	localNavigationController = [self createNavControllerWrappingViewControllerOfClass: [AboutController class]
                                                                               nibName: @"About"
                                                                           tabIconName: @"About.tiff"
                                                                              tabTitle: @"About"];
	[localViewControllersArray addObject:localNavigationController];
	[localNavigationController release];
	
	_tabBarController.viewControllers = localViewControllersArray;
	[localViewControllersArray release];
}

@end

@implementation TabController

- (id)init
{
    if ((self = [super init]))
    {
        _tabBarController = [[UITabBarController alloc] init];
        self.view = _tabBarController.view;
        
        [self initTabBarController];
    }
    return self;
}

- (void)dealloc 
{
    [_tabBarController release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning 
{
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload 
{
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

@end
