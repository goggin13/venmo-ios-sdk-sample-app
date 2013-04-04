#import <UIKit/UIKit.h>
#import <VenmoTouch/VenmoTouch.h>
#import "BTPaymentViewController.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, BTPaymentViewControllerDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UIViewController *viewController;
@property (strong, nonatomic) BTPaymentViewController *paymentViewController;

@end
