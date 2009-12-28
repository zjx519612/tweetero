//
//  SearchTest.m
//  Tweetero
//
//  Created by Sergey Shkrabak on 10/16/09.
//  Copyright 2009 Codeminders. All rights reserved.
//

#import "SearchTest.h"
#import "SearchProvider.h"

@implementation SearchTest

#if USE_APPLICATION_UNIT_TEST     // all code under test is in the iPhone Application

- (void)testAppDelegate 
{
    id yourApplicationDelegate = [[UIApplication sharedApplication] delegate];
    STAssertNotNil(!yourApplicationDelegate, @"UIApplication failed to find the AppDelegate");
}

#else                           // all code under test must be linked into the Unit Test bundle

- (void)testMath 
{
    STAssertTrue((1+1)==2, @"Compiler isn't feeling well today :-(" );
}

#endif

- (void)testSearchProvider
{
    //SearchProvider *provider = [SearchProvider provider];
    //NSAssert(provider, @"Provider is nill");
}

@end
