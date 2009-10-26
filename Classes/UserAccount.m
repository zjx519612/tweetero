//
//  UserAccount.m
//  Tweetero
//
//  Created by Sergey Shkrabak on 10/22/09.
//  Copyright 2009 Codeminders. All rights reserved.
//

#import "UserAccount.h"


@implementation UserAccount

@synthesize username = _username;

- (id)init
{
    NSAssert(NO, @"Object could not created");
    return nil;
}

- (void)dealloc
{
    self.username = nil;
    [super dealloc];
}

- (TwitterAuthType)authType
{
    return 0;
}

@end

// TwitterCommonUserAccount
@implementation TwitterCommonUserAccount

@synthesize password = _password;

- (id)init
{
    return self;
}

- (void)dealloc
{
    self.password = nil;
    [super dealloc];
}

- (TwitterAuthType)authType
{
    return TwitterCommon;
}
@end

// TwitterOAuthUserAccount
@implementation TwitterOAuthUserAccount

@synthesize accessToken = _accessToken;

- (id)init
{
    return self;
}

- (void)dealloc
{
    self.accessToken = nil;
    [super dealloc];
}

- (TwitterAuthType)authType
{
    return TwitterOAuth;
}

@end