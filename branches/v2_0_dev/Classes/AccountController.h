#import <UIKit/UIKit.h>

@interface AccountController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate>
{
@private
    BOOL canAnimate;
    IBOutlet UITableView *_tableAccounts;
}

@property (nonatomic) BOOL canAnimate;

- (id)init;

// Actions
- (IBAction)clickAdd;
- (IBAction)clickEdit;

+ (void)showAccountController:(UINavigationController*)navigationController;

@end
