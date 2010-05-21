#import "AccountController.h"
#import "TwActivityIndicator.h"
#import "LoginController.h"
#import "AccountManager.h"
#import "UserAccount.h"
#import "MGTwitterEngineFactory.h"
#import "TwTabController.h"
#include "util.h"

@interface AccountController(Private)
- (void)saveAccountNotification:(NSNotification*)notification;
- (void)showTabController;
- (void)verifySelectedAccount;
- (void)closeAndReleaserTwitter;
- (void)showActivityWithLabel:(NSString*)message;
- (void)hideCurrentActivity;
@end

@implementation AccountController

@synthesize canAnimate = _canAnimate;
@synthesize accountManager = _manager;
@synthesize _tableAccounts;

+ (void)showAccountController:(UINavigationController*)navigationController
{
    [navigationController popToRootViewControllerAnimated:YES];
}

- (id)init
{
    // Call init method from super class
    if ((self = [super initWithNibName:@"AccountController" bundle:nil]))
    {
        UIBarButtonItem *button = nil;
        
        // Create left and right buttons on navigation controller.
        // Add button.
        button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(clickAdd)];
        self.navigationItem.rightBarButtonItem = button;
        [button release];
        
        // Edit button
        button = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Edit", @"") style:UIBarButtonItemStyleBordered target:self action:@selector(clickEdit)];
        self.navigationItem.leftBarButtonItem = button;
        [button release];
        
        self.navigationItem.title = NSLocalizedString(@"Accounts", @"");
        self.canAnimate = YES;
        
        _tableAccounts = nil;
        _manager = nil;
		_activity = nil;
		_shouldShowTabControllerOnAutoLogin = YES;
        
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(saveAccountNotification:) 
                                                     name:(NSString*)LoginControllerAccountDidChange 
                                                   object:nil];
    }
    return self;
}

- (id)initWithManager:(AccountManager*)manager
{
    if (self = [self init])
    {
        _manager = [manager retain];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_tableAccounts release];
    [_manager release];
	[_loginController release];
    [self closeAndReleaserTwitter];
	
    if (_activity)
        [_activity release];
	[_tableAccounts release];
	_tableAccounts = nil;
	
    [super dealloc];
}

- (void)viewDidAppear:(BOOL)animated
{
    self.canAnimate = YES;
    self.navigationItem.rightBarButtonItem.enabled = YES;
    self.navigationItem.leftBarButtonItem.enabled = [self.accountManager hasAccounts];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self hideCurrentActivity];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [self closeAndReleaserTwitter];
}

- (void)viewDidLoad
{
    if (_tableAccounts)
        [_tableAccounts reloadData];

    if (self.accountManager.loggedUserAccount && _shouldShowTabControllerOnAutoLogin)
    {
        self.canAnimate = NO;
		_shouldShowTabControllerOnAutoLogin = NO;
        [self showTabController];
    }
}

- (void)startIndicator
{
    [self showActivityWithLabel:NSLocalizedString(@"Goto twitter.com", @"")];
}

#pragma mark Actions
// Create LoginController and push it to navigation controller.
- (IBAction)clickAdd
{
	if (nil != _loginController)
	{
		[_loginController release];
		_loginController = nil;
	}

    [NSThread detachNewThreadSelector:@selector(startIndicator) toTarget:self withObject:nil];
    
	_loginController = [[LoginController alloc] init];
	[_loginController showOAuthViewInController:self.navigationController];
    
    [self hideCurrentActivity];
}

- (IBAction)clickEdit
{
    if (_tableAccounts.editing)
    {
        [_tableAccounts setEditing:NO];
        self.navigationItem.leftBarButtonItem.title = NSLocalizedString(@"Edit", @"");
        self.navigationItem.rightBarButtonItem.enabled = YES;
        self.navigationItem.title = NSLocalizedString(@"Accounts", @"");
    }
    else
    {
        [_tableAccounts setEditing:YES];
        self.navigationItem.leftBarButtonItem.title = NSLocalizedString(@"Back", @"");
        self.navigationItem.rightBarButtonItem.enabled = NO;
        self.navigationItem.title = NSLocalizedString(@"Edit Mode", @"");
    }
    return;
}

#pragma mark UIActionSheet Delegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSIndexPath *index = [_tableAccounts indexPathForSelectedRow];
    UITableViewCell *cell = [_tableAccounts cellForRowAtIndexPath:index];
    
    UserAccount *account = [self.accountManager accountByUsername:cell.textLabel.text];
    
    if (buttonIndex == 0)
    {
        // Remove selected account
        [self.accountManager removeAccount:account];
    }
    else if (buttonIndex == 1)
    {
        // Edit selected account. Navigate LoginController with account data.
		if (nil != _loginController)
		{
			[_loginController release];
			_loginController = nil;
		}
		_loginController = [[LoginController alloc] initWithUserAccount:account];
		[_loginController showOAuthViewInController:self.navigationController];
    }
    [_tableAccounts reloadData];
}

#pragma mark UITableView DataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([self.accountManager hasAccounts])
        return [[self.accountManager allAccountUsername] count];
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *kCellIdentifier = @"AccountCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
    
    if (cell == nil)
        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:kCellIdentifier] autorelease];
    
    if ([self.accountManager hasAccounts]) {
        cell.textLabel.text = [[self.accountManager allAccountUsername] objectAtIndex:indexPath.row];
        cell.textLabel.font = [UIFont boldSystemFontOfSize:24];
        cell.textLabel.textAlignment = UITextAlignmentLeft;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
        cell.textLabel.text = NSLocalizedString(@"Please, add one or more accounts.", @"");
        cell.textLabel.font = [UIFont systemFontOfSize:16];
        cell.textLabel.textAlignment = UITextAlignmentCenter;
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

#pragma mark UITableView Delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!tableView.editing)
    {
        if ([self.accountManager hasAccounts])
        {
            NSIndexPath *index = [_tableAccounts indexPathForSelectedRow];
            UITableViewCell *cell = [_tableAccounts cellForRowAtIndexPath:index];
            UserAccount *account = [self.accountManager accountByUsername:cell.textLabel.text];
            
            self.navigationItem.rightBarButtonItem.enabled = NO;
            self.navigationItem.leftBarButtonItem.enabled = NO;
            // Login with user
            [self.accountManager login:account];
            [self verifySelectedAccount];
        }
    }
    else
    {
        // Show alert
        UIActionSheet *action = [[UIActionSheet alloc] initWithTitle: nil
                                                            delegate: self 
                                                   cancelButtonTitle: NSLocalizedString(@"Cancel", @"")
                                              destructiveButtonTitle: NSLocalizedString(@"Delete", @"")
                                                   otherButtonTitles: NSLocalizedString(@"Change", @""), nil];
        [action showInView:self.view];
        [action release];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return (UITableViewCellEditingStyleDelete | UITableViewCellEditingStyleInsert);
}

@end

@implementation AccountController(Private)

- (void)saveAccountNotification:(NSNotification*)notification
{
    NSDictionary *loginData = (NSDictionary*)[notification userInfo];
    
    UserAccount *newAccount = [loginData objectForKey:kNewAccountLoginDataKey];
    UserAccount *oldAccount = [loginData objectForKey:kOldAccountLoginDataKey];
    
    if (newAccount)
    {
        if (oldAccount)
            [self.accountManager replaceAccount:oldAccount with:newAccount];
        else
            [self.accountManager saveAccount:newAccount];
        
        [_tableAccounts reloadData];
    }
}

- (void)showTabController
{
    // Navigate tab controller
    TwTabController *tab = [[TwTabController alloc] init];
    [self.navigationController pushViewController:tab animated:self.canAnimate];
    [tab release];
}

- (void)verifySelectedAccount
{
    [self closeAndReleaserTwitter];
    _twitter = [[MGTwitterEngineFactory createTwitterEngineForCurrentUser:self] retain];
    
    _credentialIdentifier = [_twitter checkUserCredentials];
}

- (void)closeAndReleaserTwitter
{
    if (_twitter) {
        [_twitter closeAllConnections];
        [_twitter release];
        _twitter = nil;
    }
}

- (void)showActivityWithLabel:(NSString*)message
{
    if (!_activity)
    {
        _activity = [[TwActivityIndicator alloc] init];
    }
    [_activity.messageLabel setText:message];
    [_activity show];
}

- (void)hideCurrentActivity
{
    if (_activity)
        [_activity hide];
}

#pragma mark MGTwitterEngine delegate methods
- (void)requestSucceeded:(NSString *)connectionIdentifier
{
    if ([connectionIdentifier isEqualToString:_credentialIdentifier])
        [self showTabController];
    _credentialIdentifier = nil;
    self.navigationItem.rightBarButtonItem.enabled = YES;
    self.navigationItem.leftBarButtonItem.enabled = YES;
}

- (void)requestFailed:(NSString *)connectionIdentifier withError:(NSError *)error
{
    UIAlertView *theAlert = CreateAlertWithError(error);
    [theAlert show];
    [theAlert release];
    
    _credentialIdentifier = nil;
    
    self.navigationItem.rightBarButtonItem.enabled = YES;
    self.navigationItem.leftBarButtonItem.enabled = YES;
}

@end