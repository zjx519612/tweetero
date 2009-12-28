//
//  MGTwitterEngineFactory.m
//  Tweetero
//
//  Created by Sergey Shkrabak on 11/5/09.
//  Copyright 2009 Codeminders. All rights reserved.
//

#import "MGTwitterEngine.h"
#import "SA_OAuthTwitterEngine.h"
#import "UserAccount.h"
#import "AccountManager.h"
#import "MGTwitterEngineFactory.h"
#include "config.h"

@implementation MGTwitterEngineFactory

+ (MGTwitterEngine*)createTwitterEngineForCurrentUser:(id)del
{
    MGTwitterEngineFactory *factory = [[[MGTwitterEngineFactory alloc] init] autorelease];
    
    UserAccount *account = [[AccountManager manager] loggedUserAccount];
    if (account)
    {
        return [factory createTwitterEngineForUserAccount:account delegate:del];
    }
    return nil;
}

- (MGTwitterEngine*)createTwitterEngineForUserAccount:(UserAccount*)account delegate:(id)del
{
    MGTwitterEngine *engine = nil;
    
    int authType = [account authType];
    if (authType == TwitterAuthCommon)
    {
        engine = [[MGTwitterEngine alloc] initWithDelegate:del];
        if (engine)
            [MGTwitterEngine setUsername:account.username password:account.secretData];
    }
    else if (authType == TwitterAuthOAuth)
    {
        SA_OAuthTwitterEngine *oaEngine = [[SA_OAuthTwitterEngine alloc] initOAuthWithDelegate:del];
        
        [oaEngine setConsumerKey:kTweeteroConsumerKey];
        [oaEngine setConsumerSecret:kTweeteroConsumerSecret];
        [oaEngine authorizeWithAccessTokenString:account.secretData];
        
        NSDictionary *dict = [oaEngine authRequestFields];
        NSLog(@"%@", dict);
        
        engine = oaEngine;
    }
    
    return [engine autorelease];
}

@end
