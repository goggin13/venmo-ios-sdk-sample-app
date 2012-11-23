#import <UIKit/UIKit.h>
#import "VDKClient.h"

@interface TableViewController : UITableViewController <VDKClientDelegate>

@property (strong, nonatomic) VDKClient *vdkClient;

- (void)refreshVDKClient;
- (void)paymentMethodFound;
- (void)logoutVenmoSDK;

@end
