//
//  AccountManager.h
//  Tweetero
//
//  Created by Sergey Shkrabak on 9/15/09.
//  Copyright 2009 Codeminders. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kInvalidUserIndex   -1

@interface AccountManager : NSObject 
{
    NSMutableArray *_users;
    int _currentUserIndex;
}

+ (AccountManager *)manager;
+ (NSString *)loggedUserName;
+ (NSString *)loggedUserPassword;

- (NSUInteger)accountCount;
- (NSString *)userName:(NSUInteger)index;
- (NSString *)userPassword:(NSString *)userName;

// User data managament
- (void)addUser:(NSString *)userName password:(NSString *)password;
- (void)updateUser:(NSString *)userName newUserName:(NSString *)newUserName newPassword:(NSString *)password;
- (void)removeUser:(NSString *)userName;

// Login methods
- (void)login:(NSString *)userName;

@end
