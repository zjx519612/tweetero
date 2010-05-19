#import <UIKit/UIKit.h>

@class AccountManager, MGTwitterEngine, LoginController, TwActivityIndicator;

@interface AccountController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate>
{
@private
    BOOL                 _canAnimate;
	BOOL                 _shouldShowTabControllerOnAutoLogin;
	UITableView         *_tableAccounts;
    AccountManager      *_manager;
    MGTwitterEngine     *_twitter;
    NSString            *_credentialIdentifier;
	LoginController     *_loginController;
    TwActivityIndicator *_activity;
}

@property (nonatomic) BOOL canAnimate;
@property (nonatomic, readonly) AccountManager* accountManager;
@property (nonatomic, retain) IBOutlet UITableView *_tableAccounts;

- (id)init;

- (id)initWithManager:(AccountManager*)manager;

- (IBAction)clickAdd;

- (IBAction)clickEdit;

+ (void)showAccountController:(UINavigationController*)navigationController;

@end
