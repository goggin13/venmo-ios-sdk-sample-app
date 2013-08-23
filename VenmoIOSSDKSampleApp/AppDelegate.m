
#import "AppDelegate.h"

// Braintree Sandbox testing environment
#define TEST_SANDBOX_BRAINTREE_KEY @"MIIBCgKCAQEA7zuPxt75mzMTfMqHb/1p/FOtdanLmN/GuGMDPGhz/t3ZaGZuI4BLpVPFTFwe086vMTMPh2NGpF6CZ6aPV3n3m5HoEm++yGTFE9/6n863gl4aszrJNWRWB68lYxB27fqDyk9QGBS95Kb03cieQbtqYS25zbc7P2XEOHv+XfypC5YjVMdTZjq1zzQ6wg6NZ7mpGCChhznjFXqm2uh3qM7MX0CsowWRFBHjTiJoRgTuNHwKp6mC3i8UDd1zJws94Oo87vpNVnFKVP2uqRyYrF4rlEw7CCDG8/llPDpK2ADBFBWyPK49F/8U5NZPLS7DqtuBN7Oq18SpcXczrcP1ZhBJSwIDAQAB"
#define TEST_SANDBOX_APP_ID @"t34jgpz7ktn4rsfm"

// Braintree Production testing environment, no keys here
#define TEST_PRODUCTION_BRAINTREE_KEY @"test_production_braintree_key"
#define TEST_PRODUCTION_APP_ID @"test_production_app_id"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    [self initVTClient];

    self.viewController = [[UIViewController alloc] init];
    self.viewController.view.backgroundColor = [UIColor lightGrayColor];

    UIButton *payButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    payButton.frame = CGRectMake(60, 100, 200, 60);
    [payButton setTitle:@"Pay" forState:UIControlStateNormal];
    [payButton addTarget:self action:@selector(paymentButtonTapped)
        forControlEvents:UIControlEventTouchUpInside];
    [self.viewController.view addSubview:payButton];

    UIButton *restartButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    restartButton.frame = CGRectMake(100, 300, 120, 44);
    [restartButton setTitle:@"Restart" forState:UIControlStateNormal];
    [restartButton addTarget:self action:@selector(restartButtonTapped)
        forControlEvents:UIControlEventTouchUpInside];
    [self.viewController.view addSubview:restartButton];

    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void) initVTClient {
    if ([BT_ENVIRONMENT isEqualToString:@"sandbox"]) {
        [VTClient
         startWithMerchantID:TEST_SANDBOX_APP_ID
         customerEmail:nil
         braintreeClientSideEncryptionKey:TEST_SANDBOX_BRAINTREE_KEY
         environment:VTEnvironmentSandbox];
    } else {
        [VTClient
         startWithMerchantID:TEST_PRODUCTION_BRAINTREE_KEY
         customerEmail:nil
         braintreeClientSideEncryptionKey:TEST_PRODUCTION_APP_ID
         environment:VTEnvironmentProduction];
    }
}

// Show a BTPaymentViewController
- (void)paymentButtonTapped {
    // Create a payment form.
    self.paymentViewController =
    [BTPaymentViewController paymentViewControllerWithVenmoTouchEnabled:YES];
    self.paymentViewController.delegate = self;

    // Add it to a navigation controller (for styling).
    UINavigationController *paymentNavigationController =
    [[UINavigationController alloc] initWithRootViewController:self.paymentViewController];

    // Add the cancel button
    self.paymentViewController.navigationItem.leftBarButtonItem =
    [[UIBarButtonItem alloc]
     initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:paymentNavigationController
     action:@selector(dismissModalViewControllerAnimated:)]; // requires iOS5+

    // Present the payment form.
    if ([self.viewController respondsToSelector:@selector(presentViewController:animated:completion:)]) {
        [self.viewController presentViewController:paymentNavigationController animated:YES completion:nil];
    } else {
        [self.viewController presentModalViewController:paymentNavigationController animated:YES];
    }
}

// Only works in VTEnvironmentSandbox - restarts the user on this device so she can add new cards from a clean plate
- (void)restartButtonTapped {
    [[VTClient sharedVTClient] restartSession];
}

// Easter egg! Shake to choose a random color of the Venmo Touch button (if it's being displayed)
- (void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if(event.type == UIEventSubtypeMotionShake) {
        BTPaymentViewController *paymentViewController = [[((UINavigationController *)[self.viewController presentedViewController]) viewControllers] objectAtIndex:0];

        if (paymentViewController
            && [[VTClient sharedVTClient] paymentMethodOptionStatus] == VTPaymentMethodOptionStatusYes) {
            
            CGFloat red   = arc4random_uniform(256);
            CGFloat green = arc4random_uniform(256);
            CGFloat blue  = arc4random_uniform(256);
            paymentViewController.vtCardViewBackgroundColor =
            [UIColor colorWithRed:red/255.0f green:green/255.0f blue:blue/255.0f alpha:1];
            NSLog(@"Easter egg! New random color -- red:%f, green:%f, blue:%f", red, green, blue);
        }
    }
}

#pragma mark - BTPaymentViewControllerDelegate

- (void)paymentViewController:(BTPaymentViewController *)paymentViewController
        didSubmitCardWithInfo:(NSDictionary *)cardInfo
         andCardInfoEncrypted:(NSDictionary *)cardInfoEncrypted {
    [self savePaymentInfoToServer:cardInfoEncrypted withURLName:@"/card/add"];
}

- (void)paymentViewController:(BTPaymentViewController *)paymentViewController didAuthorizeCardWithPaymentMethodCode:(NSString *)paymentMethodCode {
    [self savePaymentInfoToServer:[NSDictionary dictionaryWithObject:paymentMethodCode forKey:@"payment_method_code"]
                      withURLName:@"/card/payment_method_code"];
}



// Networking code borrowed from here and modified for different url/parameter naming.
// https://github.com/braintree/braintree_ios/blob/master/braintree/SampleCheckout/SCViewController.m#L86
#pragma mark - Networking

#define SAMPLE_CHECKOUT_BASE_URL @"http://venmo-sdk-sample-two.herokuapp.com"

- (void)savePaymentInfoToServer:(NSDictionary *)paymentInfo withURLName:(NSString *)urlName {
    NSURL *url = [NSURL URLWithString: [NSString stringWithFormat:@"%@%@", SAMPLE_CHECKOUT_BASE_URL, urlName]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];

    // TODO: Send a customer id in order to save a card to the Braintree vault.

    request.HTTPBody = [self postDataFromDictionary:paymentInfo];
    request.HTTPMethod = @"POST";

    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *body, NSError *requestError)
     {
         NSError *err = nil;
         if (!response && requestError) {
             NSLog(@"requestError: %@", requestError);
            [self.paymentViewController showErrorWithTitle:@"Error" message:@"Unable to reach the network."];
             return;
         }
         
         NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:body options:kNilOptions error:&err];
//         NSLog(@"saveCardToServer: paymentInfo: %@ response: %@, error: %@", paymentInfo, responseDictionary, requestError);

         if ([[responseDictionary valueForKey:@"success"] isEqualToNumber:@1]) { // Success!
             // Don't forget to call the cleanup method,
             // `prepareForDismissal`, on your `BTPaymentViewController`
             [self.paymentViewController prepareForDismissal];
             
             // Now you can dismiss and tell the user everything worked.
             [self.viewController dismissViewControllerAnimated:YES completion:^(void) {
                 [[[UIAlertView alloc] initWithTitle:@"Success" message:@"Saved your card!" delegate:nil
                                   cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
             }];
             [[VTClient sharedVTClient] refresh];

         } else {
             // The card did not save correctly, so show the error from server with convenenience method `showErrorWithTitle`
             [self.paymentViewController showErrorWithTitle:@"Error saving your card" message:[self messageStringFromResponse:responseDictionary]];
         }
     }];
}

// Some boiler plate networking code below.

- (NSString *) messageStringFromResponse:(NSDictionary *)responseDictionary {
    return [responseDictionary valueForKey:@"message"];
}

// Construct URL encoded POST data from a dictionary
- (NSData *)postDataFromDictionary:(NSDictionary *)params {
    NSMutableString *data = [NSMutableString string];

    for (NSString *key in params) {
        NSString *value = [params objectForKey:key];
        if (value == nil) {
            continue;
        }
        if ([value isKindOfClass:[NSString class]]) {
            value = [self URLEncodedStringFromString:value];
        }

        [data appendFormat:@"%@=%@&", [self URLEncodedStringFromString:key], value];
    }

    return [data dataUsingEncoding:NSUTF8StringEncoding];
}

// This method is adapted from from Dave DeLong's example at
// http://stackoverflow.com/questions/3423545/objective-c-iphone-percent-encode-a-string ,
// and protected by http://creativecommons.org/licenses/by-sa/3.0/
- (NSString *) URLEncodedStringFromString: (NSString *)string {
    NSMutableString * output = [NSMutableString string];
    const unsigned char * source = (const unsigned char *)[string UTF8String];
    int sourceLen = strlen((const char *)source);
    for (int i = 0; i < sourceLen; ++i) {
        const unsigned char thisChar = source[i];
        if (thisChar == ' '){
            [output appendString:@"+"];
        } else if (thisChar == '.' || thisChar == '-' || thisChar == '_' || thisChar == '~' ||
                   (thisChar >= 'a' && thisChar <= 'z') ||
                   (thisChar >= 'A' && thisChar <= 'Z') ||
                   (thisChar >= '0' && thisChar <= '9')) {
            [output appendFormat:@"%c", thisChar];
        } else {
            [output appendFormat:@"%%%02X", thisChar];
        }
    }
    return output;
}

@end
