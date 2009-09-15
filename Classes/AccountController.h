#import <UIKit/UIKit.h>

@interface AccountController : UIViewController <UITableViewDataSource, UITableViewDelegate>
{
    IBOutlet UITableView *_tableAccounts;
}

- (id)init;

// Actions
- (IBAction)clickAdd;
- (IBAction)clickEdit;

@end
