//
//  MGTwitterUsersYAJLParser.m
//  MGTwitterEngine
//
//  Created by Matt Gemmell on 11/02/2008.
//  Copyright 2008 Instinctive Code.
//

#import "MGTwitterUsersYAJLParser.h"

#define DEBUG_PARSING 1

@interface MGTwitterUsersYAJLParser()
- (void)pushCollection:(id)collection;
- (void)popCollection;
- (id)currentCollection;
- (void)addValueToCollection:(id)collection value:(id)value forKey:(NSString*)key;
@end

@implementation MGTwitterUsersYAJLParser

- (void)pushCollection:(id)collection
{
    if (_collection == nil) {
        _collection = [[NSMutableArray alloc] init];
        [_collection addObject:parsedObjects];
    }
    [_collection addObject:collection];
}

- (void)popCollection
{
    [_collection removeLastObject];
}

- (id)currentCollection
{
    if (_collection == nil) {
        _collection = [[NSMutableArray alloc] init];
        [_collection addObject:parsedObjects];
    }
    return [_collection lastObject];
}

- (void)addValueToCollection:(id)collection value:(id)value forKey:(NSString*)key
{
    if (value == nil)
        return;
    if ([collection isKindOfClass:[NSDictionary class]]) {
        [collection setObject:value forKey:key];
    } else if ([collection isKindOfClass:[NSArray class]]) {
        [collection addObject:value];
    }
}

- (void)normalizeParsedObjects
{
    NSMutableArray *temp = [NSMutableArray array];
    for (id item in parsedObjects) {
        if ([item isKindOfClass:[NSArray class]]) {
            [temp addObject:item];
        }
    }
    
    for (id item in temp) {
        [parsedObjects addObjectsFromArray:item];
        [parsedObjects removeObject:item];
    }
}

- (void)addValue:(id)value forKey:(NSString *)key
{
    id top = [self currentCollection];
    
    [self addValueToCollection:top value:value forKey:key];
}

- (void)startDictionaryWithKey:(NSString *)key
{
    id collection = [NSMutableDictionary dictionary];
    if ([key isEqualToString:@"user"]) {
        _user = [collection retain];
    }
    [self addValue:collection forKey:key];
    [self pushCollection:collection];
}

- (void)endDictionary
{
    if (_user) {
        [_user setObject:[NSNumber numberWithInt:requestType] forKey:TWITTER_SOURCE_REQUEST_TYPE];
        [_user release];
        _user = nil;
    }
    [self popCollection];
}

- (void)startArrayWithKey:(NSString *)key
{
    id collection = [NSMutableArray array];
    
    [self addValue:collection forKey:key];
    [self pushCollection:collection];
}

- (void)endArray
{
    [self popCollection];
}

- (void)dealloc
{
    if (_user) {
        [_user release];
    }
    [_collection release];
	[super dealloc];
}

@end

/*
@implementation MGTwitterUsersYAJLParser

- (void)addValue:(id)value forKey:(NSString *)key
{
	if (_status)
	{
		[_status setObject:value forKey:key];
#if DEBUG_PARSING
		YFLog(@"user:   status: %@ = %@ (%@)", key, value, NSStringFromClass([value class]));
#endif
	}
	else if (_user)
	{
		[_user setObject:value forKey:key];
#if DEBUG_PARSING
		YFLog(@"user:   user: %@ = %@ (%@)", key, value, NSStringFromClass([value class]));
#endif
	}
}

- (void)startDictionaryWithKey:(NSString *)key
{
#if DEBUG_PARSING
	YFLog(@"user: dictionary start = %@", key);
#endif

	if (! _user)
	{
		_user = [[NSMutableDictionary alloc] initWithCapacity:0];
	}
	else
	{
		if (! _status)
		{
			_status = [[NSMutableDictionary alloc] initWithCapacity:0];
		}
	}
}

- (void)endDictionary
{
	if (_status)
	{
		[_user setObject:_status forKey:@"status"];
		[_status release];
		_status = nil;
	}
	else
	{
		[_user setObject:[NSNumber numberWithInt:requestType] forKey:TWITTER_SOURCE_REQUEST_TYPE];
		
		[self _parsedObject:_user];
		
		[parsedObjects addObject:_user];
		[_user release];
		_user = nil;
	}
	
#if DEBUG_PARSING
	YFLog(@"user: dictionary end");
#endif
}

- (void)startArrayWithKey:(NSString *)key
{
#if DEBUG_PARSING
	YFLog(@"user: array start = %@", key);
#endif
}

- (void)endArray
{
#if DEBUG_PARSING
	YFLog(@"user: array end");
#endif
}

- (void)dealloc
{
	[_user release];
	[_status release];

	[super dealloc];
}

@end
*/