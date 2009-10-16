//
//  SearchProvider.m
//  Tweetero
//
//  Created by Sergey Shkrabak on 10/16/09.
//  Copyright 2009 Codeminders. All rights reserved.
//

#import "SearchProvider.h"
#import "MGTwitterEngine.h"
#import "MGTwitterEngine+Search.h"

@interface SearchProvider(Private)

- (void)setNotificationValue:(SPNotificationValue)value forIdentifier:(NSString *)identifier;
- (void)setNotificationValue:(SPNotificationValue)value forIdentifier:(NSString *)identifier forQuery:(NSString *)query;
- (void)removeNotification:(NSString *)identifier;
- (SPNotificationValue)notificationForIdentifier:(NSString *)identifier;
- (NSString *)queryForIdentifier:(NSString *)identifier;
- (BOOL)validateQuery:(NSString *)query;
- (void)updateQueries:(NSArray *)data;

@end

@implementation SearchProvider

@synthesize twitter = _twitter;
@synthesize delegate = _delegate;

+ (SearchProvider *)providerWithDelegate:(id)delegate
{
    SearchProvider *provider = [[SearchProvider alloc] initWithDelegate:delegate];
    return [provider autorelease];
}

- (id)init
{
    NSAssert(NO, @"Use initWithTwitterEngine method for init object");
    return nil;
}

- (id)initWithDelegate:(id)delegate
{
    if ((self = [super init]))
    {
        _queries = [[NSMutableDictionary alloc] init];
        _twitterConnection = [[NSMutableDictionary alloc] init];
        _twitter = [[MGTwitterEngine alloc] initWithDelegate:self];
        self.delegate = delegate;
    }
    return self;
}

- (void)dealloc
{
    self.delegate = nil;
    [_twitter release];
    [_twitterConnection release];
    [_queries release];
    [super dealloc];
}

// Update object state
- (void)update
{
    NSString *identifier = [self.twitter getSearchSavedResult:0 count:0];
    [self setNotificationValue:SPUpdateState forIdentifier:identifier];
}

// Return YES if query string present in dictionary
- (BOOL)hasQuery:(NSString *)query
{
    return ([[_queries allKeys] indexOfObject:query] != NSNotFound);
}

// Return YES if query with query id present in dictionary
- (BOOL)hasQueryById:(int)queryId
{
    NSNumber *value = [NSNumber numberWithInt:queryId];
    return ([[_queries allValues] indexOfObjectIdenticalTo:value] != NSNotFound);
}

// Save query string in tweeter
- (void)saveQuery:(NSString *)query forId:(int)queryId
{
    NSNumber *value = [NSNumber numberWithInt:queryId];

    [_twitter searchSaveQuery:query];
    [_queries setObject:value forKey:query];
}

// Remove saved search query
- (void)removeQuery:(NSString *)query
{
    int queryId = [self queryId:query];
    
    if (queryId > 0)
    {
        [_twitter searchDestroyQuery:queryId];
        [_queries removeObjectForKey:query];
    }
}

// Remove saved search query with query id
- (void)removeQueryById:(int)queryId
{
    if (queryId > 0)
    {
        NSString *query = [self queryById:queryId];

        if (query)
        {
            [_twitter searchDestroyQuery:queryId];
            [_queries removeObjectForKey:query];
        }
    }
}

// Return query string by id
- (NSString *)queryById:(int)queryId
{
    NSString *query = nil;
    for (NSString *key in [_queries allKeys])
    {
        if ([[_queries objectForKey:key] intValue] == queryId)
        {
            query = key;
            break;
        }
    }
    return query;
}

// Return id for query string
- (int)queryId:(NSString *)query
{
    NSNumber *value = [_queries objectForKey:query];
    if (!value)
        return 0;
    return [value unsignedLongValue];
}

// Return queries array
- (NSArray *)allQueries
{
    return [_queries allKeys];
}

#pragma mark MGTwitterEngineDelegate
- (void)searchResultsReceived:(NSArray *)searchResults forRequest:(NSString *)connectionIdentifier
{
    SPNotificationValue notification = [self notificationForIdentifier:connectionIdentifier];
    
    if (notification == SPInvalidValue)
        return;
    
    switch (notification) 
    {
        case SPSearchData:
            if (self.delegate && [self.delegate respondsToSelector:@selector(searchDidEnd:forQuery:)])
            {
                NSString *query = [self queryForIdentifier:connectionIdentifier];
                [self.delegate performSelector:@selector(searchDidEnd:forQuery:) withObject:searchResults withObject:query];
            }
            break;
        case SPSavedSearch:
            [self updateQueries:searchResults];
            if (self.delegate && [self.delegate respondsToSelector:@selector(searchSavedSearchReceived:)])
            {
                [self.delegate performSelector:@selector(searchSavedSearchReceived:) withObject:searchResults];
            }
            break;
        case SPUpdateState:
            [self updateQueries:searchResults];
        default:
            break;
    }
}

- (void)requestFailed:(NSString *)connectionIdentifier withError:(NSError *)error 
{
    NSString *query = [self queryForIdentifier:connectionIdentifier];
    if (self.delegate && [self.delegate respondsToSelector:@selector(searchDidEndWithError:)])
    {
        [self.delegate performSelector:@selector(searchDidEndWithError:) withObject:query];
    }
}

#pragma mark Unusable MGTwitterEngineDelegate methods
- (void)requestSucceeded:(NSString *)connectionIdentifier {}
- (void)receivedObject:(NSDictionary *)dictionary forRequest:(NSString *)connectionIdentifier {}
- (void)statusesReceived:(NSArray *)statuses forRequest:(NSString *)connectionIdentifier {}
- (void)directMessagesReceived:(NSArray *)messages forRequest:(NSString *)connectionIdentifier {}
- (void)userInfoReceived:(NSArray *)userInfo forRequest:(NSString *)connectionIdentifier {}
- (void)miscInfoReceived:(NSArray *)miscInfo forRequest:(NSString *)connectionIdentifier {}
- (void)imageReceived:(UIImage *)image forRequest:(NSString *)connectionIdentifier {}
- (void)connectionFinished {}

@end

@implementation SearchProvider(SearchMethods)

- (void)search:(NSString *)query
{
    if ([self validateQuery:query] == YES)
    {
        NSString *identifier = [_twitter getSearchResultsForQuery:query];
        [self setNotificationValue:SPSearchData forIdentifier:identifier forQuery:query];
    }
}

- (void)search:(NSString *)query fromPage:(int)page count:(int)count
{
    if ([self validateQuery:query] == YES)
    {
        NSString *identifier = [_twitter getSearchResultsForQuery:query sinceID:0 startingAtPage:page count:count];
        [self setNotificationValue:SPSearchData forIdentifier:identifier forQuery:query];
    }
}

- (void)searchForQueryId:(int)queryId
{
    NSString *query = [self queryById:queryId];
    
    if ([self validateQuery:query] == YES)
    {
        NSString *identifier = [_twitter getSearchSavedResultById:queryId];
        [self setNotificationValue:SPSearchData forIdentifier:identifier forQuery:query];
    }
}

- (void)searchForQueryId:(int)queryId fromPage:(int)page count:(int)count
{
    [self searchForQueryId:queryId];
}

- (void)savedSearch
{
    NSString *identifier = [_twitter getSearchSavedResult:0 count:0];
    [self setNotificationValue:SPSavedSearch forIdentifier:identifier];
}

@end

@implementation SearchProvider(Private)

- (void)setNotificationValue:(SPNotificationValue)value forIdentifier:(NSString *)identifier
{
    [self setNotificationValue:value forIdentifier:identifier forQuery:nil];
}

- (void)setNotificationValue:(SPNotificationValue)value forIdentifier:(NSString *)identifier forQuery:(NSString *)query
{
    NSArray *values = [NSArray arrayWithObjects:[NSNumber numberWithInt:value], query, nil];
    
    [_twitterConnection setObject:values forKey:identifier];
}

- (void)removeNotification:(NSString *)identifier
{
    [_twitterConnection removeObjectForKey:identifier];
}

- (SPNotificationValue)notificationForIdentifier:(NSString *)identifier
{
    NSArray *value = [_twitterConnection objectForKey:identifier];
    if (value == nil)
        return SPInvalidValue;
    return [[value objectAtIndex:0] intValue];
}

- (NSString *)queryForIdentifier:(NSString *)identifier
{
    NSArray *value = [_twitterConnection objectForKey:identifier];
    if (value == nil && [value count] < 2)
        return nil;
    return [value objectAtIndex:1];
}

- (BOOL)validateQuery:(NSString *)query
{
    return YES;
}

- (void)updateQueries:(NSArray *)data
{
    @synchronized(self)
    {
        // Update queries
        for (NSDictionary *search in data)
        {
            NSString *query = [NSString stringWithString:[search objectForKey:@"query"]];
            int queryId = [[search objectForKey:@"id"] intValue];
            
            [_queries setObject:[NSNumber numberWithInt:queryId] forKey:query];
        }
        
        // Notificate delegate object about changing
        if (self.delegate && [self.delegate respondsToSelector:@selector(searchProviderDidUpdated)])
        {
            [self.delegate performSelector:@selector(searchProviderDidUpdated)];
        }
    }
}

@end