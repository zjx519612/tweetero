#import <UIKit/UIKit.h>

@interface AccountController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate>
{
    IBOutlet UITableView *_tableAccounts;
}

- (id)init;

// Actions
- (IBAction)clickAdd;
- (IBAction)clickEdit;

+ (void)showAccountController:(UINavigationController*)navigationController;

@end
