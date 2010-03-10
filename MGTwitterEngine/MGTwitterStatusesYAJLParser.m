//
//  MGTwitterStatusesYAJLParser.m
//  MGTwitterEngine
//
//  Created by Matt Gemmell on 11/02/2008.
//  Copyright 2008 Instinctive Code.
//

#import "MGTwitterStatusesYAJLParser.h"

#define DEBUG_PARSING 0

@interface MGTwitterStatusesYAJLParser()

- (NSMutableArray *)childs;

@end

@implementation MGTwitterStatusesYAJLParser

- (void)addValue:(id)value forKey:(NSString *)key
{
	if ([[self childs] count] == 0)
	{
		// There are no opened child containers so add value to root container
		[_root setObject:value forKey:key];
#if DEBUG_PARSING
		YFLog(@"status:  status: %@ = %@ (%@)", key, value, NSStringFromClass([value class]));
#endif
	}
	
	if ([[self childs] count] > 0)
	{
		// There is some opened child container
		NSDictionary *theLastChildHolder = [[self childs] lastObject];
		if (theLastChildHolder)
		{
			// Note that holder should contain only one key-value pair
			NSMutableDictionary *theChild = [[theLastChildHolder allValues] objectAtIndex:0];
			[theChild setObject:value forKey:key];
#if DEBUG_PARSING
			YFLog(@"status: added value: %@, for key: %@", [value description], key);
#endif
			return;
		}
	}
}

- (void)startDictionaryWithKey:(NSString *)key
{
#if DEBUG_PARSING
	YFLog(@"status: dictionary start = %@", key);
#endif

	if (! _root)
	{
		_root = [[NSMutableDictionary alloc] initWithCapacity:0];
		return;
	}
		
	// Holder is used to remember a key of the opened container
	NSMutableDictionary *theHolder = [NSMutableDictionary dictionaryWithCapacity:1];
	NSMutableDictionary *theChild = [NSMutableDictionary dictionaryWithCapacity:0];
	[theHolder setObject:theChild forKey:key];
	[[self childs] addObject:theHolder];
}

- (void)endDictionary
{
	NSDictionary *theLastChildHolder = [[self childs] lastObject];
	if (theLastChildHolder)
	{
		// Note that holder should contain only one key-value pair
		NSString *theKey = [[theLastChildHolder allKeys] objectAtIndex:0];
		NSDictionary *theChild = [theLastChildHolder objectForKey:theKey];
		
		if ([[self childs] count] == 1)
		{
			[_root setObject:theChild forKey:theKey];
#if DEBUG_PARSING
			YFLog(@"status: added dictionary for key: %@ to root container", theKey);
#endif
		}
		else if ([[self childs] count] > 1)
		{
			NSInteger theParentIndex = [[self childs] count] - 1;
			NSMutableDictionary *theParentHolder = [[self childs] objectAtIndex:theParentIndex];
			NSMutableDictionary *theParentContainer = [[theParentHolder allValues] objectAtIndex:0];
			[theParentContainer setObject:theChild forKey:theKey];
#if DEBUG_PARSING
			NSString *theParentKey = [[theParentHolder allKeys] objectAtIndex:0];
			YFLog(@"status: added dictionary for key: %@ to parent for key: %@", theKey, theParentKey);
#endif
		}

		[[self childs] removeLastObject];
		return;
	}
	
	if ([[self childs] count] == 0)
	{
		[_root setObject:[NSNumber numberWithInt:requestType] forKey:TWITTER_SOURCE_REQUEST_TYPE];
		
		[self _parsedObject:_root];
		
		[parsedObjects addObject:_root];
		[_root release];
		_root = nil;
		
#if DEBUG_PARSING
		YFLog(@"status: root dictionary is closed");
#endif
	}
}

- (void)startArrayWithKey:(NSString *)key
{
#if DEBUG_PARSING
	YFLog(@"status: array start = %@", key);
#endif
}

- (void)endArray
{
#if DEBUG_PARSING
	YFLog(@"status: array end");
#endif
}

- (void)dealloc
{
	[_root release];
	[_childs release];

	[super dealloc];
}

- (NSMutableArray *)childs
{
	if (! _childs)
	{
		// A container for items that contain other items, for instance
		// "user" dictionary, "geo" dictionary.
		_childs = [[NSMutableArray alloc] initWithCapacity:0];
	}
	
	return _childs;
}

@end
