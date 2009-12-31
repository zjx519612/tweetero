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

+ (MGTwitterEngineFactory*)factory
{
    return [[[MGTwitterEngineFactory alloc] init] autorelease];
}

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
        
        engine = oaEngine;
    }
    
    return [engine autorelease];
}

- (NSDictionary*)createTwitterAuthorizationFields:(UserAccount*)account
{
    if (account == nil)
        return nil;
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    
    if (account.authType == TwitterAuthCommon)
    {
        [params setObject:[account username] forKey:@"username"];
        [params setObject:[account secretData] forKey:@"password"];
    }
    else if (account.authType == TwitterAuthOAuth)
    {
        SA_OAuthTwitterEngine *oaEngine = [[SA_OAuthTwitterEngine alloc] initOAuthWithDelegate:self];
        
        [oaEngine setConsumerKey:kTweeteroConsumerKey];
        [oaEngine setConsumerSecret:kTweeteroConsumerSecret];
        [oaEngine authorizeWithAccessTokenString:account.secretData];
        
        [params setObject:@"oauth" forKey:@"auth"];
        [params setObject:[account username] forKey:@"username"];
        
        NSDictionary *oauthFields = [oaEngine authRequestFields];
        
        //https://twitter.com/account/verify_credentials.xml?
        //      oauth_version=%@&
        //      oauth_nonce=%@&
        //      oauth_timestamp=%@&
        //      oauth_consumer_key=%@&
        //      oauth_token=%@&
        //      oauth_signature_method=%@&
        //      oauth_signature=%@
        
        NSString *credential = [NSString stringWithFormat:kYFrogVerifyCredentialUrlMask,
                                    [oauthFields objectForKey:@"oauth_version"],
                                    [oauthFields objectForKey:@"oauth_nonce"],
                                    [oauthFields objectForKey:@"oauth_timestamp"],
                                    [oauthFields objectForKey:@"oauth_consumer_key"],
                                    [oauthFields objectForKey:@"oauth_token"],
                                    [oauthFields objectForKey:@"oauth_signature_method"],
                                    [oauthFields objectForKey:@"oauth_signature"]
                                ];
        
        [params setObject:credential forKey:@"verify_url"];
        
        [oaEngine release];
    }
    
    return params;
}

@end
