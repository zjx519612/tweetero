#import "AccountController.h"
#import "TabController.h"
#import "LoginController.h"
#import "MGTwitterEngine.h"
#import "AccountManager.h"

@interface AccountController (Private)

- (void)saveAccountNotification:(NSNotification*)notification;
- (void)showTabController;

@end

@implementation AccountController (Private)

- (void)saveAccountNotification:(NSNotification*)notification
{
    NSLog(@"saveAccountNotification Handler\n");
    
    NSDictionary *userInfo = (NSDictionary *)[notification userInfo];
    NSString *userName = [userInfo objectForKey:@"login"];
    NSString *userPassword = [userInfo objectForKey:@"password"];
    NSString *oldPassword = [userInfo objectForKey:@"old_password"];
    NSString *oldUserName = [userInfo objectForKey:@"old_login"];
    
    NSLog(@"userName = %@, userPassword = %@, oldUserName = %@, oldUserPassword = %@\n", userName, userPassword, oldUserName, oldPassword);
    if (userName)
    {
        if (oldPassword == nil && oldUserName == nil)
            [[AccountManager manager] addUser:userName password:userPassword];
        else
            [[AccountManager manager] updateUser:oldUserName newUserName:userName newPassword:userPassword];
        [_tableAccounts reloadData];
    }
    NSLog(@"end handler");
}

- (void)showTabController
{
    // Navigate tab controller
    TabController *controller = [[TabController alloc] init];
    [self.navigationController pushViewController:controller animated:YES];
    [controller release];
}

@end

@implementation AccountController

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
        button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(clickEdit)];
        self.navigationItem.leftBarButtonItem = button;
        [button release];
        
        self.navigationItem.title = NSLocalizedString(@"Accounts", @"");
        _tableAccounts = nil;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveAccountNotification:) name:@"AccountDataChanged" object:nil];
    }
    return self;
}
        
- (void)dealloc
{
    [_tableAccounts release];
    [super dealloc];
}

//#define LOGIN_DEBUG 1

- (void)viewDidLoad
{
    if (_tableAccounts)
        [_tableAccounts reloadData];

#ifndef LOGIN_DEBUG
    if ([AccountManager loggedUserName])
        [self showTabController];
#endif
}

#pragma mark Actions
/** 
 Create LoginController and push it to navigation controller.
 */
- (IBAction)clickAdd
{
    LoginController *controller = [[LoginController alloc] initWithNibName:@"Login" bundle:nil];
    [self.navigationController pushViewController:controller animated:YES];
    [controller release];
}

/** 
 Create LoginController with selected account data and push it to nvaigation controller.
 */
- (IBAction)clickEdit
{
    [_tableAccounts setEditing:!_tableAccounts.editing];
    return;
}

#pragma mark UIActionSheet Delegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSIndexPath *index = [_tableAccounts indexPathForSelectedRow];
    NSString *userName = [[AccountManager manager] userName:index.row];
    
    switch (buttonIndex)
    {
        // Delete
        case 0:
        {
            [[AccountManager manager] removeUser:userName];
            break;
        }
        
        // Change
        case 1:
        {
            NSString *password = [[AccountManager manager] userPassword:userName];
            
            LoginController *controller = [[LoginController alloc] initWithUserData:userName password:password];
            [self.navigationController pushViewController:controller animated:YES];
            [controller release];
            break;
        }   
        // Cancel
        case 2:
            break;
    }
    [_tableAccounts setEditing:NO];
    [_tableAccounts reloadData];
}

#pragma mark UITableView DataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = [[AccountManager manager] accountCount];
    NSLog(@"AccountController: numberOfRowsInSection = %i\n", count);
    
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"AccountController: cellForRowAtIndexPath\n");
    
    static NSString *kCellIdentifier = @"AccountCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
    
    if (cell == nil)
        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:kCellIdentifier] autorelease];
    
    cell.textLabel.text = [[AccountManager manager] userName:indexPath.row];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    NSLog(@"textLabel.text = %@\n", cell.textLabel.text);
    NSLog(@"AccountController: finish cellForRowAtIndexPath\n");
    
    return cell;
}

#pragma mark UITableView Delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!tableView.editing)
    {
        NSString *userName = [[AccountManager manager] userName:indexPath.row];
        
        // Login with user
        [[AccountManager manager] login:userName];
        [self showTabController];
    }
    else
    {
        // Show alert
        UIActionSheet *action = [[UIActionSheet alloc] initWithTitle: nil
                                                            delegate: self 
                                                   cancelButtonTitle: @"Cancel" 
                                              destructiveButtonTitle: @"Delete" 
                                                   otherButtonTitles: @"Change", nil];
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