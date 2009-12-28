// Copyright (c) 2009 Imageshack Corp.
// All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
// 1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
// 3. The name of the author may not be used to endorse or promote products
//    derived from this software without specific prior written permission.
// 
// THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
// IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
// OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
// IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
// NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
// THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
// 

#import "LoginController.h"
#import "WebViewController.h"
#import "UserAccount.h"

#include "config.h"

#define AccountSegmentIndex     0
#define OAuthSegmentIndex       1

const NSString *kNewAccountLoginDataKey = @"newAccount";
const NSString *kOldAccountLoginDataKey = @"oldAccount";

const NSString *LoginControllerAccountDidChange = @"LoginControllerAccountDidChange";

@implementation LoginController

- (id)init
{
    if (self = [super initWithNibName:@"Login" bundle:nil])
    {
        _currentAccount = nil;
        oAuthAuthorization = NO;
    }
    return self;
}

- (id)initWithUserAccount:(UserAccount*)account
{
    if (self = [self init])
    {
        _currentAccount = [account retain];
    }
    return self;
}

- (void)dealloc
{
    [_currentAccount release];
    [super dealloc];
}

- (IBAction)cancel:(id)sender 
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)login:(id)sender 
{
    // Create new UserAccount object and send it as parameter of notification
    //TwitterCommonUserAccount *newAccount = [[TwitterCommonUserAccount alloc] init];
    UserAccount *newAccount = [[UserAccount alloc] init];

    newAccount.username = [loginField text];
    newAccount.secretData = [passwordField text];
    //newAccount.password = [passwordField text];
    
    // Notification parameters
    NSDictionary *loginData = [NSDictionary dictionaryWithObjectsAndKeys: newAccount, kNewAccountLoginDataKey, _currentAccount, kOldAccountLoginDataKey, nil];
    [newAccount release];
    
    // Post LoginControllerAccountDidChange notifiaction
    [[NSNotificationCenter defaultCenter] postNotificationName: (NSString *)LoginControllerAccountDidChange 
                                                        object: nil
                                                      userInfo: loginData];
    
    // Pop self controller from navigation bar
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)changeAuthTypeClick:(id)sender
{
    UISegmentedControl *segmentSender = (UISegmentedControl*)sender;
    
    if (segmentSender)
    {
        // Select authentification via login/password.
        if (segmentSender.selectedSegmentIndex == AccountSegmentIndex)
        {
            self.view = accountView;
            self.navigationItem.rightBarButtonItem.enabled = YES;
        }
        // Selecte authentification via OAuth. Load twitter.com in inapp web browser.
        else if (segmentSender.selectedSegmentIndex == OAuthSegmentIndex)
        {
            self.view = oAuthView;
            self.navigationItem.rightBarButtonItem.enabled = NO;
        }
    }
}

- (IBAction)oAuthOKClick
{
    SA_OAuthTwitterEngine *engine = [[SA_OAuthTwitterEngine alloc] initOAuthWithDelegate: self];
    
    engine.consumerKey = kTweeteroConsumerKey;
    engine.consumerSecret = kTweeteroConsumerSecret;
    
    [engine requestRequestToken];
    
    SA_OAuthTwitterController *oAuthController = [SA_OAuthTwitterController controllerToEnterCredentialsWithTwitterEngine:engine delegate:self];
    
    if (oAuthController)
        [self.navigationController pushViewController:oAuthController animated:YES];
    else
		[engine sendUpdate: [NSString stringWithFormat: @"Already Updated. %@", [NSDate date]]];
}

- (void)viewDidLoad 
{
    [super viewDidLoad];
    
    accountView = self.view;
    
 	self.navigationItem.rightBarButtonItem = loginButton;
    self.navigationItem.leftBarButtonItem = cancelButton;
    self.navigationItem.titleView = authTypeSegment;
    
    if (_currentAccount)
    {
        [loginField setText:_currentAccount.username];
        [passwordField setText:@""];
        [rememberSwitch setOn: NO];
    }
    
    self.navigationItem.leftBarButtonItem = nil;
    
	UIImage *icon = [UIImage imageNamed:@"Frog.tiff"];
	if(icon)
		[iconView setImage:icon];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (_currentAccount)
    {
        UISegmentedControl *seg = authTypeSegment;
        
        [seg setSelectedSegmentIndex:_currentAccount.authType];
        [self changeAuthTypeClick:seg];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (oAuthAuthorization)
        [self.navigationController popToRootViewControllerAnimated:YES];
}
#pragma mark -
#pragma mark <UITextFieldDelegate> Methods
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];
    return YES;
}

#pragma mark OAuth delegate
- (void) storeCachedTwitterOAuthData: (NSString *) data forUsername: (NSString *) username 
{
    UserAccount *newAccount = [[UserAccount alloc] init];
    
    newAccount.username = username;
    newAccount.secretData = data;
    newAccount.authType = TwitterAuthOAuth;
    
    // Notification parameters
    NSDictionary *loginData = [NSDictionary dictionaryWithObjectsAndKeys: newAccount, kNewAccountLoginDataKey, _currentAccount, kOldAccountLoginDataKey, nil];
    [newAccount release];
    
    // Post LoginControllerAccountDidChange notifiaction
    [[NSNotificationCenter defaultCenter] postNotificationName: (NSString *)LoginControllerAccountDidChange 
                                                        object: nil
                                                      userInfo: loginData];
    [self.navigationController popViewControllerAnimated:YES];
    oAuthAuthorization = YES;
}

- (NSString *) cachedTwitterOAuthDataForUsername: (NSString *) username 
{
    if (_currentAccount)
        return [_currentAccount secretData];
    return nil;
}


@end
