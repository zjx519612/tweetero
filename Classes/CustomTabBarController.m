//
//  CustomTabBarController.m
//  Tweetero
//
//  Created by Sergey Shkrabak on 9/17/09.
//  Copyright 2009 Codeminders. All rights reserved.
//

#import "CustomTabBarController.h"
#import "MGTwitterEngine.h"
#import "SearchController.h"
#import "AppController.h"

#include "util.h"

const int kMoreBarItemTag   = -1;
const int kMaxBarItems      = 5;
const int kViewScreenWidth  = 320;
const int kViewScreenHeight = 370;
const int kTabBarHeight     = 46;

@interface CustomTabBarController (Private)
- (NSString *)makeKeyForItem:(UITabBarItem *)item;
- (NSMutableArray *)createTabBarItems;
@end

@implementation CustomTabBarController

@synthesize searchProvider = _searchProvider;

- (id)init
{
    if ((self = [super init]))
    {
        _viewControllers = [[NSMutableDictionary alloc] init];
        _contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kViewScreenWidth, kViewScreenHeight)];
        _tabBar = [[UITabBar alloc] init];
        _tabBar.frame = CGRectMake(0, kViewScreenHeight, kViewScreenWidth, kTabBarHeight);
        _tabBar.delegate = self;
        _tabBar.selectedItem == nil;
        _moreTable = nil;
        
        NSMutableArray *items = [self createTabBarItems];
        if (items && ([items count] > kMaxBarItems))
        {
            // Add only first 4 items to tab bar
            NSMutableArray *tabs = [[NSMutableArray alloc] init];
            for (int i = 0; i < 4; i++)
                [tabs addObject:[items objectAtIndex:i]];
            
            UITabBarItem *moreItem = [[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemMore tag:kMoreBarItemTag];
            [tabs addObject:moreItem];
            [moreItem release];
            
            // Create more items array
            _moreItems = [[NSMutableArray alloc] init];
            for (int i = 4; i < [items count]; i++)
                [_moreItems addObject:[items objectAtIndex:i]];
            
            _moreTable = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, kViewScreenWidth, kViewScreenHeight) style:UITableViewStylePlain];
            _moreTable.delegate = self;
            _moreTable.dataSource = self;
            
            // Set tabBar items
            _tabBar.items = tabs;
            [tabs release];
        }
        else
        {
            _tabBar.items = items;
        }
        
        [self.view addSubview:_contentView];
        [self.view addSubview:_tabBar];
    }
    return self;
}

- (void)dealloc
{
    if (self.searchProvider)
    {
        self.searchProvider.delegate = nil;
        self.searchProvider = nil;
    }
    
    _tabBar.delegate = nil;
    if (_moreTable)
    {
        _moreTable.delegate = nil;
        [_moreTable release];
        [_moreItems release];
    }

    [_tabBar release];
    [_contentView release];
    [_viewControllers release];
    [super dealloc];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if ([_tabBar.items count] > 0 && _tabBar.selectedItem == nil)
    {
        _tabBar.selectedItem = [_tabBar.items objectAtIndex:0];
        [self tabBar:_tabBar didSelectItem:_tabBar.selectedItem];
    }
    
    if (_tabBar.selectedItem.tag == kMoreBarItemTag)
    {
        [_moreTable reloadData];
    }
    self.searchProvider = [[AppController instance] searchProviderWithDelegate:self];
    [self.searchProvider update];
}

/*
 * addViewController
 *
 * Add controller to dictionary. Retunrn key for added controller.
 */
- (NSString *)addViewController:(UIViewController *)controller
{
    NSString *key = [self makeKeyForItem:controller.tabBarItem];
    [_viewControllers setObject:controller forKey:key];
    return key;
}

/*
 * controllerForTabItem
 *
 * Return controller object for tabitem.
 */
- (UIViewController *)controllerForTabItem:(UITabBarItem *)item
{
    NSString *key = [self makeKeyForItem:item];
    return [_viewControllers objectForKey:key];
}

#pragma mark SearchProvider Delgate methods
- (void)searchProviderDidUpdated
{
    [_moreTable reloadData];
}

#pragma mark UITabBar Delegate
- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    // Clear all subviews in main view
    for (UIView *child in _contentView.subviews)
        [child removeFromSuperview];
    
    if (item.tag == kMoreBarItemTag)
    {
        // Show More table
        self.navigationItem.title = NSLocalizedString(@"More", @"");
        self.navigationItem.rightBarButtonItem = nil;

        [_contentView addSubview:_moreTable];
    }
    else
    {
        // Get controller for current tab and show it view on top.
        UIViewController *controller = [self controllerForTabItem:item];

        if (controller)
        {
            // Update navigation bar
            self.navigationItem.title = controller.title;
            self.navigationItem.rightBarButtonItem = nil;
            
            if ([controller respondsToSelector:@selector(setRootNavigationController:)])
                [controller performSelector:@selector(setRootNavigationController:) withObject:self.navigationController];
            
            if ([controller respondsToSelector:@selector(viewControllerDidActivate:)])
                [controller performSelector:@selector(viewControllerDidActivate:) withObject:self];
            
            // Add controller view to content view.
            controller.view.frame = CGRectMake(0, 0, kViewScreenWidth, kViewScreenHeight);
            controller.tabBarItem = item;
           [_contentView addSubview:controller.view];
        }
    }
}

#pragma mark UITableView DataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return ([self.searchProvider allQueries] && ([self.searchProvider allQueries] > 0)) ? 2 : 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
        return [_moreItems count];
    else if (section == 1)
        return [[self.searchProvider allQueries] count];
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *kCellIdentifier = @"MoreViewCell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];

    if (cell == nil)
        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:kCellIdentifier] autorelease];
    
    // Controller cells
    if (indexPath.section == 0)
    {
        UITabBarItem *tabItem = [_moreItems objectAtIndex:indexPath.row];
        
        if (tabItem)
        {
            cell.textLabel.text =  tabItem.title;
            cell.imageView.image = tabItem.image;
        }
    }
    // Saved search cells
    else
    {
        cell.imageView.image = nil;
        cell.textLabel.text = [[self.searchProvider allQueries] objectAtIndex:indexPath.row];
    }
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

#pragma mark UITableView Delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
    {
        UITabBarItem *tabItem = [_moreItems objectAtIndex:indexPath.row];
        if (tabItem)
        {
            UIViewController *controller = [self controllerForTabItem:tabItem];
            if (controller)
                [self.navigationController pushViewController:controller animated:YES];
        }
    }
    else if (indexPath.section == 1)
    {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        
        NSAssert(cell != nil, @"Cell is nil");
        SearchController *searchController = [[SearchController alloc] initWithQuery:cell.textLabel.text];
        [self.navigationController pushViewController:searchController animated:YES];
        [searchController release];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section 
{
    if (section == 1)
        return NSLocalizedString(@"Saved Searches", @"");
    return nil;
}

@end

@implementation CustomTabBarController (Private)

- (NSString *)makeKeyForItem:(UITabBarItem *)item
{
    int tag = 0;
    if (item)
        tag = item.tag;
    return [NSString stringWithFormat:@"__Controller_%i__", tag];
}

- (NSMutableArray *)createTabBarItems
{
    return nil;
}

@end