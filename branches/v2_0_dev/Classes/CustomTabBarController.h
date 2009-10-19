//
//  CustomTabBarController.h
//  Tweetero
//
//  Created by Sergey Shkrabak on 9/17/09.
//  Copyright 2009 Codeminders. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SearchProvider.h"

@class MGTwitterEngine;

@interface CustomTabBarController : UIViewController <UITabBarDelegate, UITableViewDelegate, UITableViewDataSource, SearchProviderDelegate>
{
    UITabBar            *_tabBar;
    NSMutableDictionary *_viewControllers;
    NSMutableArray      *_moreItems;
    UIView              *_contentView;
    UITableView         *_moreTable;
    SearchProvider      *_searchProvider;
}

@property (nonatomic, retain) SearchProvider *searchProvider;

- (id)init;
- (void)dealloc;
- (NSString *)addViewController:(UIViewController *)controller;
- (UIViewController *)controllerForTabItem:(UITabBarItem *)item;

@end

@interface UIViewController (CustomTabBarController)

@property(nonatomic,retain) UITabBarItem *tabBarItem;

@end

