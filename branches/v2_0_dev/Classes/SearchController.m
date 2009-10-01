//
//  SearchController.m
//  Tweetero
//
//  Created by Sergey Shkrabak on 9/18/09.
//  Copyright 2009 Codeminders. All rights reserved.
//
#import "MGTwitterEngine.h"
#import "SearchController.h"
#import "CustomImageView.h"
#import "ImageLoader.h"

#include "util.h"
#include "searchutil.h"

// Tag identifire
#define TAG_IMAGE               1
#define TAG_FROM                2
#define TAG_TO                  3
#define TAG_TEXT                4
// Geometry metrics
#define BORDER_WIDTH            5
#define IMAGE_SIDE              48
#define LABLE_HEIGHT            15
#define LABLE_WIDTH             250

#define MAX_SEARCH_COUNT        20
#define START_AT_PAGE           1

@interface SearchController (Private)

- (UITableViewCell *)createSearchResultCell:(UITableView*)tableView more:(BOOL)isMore;
- (void)setCellData:(UITableViewCell *)cell data:(NSDictionary *)result;
- (void)updateTermActionButton;
- (void)reloadData;
- (void)updateSearch;

@end

@implementation SearchController

@synthesize searchString;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]))
    {
        _searchController = [[UISearchDisplayController alloc] initWithSearchBar:_searchBar contentsController:self];
        _twitter = [[MGTwitterEngine alloc] initWithDelegate:self];
        _result = nil;
        _pageNum = START_AT_PAGE;
        self.searchString = nil;
    }
    return self;
}

- (void)dealloc
{
    self.searchString = nil;
    
    if (_result)
        [_result release];
    [_searchBar release];
    [_searchController release];
    [_twitter release];
    [super dealloc];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    _pageNum = START_AT_PAGE;
    _searchBar.text = self.searchString;
    if (self.searchString)
        [self searchBarSearchButtonClicked:_searchBar];
    self.navigationItem.titleView = _searchBar;
    
    [self updateTermActionButton];
    [self reloadData];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self clear];
}

- (IBAction)clickActionTerm
{
    NSString *searchStr = [NSString stringWithString:_searchBar.text];
    
    //[_twitter twitterDestroySearch:1934118];
    
    if (presentAtSavedSearchTerms(searchStr))
        removeSearchTerm(searchStr);
    else
        saveSearchTerm(searchStr);
    [self updateTermActionButton];
}

- (void)clear
{
    if (_result)
        [_result release];
    _result = nil;
}

#pragma mark UISearchBar Delegate
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    if (_result)
        [_result release];
    [self updateSearch];
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    return YES;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self updateTermActionButton];
}

#pragma mark MGTwitterEngine Delegate
- (void)requestSucceeded:(NSString *)connectionIdentifier
{
}

- (void)requestFailed:(NSString *)connectionIdentifier withError:(NSError *)error
{
}

- (void)receivedObject:(NSDictionary *)dictionary forRequest:(NSString *)connectionIdentifier
{
}

- (void)statusesReceived:(NSArray *)statuses forRequest:(NSString *)connectionIdentifier
{
}

- (void)directMessagesReceived:(NSArray *)messages forRequest:(NSString *)connectionIdentifier
{
}

- (void)userInfoReceived:(NSArray *)userInfo forRequest:(NSString *)connectionIdentifier
{
}

- (void)miscInfoReceived:(NSArray *)miscInfo forRequest:(NSString *)connectionIdentifier
{
}

- (void)searchResultsReceived:(NSArray *)searchResults forRequest:(NSString *)connectionIdentifier
{
    if ([searchResults count] == 0)
        return;

    NSArray *tempArray;
    NSRange range;
        
    range.length = [searchResults count] - 1;
    range.location = 0;
    tempArray = [searchResults subarrayWithRange:range];
    
    NSArray *newResult = _result;
    if (newResult)
    {
        _result = [[newResult arrayByAddingObjectsFromArray:tempArray] retain];
        [newResult release];
    }
    else
    {
        _result = [tempArray retain];
    }

    [self reloadData];
    /*
     
     NSArray *prevRes = _result;
     if (prevRes)
     {
     _result = [[prevRes arrayByAddingObjectsFromArray:tempArray] retain];
     NSMutableArray *rows = [NSMutableArray arrayWithCapacity:[tempArray count]];
     for (int i = [prevRes count]; i < [_result count]; ++i)
     [rows addObject:[NSIndexPath indexPathForRow:i inSection:0]];
     if ([rows count] > 0)
     [(UITableView*)self.view insertRowsAtIndexPaths:rows withRowAnimation:YES];
     [prevRes release];
     }
     else
     {
     _result = [tempArray retain];
     }
     [self reloadData];
     
     */
    [_searchBar resignFirstResponder];
}

- (void)imageReceived:(UIImage *)image forRequest:(NSString *)connectionIdentifier
{
}

- (void)connectionFinished
{
}

#pragma mark UITableView DataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    int count = 0;
    
    if (_result)
        count = [_result count];
    if (count == MAX_SEARCH_COUNT * _pageNum)
        count++;
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    BOOL isMoreCell = YES;
    
    if (indexPath.row < [_result count])
        isMoreCell = NO;

    cell = [self createSearchResultCell:tableView more:isMoreCell];
    if (!isMoreCell)
    {
        NSDictionary *searchResult = [_result objectAtIndex:indexPath.row];
        [self setCellData:cell data:searchResult];
    }
    return cell;
}

#pragma mark UITableView Delegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 80;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(indexPath.row == [_result count])
    {
        //UIActivityIndicatorView *indicator = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray] autorelease];
        //UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        
        //indicator.contentMode = UIViewContentModeCenter;
        //[self.view addSubview:indicator];
        ++_pageNum;
        [self updateSearch];
    }
}

@end

@implementation SearchController (Private)

- (UITableViewCell *)createSearchResultCell:(UITableView*)tableView more:(BOOL)isMore
{
    NSString *kCellIdentifier = isMore ? @"MoreSearchCell" : @"SearchCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
    
    if (cell == nil)
        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:kCellIdentifier] autorelease];
    
    if (cell)
    {
        if (isMore)
        {
            UILabel *more = [[UILabel alloc] initWithFrame:CGRectMake(135, 30, 200, 20)];
            more.text = @"More...";
            more.backgroundColor = [UIColor clearColor];
            [cell.contentView addSubview:more];
            [more release];            
        }
        else
        {
            // Create avatar image
            CustomImageView *avatar = [[CustomImageView alloc] initWithFrame:CGRectMake(BORDER_WIDTH, BORDER_WIDTH, IMAGE_SIDE, IMAGE_SIDE)];
            avatar.tag = TAG_IMAGE;
            avatar.backgroundColor = [UIColor clearColor];
            [cell.contentView addSubview:avatar];
            [avatar release];
            
            UILabel *label = nil;
            
            // Create "From" label
            label = [[UILabel alloc] initWithFrame:CGRectMake(BORDER_WIDTH * 2 + IMAGE_SIDE, BORDER_WIDTH, LABLE_WIDTH, LABLE_HEIGHT)];
            label.font = [UIFont boldSystemFontOfSize:14];
            label.tag = TAG_FROM;
            label.backgroundColor = [UIColor clearColor];
            [cell.contentView addSubview:label];
            [label release];
            
            // Create "To" label
            label = [[UILabel alloc] initWithFrame:CGRectMake(BORDER_WIDTH * 2 + IMAGE_SIDE, BORDER_WIDTH + 20, LABLE_WIDTH, LABLE_HEIGHT)];
            label.font = [UIFont boldSystemFontOfSize:14];
            label.tag = TAG_TO;
            label.backgroundColor = [UIColor clearColor];
            [cell.contentView addSubview:label];
            [label release];
            
            // Create "Text" label
            label = [[UILabel alloc] initWithFrame:CGRectMake(BORDER_WIDTH * 2 + IMAGE_SIDE, BORDER_WIDTH + 40, LABLE_WIDTH, 30)];
            label.font = [UIFont systemFontOfSize:13];
            label.numberOfLines = 10;
            label.tag = TAG_TEXT;
            label.backgroundColor = [UIColor clearColor];
            [cell.contentView addSubview:label];
            [label release];
        }
    }
    return cell;
}

- (void)setCellData:(UITableViewCell *)cell data:(NSDictionary *)result
{
    static int i = 0;
    
    NSString *title = [NSString stringWithFormat:@"USER_INFO : %i", i++];
    LogDictionaryStringKeys(result, title);
    
    CustomImageView *avatar = (CustomImageView*)[cell viewWithTag:TAG_IMAGE];
    
    id imageUrl = [result objectForKey:@"profile_image_url"];
    if (!isNullable(imageUrl))
        avatar.image = [[ImageLoader sharedLoader] imageWithURL:imageUrl];
    
    UILabel *label = nil;
    
    label = (UILabel*)[cell viewWithTag:TAG_FROM];
    label.text = [result objectForKey:@"from_user"];
    
    label = (UILabel*)[cell viewWithTag:TAG_TO];
    label.text = [result objectForKey:@"to_user"];
    
    label = (UILabel*)[cell viewWithTag:TAG_TEXT];
    label.text = DecodeEntities([result objectForKey:@"text"]);
}

- (void)updateTermActionButton
{
    UIBarButtonItem *item;
    UIBarButtonSystemItem systemItem;
    
    if (presentAtSavedSearchTerms(_searchBar.text))
        systemItem = UIBarButtonSystemItemTrash;
    else
        systemItem = UIBarButtonSystemItemAdd;
    
    item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:systemItem target:self action:@selector(clickActionTerm)];
    self.navigationItem.rightBarButtonItem = item;
    [item release];
}

- (void)reloadData
{
    [(UITableView*)self.view reloadData];
}

- (void)updateSearch
{
    [_twitter getSearchResultsForQuery:_searchBar.text sinceID:0 startingAtPage:_pageNum count:MAX_SEARCH_COUNT];
}

@end
