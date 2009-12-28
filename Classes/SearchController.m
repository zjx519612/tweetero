//
//  SearchController.m
//  Tweetero
//
//  Created by Sergey Shkrabak on 9/18/09.
//  Copyright 2009 Codeminders. All rights reserved.
//

#import "TweetterAppDelegate.h"
#import "SearchController.h"
#import "CustomImageView.h"
#import "ImageLoader.h"
#include "util.h"

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
- (void)updateActionButton;
- (void)reloadData;
- (void)updateSearch;
- (void)activateIndicator:(BOOL)activate;
- (void)activateActionButton:(BOOL)activate;

@end

@implementation SearchController

@synthesize searchProvider = _searchProvider;
@synthesize query = _query;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]))
    {
        _searchController = [[UISearchDisplayController alloc] initWithSearchBar:_searchBar contentsController:self];
        _indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        _result = nil;
        _pageNum = START_AT_PAGE;
        
        self.query = nil;
    }
    return self;
}

- (id)initWithQuery:(NSString *)query
{
    if ((self = [self initWithNibName:@"SearchController" bundle:nil]))
    {
        [self activateActionButton:NO];
        self.query = query;
    }
    return self;
}

- (void)dealloc
{
    self.query = nil;
    if (self.searchProvider)
        self.searchProvider = nil;
    
    [_result release];
    [_searchBar release];
    [_indicator release];
    [_searchController release];
    [super dealloc];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.searchProvider = [SearchProvider sharedProviderUsingDelegate:self];
    
    _pageNum = START_AT_PAGE;
    _searchBar.text = self.query;
    self.navigationItem.titleView = _searchBar;
    if (self.query != nil)
        [_searchBar becomeFirstResponder];
        
    [self updateActionButton];
    [self reloadData];
}

- (void)viewDidDisappear:(BOOL)animated 
{
    [self clear];
    [self reloadData];
    
    // Reset delegate in searchProvider object
    if (self.searchProvider) 
    {
        self.searchProvider.delegate = nil;
        self.searchProvider = nil;
    }
    [super viewDidDisappear:animated];
}

- (IBAction)clickActionButton
{
    if ([self.searchProvider hasQuery:self.query])
        [self.searchProvider removeQuery:self.query];
    else
        [self.searchProvider saveQuery:self.query forId:0];
    [self activateActionButton:NO];
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
    [TweetterAppDelegate increaseNetworkActivityIndicator];
    
    [self clear];
    [self activateIndicator:YES];
    [self updateSearch];
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    return YES;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    self.query = searchText;
    [self updateActionButton];
}

#pragma mark SearchProvider Delegate
- (void)searchDidEnd:(NSArray *)recievedData forQuery:(NSString *)query
{
    if ([recievedData count] == 0)
        return;
    
    NSArray *tempArray;
    NSRange range;
    
    range.length = [recievedData count] - 1;
    range.location = 0;
    tempArray = [recievedData subarrayWithRange:range];

    NSArray *newResult = _result;
    if (newResult)
    {
        _result = [[newResult arrayByAddingObjectsFromArray:tempArray] retain];
        [newResult release];
    }
    else
        _result = [tempArray retain];
    
    [self reloadData];
    [TweetterAppDelegate decreaseNetworkActivityIndicator];
    [self activateIndicator:NO];
    [_searchBar resignFirstResponder];
}

- (void)searchDidEndWithError:(NSString *)query
{
}

- (void)searchProviderDidUpdated
{
    [self activateActionButton:YES];
    [self updateActionButton];
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
        
        NSLog(@"SEARCH_RESULT: %@", searchResult);
        [self setCellData:cell data:searchResult];
    }
    return cell;
}

#pragma mark UITableView Delegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];
    
    return cell.frame.size.height;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(indexPath.row == [_result count])
    {
        ++_pageNum;
        [self updateSearch];
    }
    else
    {
        //TweetViewController *view = [[TweetViewController alloc] initWithStore:self messageIndex:indexPath.row];
        //[self.navigationController pushViewController:view animated:YES];
        //[view release];
    }
}

#pragma mark TweetViewDelegate
- (int)messageCount
{
    return [_result count];
}

// Must return dictionary with message data
- (NSDictionary *)messageData:(int)index
{
    return [_result objectAtIndex:index];
}

@end

@implementation SearchController (Private)

- (UITableViewCell *)createSearchResultCell:(UITableView*)tableView more:(BOOL)isMore
{
    NSString *kCellIdentifier = isMore ? @"MoreSearchCell" : @"SearchCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
    
    if (!cell)
    {
        if (cell == nil)
            cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:kCellIdentifier] autorelease];
        
        if (isMore)
        {
            UILabel *more = [[UILabel alloc] initWithFrame:CGRectMake(135, 10, 200, 20)];
            more.text = NSLocalizedString(@"More...", @"");
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
            
            // Create "Text" label
            label = [[UILabel alloc] initWithFrame:CGRectMake(BORDER_WIDTH * 2 + IMAGE_SIDE, BORDER_WIDTH, LABLE_WIDTH, LABLE_HEIGHT)];
            label.font = [UIFont systemFontOfSize:13];
            label.lineBreakMode = UILineBreakModeWordWrap;
            label.numberOfLines = 0;
            label.tag = TAG_TEXT;
            label.backgroundColor = [UIColor clearColor];
            label.opaque = NO;
            [cell.contentView addSubview:label];
            [label release];
        }
    }
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (void)setCellData:(UITableViewCell *)cell data:(NSDictionary *)result
{
    CustomImageView *avatar = (CustomImageView*)[cell viewWithTag:TAG_IMAGE];
    id profileImageUrl = [result objectForKey:@"profile_image_url"];
    if (!isNullable(profileImageUrl))
        avatar.image = [[ImageLoader sharedLoader] imageWithURL:profileImageUrl];

    int doubleBorder = BORDER_WIDTH << 1;
    int height = 0;
    UILabel *label = nil;
    
    label = (UILabel*)[cell viewWithTag:TAG_FROM];
    label.text = [result objectForKey:@"from_user"];
    height = label.frame.size.height;
    
    int fromHeight = label.frame.size.height;
    
    label = (UILabel*)[cell viewWithTag:TAG_TEXT];
    label.text = DecodeEntities([result objectForKey:@"text"]);
    label.frame = CGRectMake(BORDER_WIDTH * 2 + IMAGE_SIDE, fromHeight + BORDER_WIDTH, LABLE_WIDTH, LABLE_HEIGHT);
    [label sizeToFit];
    height += label.frame.size.height;
    height += BORDER_WIDTH;
    
    if (height < (avatar.frame.size.height + doubleBorder))
        height = avatar.frame.size.height + doubleBorder;
    else
        height += BORDER_WIDTH;
    
    CGRect rc = cell.frame;
    rc.size.height = height;
    [cell setFrame:rc];
}

// Update action button
- (void)updateActionButton
{
    if (self.searchProvider)
    {
        UIBarButtonSystemItem systemItem;
        
        if ([self.searchProvider hasQuery:self.query])
            systemItem = UIBarButtonSystemItemTrash;
        else
            systemItem = UIBarButtonSystemItemAdd;
        
        UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: systemItem target: self action: @selector(clickActionButton)];
        self.navigationItem.rightBarButtonItem = item;
        [item release];
    }
    else
    {
        [self activateActionButton:NO];
    }
}

// Reload table data
- (void)reloadData
{
    [(UITableView*)self.view reloadData];
}

// Update search
- (void)updateSearch
{
    //[self clearAvatars];
    [self.searchProvider search:self.query fromPage:_pageNum count:MAX_SEARCH_COUNT];
}

// Activate/Deactivate progress indicator
- (void)activateIndicator:(BOOL)activate
{
    if (activate)
    {
        CGRect frame = self.view.frame;
        CGRect indFrame = _indicator.frame;
        frame.origin.x += (frame.size.width - indFrame.size.width) * 0.5f;
        frame.origin.y += (frame.size.height - indFrame.size.height) * 0.25f;
        frame.size = indFrame.size;
        _indicator.frame = frame;
        
        [self.view addSubview:_indicator];
        [_indicator startAnimating];
    }
    else
    {
        [_indicator stopAnimating];
        [_indicator removeFromSuperview];
    }
}

// Activate/Deactivate action button
- (void)activateActionButton:(BOOL)activate
{
    self.navigationItem.rightBarButtonItem.enabled = activate;
}

@end
