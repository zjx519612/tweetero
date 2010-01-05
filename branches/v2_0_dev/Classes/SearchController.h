//
//  SearchController.h
//  Tweetero
//
//  Created by Sergey Shkrabak on 9/18/09.
//  Copyright 2009 Codeminders. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SearchProvider.h"
#import "TweetViewController.h"
#import "TwActivityIndicator.h"

@interface SearchController : UITableViewController <UISearchBarDelegate, SearchProviderDelegate, TweetViewDelegate>
{
  @private
    IBOutlet UISearchBar        *_searchBar;
    TwActivityIndicator         *_indicator;
    UISearchDisplayController   *_searchController;
    SearchProvider              *_searchProvider;
    //NSArray                     *_result;
    NSMutableArray              *_result;
    int                          _pageNum;
    NSString                    *_query;
    BOOL                         _showSearchResult;
    BOOL                         _hasConnectionError;
    NSString                    *_emptyString;
}

@property (nonatomic, retain) SearchProvider *searchProvider;
@property (nonatomic, copy) NSString *query;

- (id)initWithQuery:(NSString *)query;

- (IBAction)clickActionButton;

- (void)clear;

@end
