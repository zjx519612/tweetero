//
//  SearchController.h
//  Tweetero
//
//  Created by Sergey Shkrabak on 9/18/09.
//  Copyright 2009 Codeminders. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MGTwitterEngineDelegate.h"

@class MGTwitterEngine;

@interface SearchController : UITableViewController <UISearchBarDelegate, MGTwitterEngineDelegate>
{
  @private
    IBOutlet UISearchBar        *_searchBar;
    MGTwitterEngine             *_twitter;
    UISearchDisplayController   *_searchController;
    NSArray                     *_result;
    int                          _pageNum;
    // Properties
    NSString                    *searchString;
}

@property (nonatomic, copy) NSString *searchString;

- (IBAction)clickActionTerm;

- (void)clear;

@end
