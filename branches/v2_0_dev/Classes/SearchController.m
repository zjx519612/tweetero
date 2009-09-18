//
//  SearchController.m
//  Tweetero
//
//  Created by Sergey Shkrabak on 9/18/09.
//  Copyright 2009 Codeminders. All rights reserved.
//
#import "MGTwitterEngine.h"
#import "SearchController.h"

@implementation SearchController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]))
    {
        _searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 100, 44)];
        _searchBar.backgroundColor = [UIColor clearColor];
        _searchBar.delegate = self;
        _searchController = [[UISearchDisplayController alloc] initWithSearchBar:_searchBar contentsController:self];
        _twitter = [[MGTwitterEngine alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [_searchBar release];
    [_searchController release];
    [_twitter release];
    [super dealloc];
}

- (void)viewDidAppear:(BOOL)animated
{
    //UIBarButtonItem *searchItem = [[UIBarButtonItem alloc] initWithCustomView:_searchBar];
    //self.navigationItem.rightBarButtonItem = searchItem;
    //[searchItem release];
    [self.view addSubview:_searchBar];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    //[_twitter getSearchResultsForQuery:
}

#pragma mark UITableView DataSource
/*
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *kCellIdentifier = @"SearchCell";
    
    UITableViewCell *cell = [[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:kCellIdentifier];
    cell.textLabel.text = @"Search";
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}
 */
@end
