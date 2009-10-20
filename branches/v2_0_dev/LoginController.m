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
#import "MGTwitterEngine.h"
#import "WebViewController.h"

@implementation LoginController

- (id)init
{
    if ((self = [super initWithNibName:@"Login" bundle:nil]))
    {
        _currentUsername = nil;
        _currentPassword = nil;
    }
    return self;
}

- (id)initWithUserData:(NSString *)userName password:(NSString *)password
{
    if ((self = [self init]))
    {
        _currentUsername = [userName retain];
        _currentPassword = [password retain];
    }
    return self;
}

- (void)dealloc
{
    if (_currentUsername)
        [_currentUsername release];
    if (_currentPassword)
        [_currentPassword release];
    [super dealloc];
}

- (IBAction)cancel:(id)sender 
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)login:(id)sender 
{
    NSString *login = [loginField text];
	NSString *password = [passwordField text];
	
	[MGTwitterEngine setUsername:login password:password remember:[rememberSwitch isOn]];
    
    NSDictionary *userInfoDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                                login, @"login", password, @"password",
                                                _currentUsername, @"old_login", _currentPassword, @"old_password",
                                                nil];
    [[NSNotificationCenter defaultCenter] postNotificationName: @"AccountDataChanged" 
                                                        object: nil
                                                      userInfo: userInfoDict];
    [self.navigationController popViewControllerAnimated:YES];
}

#define AccountSegmentIndex     0
#define OAuthSegmentIndex       1

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
    NSURLRequest *twitterUrlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://twitter.com"]];
    
    OAuthWebController *web = [[OAuthWebController alloc] initWithRequest:twitterUrlRequest];
    [self.navigationController pushViewController:web animated:YES];
    [web release];
}

- (void)viewDidLoad 
{
    [super viewDidLoad];
    
    accountView = self.view;
    
 	self.navigationItem.rightBarButtonItem = loginButton;
    self.navigationItem.leftBarButtonItem = cancelButton;
    self.navigationItem.titleView = authTypeSegment;
    
    [loginField setText:_currentUsername];
    [passwordField setText:_currentPassword];
	[rememberSwitch setOn: NO];
	
	UIImage *icon = [UIImage imageNamed:@"Frog.tiff"];
	if(icon)
		[iconView setImage:icon];
}

#pragma mark -
#pragma mark <UITextFieldDelegate> Methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];
    return YES;
}

@end
