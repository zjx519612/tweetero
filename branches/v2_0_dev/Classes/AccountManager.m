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
#define SEC_ATTR_SERVER                 @"twitter.com"

static AccountManager *accountManager = nil;

@interface AccountManager (Private)
- (id)init;
- (NSString *)currentUserName;
- (int)currentUserIndex;
- (void)saveLastLoggedUser;
- (NSMutableDictionary *)prepareSecItemEntry:(NSString *)server user:(NSString *)userName;
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

- (NSMutableDictionary *)prepareSecItemEntry:(NSString *)server user:(NSString *)userName
{
    NSMutableDictionary *secItemEntry = [[NSMutableDictionary alloc] init];
    
    [secItemEntry setObject:(id)kSecClassInternetPassword forKey:(id)kSecClass];
    [secItemEntry setObject:server forKey:(id)kSecAttrServer];
    [secItemEntry setObject:userName forKey:(id)kSecAttrAccount];
    return [secItemEntry autorelease];
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
    NSMutableDictionary *secItemEntry = [self prepareSecItemEntry:SEC_ATTR_SERVER user:userName];
    
    [secItemEntry setObject:(id)kSecMatchLimitOne forKey:(id)kSecMatchLimit];
    [secItemEntry setObject:(id)kCFBooleanTrue forKey:(id)kSecReturnData];
    
    NSData *result = nil;
    OSStatus err = SecItemCopyMatching((CFDictionaryRef)secItemEntry, (CFTypeRef*)&result);
 
    NSString *password = nil;
    if (err == noErr && result)
        password = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];

    return [password autorelease];
}

- (void)addUser:(NSString *)userName password:(NSString *)password
{
    if (!userName || !password)
        return;
    
    if (([userName length] == 0) || ([password length]) == 0)
        return;
    
    NSData *passwordData = [password dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableDictionary *secItemEntry = [self prepareSecItemEntry:SEC_ATTR_SERVER user:userName];

    // Try update user data.
    OSStatus err = noErr;
    NSMutableDictionary *attrToUpdate = [[NSMutableDictionary alloc] init];
    
    [attrToUpdate setObject:passwordData forKey:(id)kSecValueData];
    err = SecItemUpdate((CFDictionaryRef)secItemEntry, (CFDictionaryRef)attrToUpdate);
    [attrToUpdate release];
    
    // Add new user data if update is failed.
    if (err != noErr)
    {
        [self removeUser:userName];
        
        [secItemEntry setObject:passwordData forKey:(id)kSecValueData];
        err = SecItemAdd((CFDictionaryRef)secItemEntry, NULL);

        // Save username
        if (err == noErr)
        {
            [_users addObject:userName];
            [[NSUserDefaults standardUserDefaults] setObject:_users forKey:ACCOUNT_MANAGER_KEY];
        }
    }
}

- (void)updateUser:(NSString *)userName newUserName:(NSString *)newUserName newPassword:(NSString *)password
{
    if (userName && newUserName && password)
    {
        if ([userName length] == 0 || [newUserName length] == 0 || [password length] == 0)
            return;
        
        NSMutableDictionary *secItemEntry = [self prepareSecItemEntry:SEC_ATTR_SERVER user:userName];
        
        if ([userName compare:newUserName] == NSOrderedSame)
        {
            // Update user data
            NSData *passwordData = [password dataUsingEncoding:NSUTF8StringEncoding];
            NSMutableDictionary *attrToUpdate = [[NSMutableDictionary alloc] init];
            
            [attrToUpdate setObject:passwordData forKey:(id)kSecValueData];
            SecItemUpdate((CFDictionaryRef)secItemEntry, (CFDictionaryRef)attrToUpdate);
            [attrToUpdate release];
        }
        else
        {
            // Delete old user and add new user data
            [self removeUser:userName];
            [self addUser:newUserName password:password];
        }
    }
}

- (void)removeUser:(NSString *)userName
{
    NSMutableDictionary *secItemEntry = [self prepareSecItemEntry:SEC_ATTR_SERVER user:userName];
    
    SecItemDelete((CFDictionaryRef)secItemEntry);
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
