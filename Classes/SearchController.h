//
//  SearchController.h
//  Tweetero
//
//  Created by Sergey Shkrabak on 9/18/09.
//  Copyright 2009 Codeminders. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MGTwitterEngine;
@interface SearchController : UITableViewController <UISearchBarDelegate>
{
    MGTwitterEngine *_twitter;
    UISearchBar *_searchBar;
    UISearchDisplayController *_searchController;
}

@end
