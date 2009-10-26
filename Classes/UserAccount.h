//
//  UserAccount.h
//  Tweetero
//
//  Created by Sergey Shkrabak on 10/22/09.
//  Copyright 2009 Codeminders. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OAToken;

typedef enum {
    TwitterCommon,
    TwitterOAuth
} TwitterAuthType;

// Base account class
@interface UserAccount : NSObject
{
    NSString    *_username;
}
@property (nonatomic, copy) NSString *username;

- (TwitterAuthType)authType;

@end

// TwitterCommonUserAccount
@interface TwitterCommonUserAccount : UserAccount
{
    NSString    *_password;
}
@property (nonatomic, copy) NSString *password;
@end

// TwitterOAuthUserAccount
@interface TwitterOAuthUserAccount : UserAccount
{
    OAToken *_accessToken;
}
@property (nonatomic, retain) OAToken *accessToken;
@end