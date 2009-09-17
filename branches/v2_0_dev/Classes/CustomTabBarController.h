//
//  CustomTabBarController.h
//  Tweetero
//
//  Created by Sergey Shkrabak on 9/17/09.
//  Copyright 2009 Codeminders. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CustomTabBarController : UIViewController <UITabBarDelegate, UITableViewDelegate, UITableViewDataSource>
{
    UITabBar *_tabBar;
    NSMutableDictionary *_viewControllers;
    NSMutableArray *_moreItems;
    UIView *_contentView;
    UITableView *_moreTable;
}

- (id)init;
- (void)dealloc;
- (NSString *)addViewController:(UIViewController *)controller;
- (UIViewController *)controllerForTabItem:(UITabBarItem *)item;

@end
