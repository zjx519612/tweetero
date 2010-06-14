//
//  MGTwitterSearchYAJLParser.m
//  MGTwitterEngine
//
//  Created by Matt Gemmell on 11/02/2008.
//  Copyright 2008 Instinctive Code.
//

#import "MGTwitterSearchYAJLParser.h"

#define DEBUG_PARSING 0

@interface MGTwitterSearchYAJLParser()
- (void)pushCollection:(id)collection;
- (void)popCollection;
- (id)currentCollection;
- (void)addValueToCollection:(id)collection value:(id)value forKey:(NSString*)key;
@end

@implementation MGTwitterSearchYAJLParser

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
    if (value == nil) {
        return;
    }
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
    
    [self addValue:collection forKey:key];
    [self pushCollection:collection];
}

- (void)endDictionary
{
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
    [_collection release];
	[super dealloc];
}

@end
