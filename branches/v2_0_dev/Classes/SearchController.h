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

@interface SearchController : UITableViewController <UISearchBarDelegate, SearchProviderDelegate, TweetViewDelegate>
{
  @private
    IBOutlet UISearchBar        *_searchBar;
    UIActivityIndicatorView     *_indicator;
    UISearchDisplayController   *_searchController;
    SearchProvider              *_searchProvider;
    NSArray                     *_result;
    int                          _pageNum;
    NSString                    *_query;
}

@property (nonatomic, retain) SearchProvider *searchProvider;
@property (nonatomic, copy) NSString *query;

- (id)initWithQuery:(NSString *)query;

- (IBAction)clickActionButton;

- (void)clear;

@end
