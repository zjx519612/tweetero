//
//  AccountManager.m
//  Tweetero
//
//  Created by Sergey Shkrabak on 9/15/09.
//  Copyright 2009 Codeminders. All rights reserved.
//

#import "AccountManager.h"
#import "MGTwitterEngine.h"

#define ACCOUNT_MANAGER_KEY             @"Accounts"
#define ACCOUNT_MANAGER_LAST_USER_KEY   @"AccountLastUser"

static AccountManager *accountManager = nil;

@interface AccountManager (Private)
- (id)init;
- (NSString *)currentUserName;
- (int)currentUserIndex;
- (void)saveLastLoggedUser;
@end

@implementation AccountManager (Private)

- (id)init
{
    if ((self = [super init]))
    {
        NSArray *accounts = [[NSUserDefaults standardUserDefaults] arrayForKey:ACCOUNT_MANAGER_KEY];
        _users = [[NSMutableArray alloc] initWithArray:accounts];
        _currentUserIndex = kInvalidUserIndex;
        
        NSString *userName = [[NSUserDefaults standardUserDefaults] stringForKey:ACCOUNT_MANAGER_LAST_USER_KEY];
        [self login:userName];
    }
    return self;
}

- (NSString *)currentUserName
{
    return (_currentUserIndex < 0) ? nil : [_users objectAtIndex:_currentUserIndex];
}

- (int)currentUserIndex
{
    return _currentUserIndex;
}

- (void)saveLastLoggedUser
{
    NSString *userName = [self currentUserName];
    [[NSUserDefaults standardUserDefaults] setObject:userName forKey:ACCOUNT_MANAGER_LAST_USER_KEY];
}

@end

@implementation AccountManager

+ (AccountManager *)manager
{
    if (!accountManager)
        accountManager = [[AccountManager alloc] init];
    return accountManager;
}

+ (NSString *)loggedUserName
{
    if (![AccountManager manager])
        return nil;
    return [[AccountManager manager] currentUserName];
}

+ (NSString *)loggedUserPassword
{
    NSString *userName = [AccountManager loggedUserName];
    if (!userName)
        return nil;
    return [[AccountManager manager] userPassword:userName];
}

- (void)dealloc
{
    [_users release];
    [super dealloc];
}

- (NSUInteger)accountCount
{
    return [_users count];
}

- (NSString *)userName:(NSUInteger)index
{
    return [_users objectAtIndex:index];
}

- (NSString *)userPassword:(NSString *)userName
{
    NSString *password = nil;
    
    NSMutableDictionary *secItemEntry = [[NSMutableDictionary alloc] init];
    
    [secItemEntry setObject:(id)kSecClassInternetPassword forKey:(id)kSecClass];
    [secItemEntry setObject:@"twitter.com" forKey:(id)kSecAttrServer];
    [secItemEntry setObject:userName forKey:(id)kSecAttrAccount];
    [secItemEntry setObject:(id)kSecMatchLimitOne forKey:(id)kSecMatchLimit];
    [secItemEntry setObject:(id)kCFBooleanTrue forKey:(id)kSecReturnData];
    
    NSData *result;
    OSStatus err = SecItemCopyMatching((CFDictionaryRef)secItemEntry, (CFTypeRef*)&result);
    
    if (err == noErr && result)
        password = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
    
    [secItemEntry release];
    
    return [password autorelease];
}

- (NSString *)saveUser:(NSString *)userName password:(NSString *)password
{
    [_users addObject:userName];
    [[NSUserDefaults standardUserDefaults] setObject:_users forKey:ACCOUNT_MANAGER_KEY];

    NSData *passwordData = [password dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableDictionary *secItemEntry = [[NSMutableDictionary alloc] init];
    
    [secItemEntry setObject:(id)kSecClassInternetPassword forKey:(id)kSecClass];
    [secItemEntry setObject:@"twitter.com" forKey:(id)kSecAttrServer];
    [secItemEntry setObject:userName forKey:(id)kSecAttrAccount];
    
    // Try update user data.
    OSStatus err = noErr;
    NSMutableDictionary *attrToUpdate = [[NSMutableDictionary alloc] init];
    
    [attrToUpdate setObject:passwordData forKey:(id)kSecValueData];
    err = SecItemUpdate((CFDictionaryRef)secItemEntry, (CFDictionaryRef)attrToUpdate);
    [attrToUpdate release];
    
    // Add new user data if update is failed.
    if (err != noErr)
    {
        SecItemDelete((CFDictionaryRef)secItemEntry);
        [secItemEntry setObject:passwordData forKey:(id)kSecValueData];
        SecItemAdd((CFDictionaryRef)secItemEntry, NULL);
    }
    [secItemEntry release];
    
    return userName;
}

- (void)removeUser:(NSString *)userName
{
    [_users removeObject:userName];
    [[NSUserDefaults standardUserDefaults] setObject:_users forKey:ACCOUNT_MANAGER_KEY];
}

- (void)login:(NSString *)userName
{
    if (userName)
    {
        NSUInteger index = [_users indexOfObject:userName];
        NSString *password = [self userPassword:userName];
        
        _currentUserIndex = kInvalidUserIndex;
        [MGTwitterEngine setUsername:userName password:password remember:NO];
        if ([MGTwitterEngine username] != nil && [MGTwitterEngine password] != nil)
            _currentUserIndex = index;
        
        [[NSNotificationCenter defaultCenter] postNotificationName: @"AccountChanged" 
                                                            object: nil
                                                          userInfo: [NSDictionary dictionaryWithObjectsAndKeys:userName, @"login", password, @"password", nil]];
        [self saveLastLoggedUser];
    }
}

@end
