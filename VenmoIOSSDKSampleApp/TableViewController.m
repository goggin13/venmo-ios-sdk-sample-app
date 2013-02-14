#import "TableViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "MerchantAppVenmoSDKDefines.h"
#import "ActivityOverlayView.h"
#import "FSNConnection.h"

#define HEADER_FRAME        CGRectMake(0,   0, 320, 50)
#define HEADER_FRAME_HIDDEN CGRectMake(0, -50, 320, 50) // shake to hide the settings buttons

static NSString *WidgetCellIdentifier = @"WidgetCell";
static NSString *FormCellIdentifier = @"FormCell";
static NSString *CheckboxCellIdentifier = @"CheckboxCell";
static NSString *SubmitCellIdentifier = @"SubmitCell";

@interface TableViewController() {
    UIButton *restartButton;
    BOOL showsHeaderView;
    UIView *headerView;
    ActivityOverlayView *activityOverlayView;
}

@property (strong, nonatomic) VDKCardWidget *cardWidget;
@property (strong, nonatomic) VDKCheckboxWidget *checkboxWidget;

@property (strong, nonatomic) NSMutableArray *textFields;
@property (nonatomic, assign) BOOL hasPaymentMethods;

@end

@implementation TableViewController

@synthesize vdkClient;

@synthesize cardWidget;
@synthesize checkboxWidget;

@synthesize textFields;
@synthesize hasPaymentMethods;

#pragma mark - UITableViewController

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        self.title = NSLocalizedString(@"UITableViewController", nil);
    }
    return self;
}

#pragma mark - UIViewController

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = APP_COLOR;
    [self createHeaderView];

    // Set up card input form text fields
    textFields = [[NSMutableArray alloc] initWithCapacity:5];
    for (NSInteger i=0; i<5; i++) {
        UITextField *textField = [[UITextField alloc] initWithFrame:
                                  CGRectMake(10, 10, 180, 26)];
        textField.backgroundColor = [UIColor clearColor];
        textField.tag = 1337;
        textField.keyboardType = UIKeyboardTypeNumberPad;
        [textFields addObject:textField];
    }

    [self initVDKClient];

    showsHeaderView = YES;
    activityOverlayView = [ActivityOverlayView sharedOverlayView];
    [activityOverlayView.titleLabel setText:@"Purchasing..."];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self resignFirstResponder];
}

-(BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if(event.type == UIEventSubtypeMotionShake) {
        showsHeaderView = !showsHeaderView;
        UIView *newHeaderView = (showsHeaderView ? headerView : nil);
        CGRect newHeaderFrame = (showsHeaderView ? HEADER_FRAME : HEADER_FRAME_HIDDEN);

        if (showsHeaderView) {
            for (UITextField *textField in textFields) {
                textField.text = @"";
            }
        }

        [UIView animateWithDuration:.3 animations:^{
            self.tableView.tableHeaderView.frame = newHeaderFrame;
            self.tableView.tableHeaderView = newHeaderView;
        }];
    }
}

- (void)initVDKClient {
    vdkClient.delegate = nil;
    vdkClient = nil;

    vdkClient = [[VDKClient alloc] initWithMerchantID:SANDBOX_APP_ID
                         braintreePublicEncryptionKey:SANDBOX_BRAINTREE_KEY
                                       vdkEnvironment:VDKEnvironmentSandbox];
    vdkClient.delegate = self;

    hasPaymentMethods = NO;
    [cardWidget removeFromSuperview];
    cardWidget = nil;
    [checkboxWidget removeFromSuperview];
    checkboxWidget = nil;

    if (vdkClient) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    }
}

- (void)createHeaderView {
    headerView = [[UIView alloc] initWithFrame:HEADER_FRAME];
    headerView.backgroundColor = APP_COLOR;

    UILabel *merchantName = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, 100, 30)];
    merchantName.font = [UIFont boldSystemFontOfSize:26];
    merchantName.text = APP_NAME;
    merchantName.backgroundColor = [UIColor clearColor];
    merchantName.textColor = APP_TEXT_COLOR;
    merchantName.shadowOffset = CGSizeMake(0, 1);
    merchantName.shadowColor = APP_TEXT_SHADOW_COLOR;
    [headerView addSubview:merchantName];

    UIButton *refreshButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    refreshButton.frame = CGRectMake(90, 5, 70, 40);
    [refreshButton setTitle:@"Refresh" forState:UIControlStateNormal];
    [refreshButton addTarget:self action:@selector(refreshVDKClient)
            forControlEvents:UIControlEventTouchUpInside];
    [headerView addSubview:refreshButton];

    restartButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    restartButton.frame = CGRectMake(170, 5, 70, 40);
    [restartButton setTitle:@"Restart" forState:UIControlStateNormal];
    [restartButton addTarget:self action:@selector(logoutAndRestartVDKClient)
           forControlEvents:UIControlEventTouchUpInside];
    [headerView addSubview:restartButton];

    UIButton *prefillButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    prefillButton.frame = CGRectMake(250, 5, 60, 40);
    prefillButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [prefillButton setTitle:@"Prefill" forState:UIControlStateNormal];
    [prefillButton addTarget:self action:@selector(prefillAction)
            forControlEvents:UIControlEventTouchUpInside];
    [headerView addSubview:prefillButton];

    self.tableView.tableHeaderView = headerView;
}

- (void)refreshVDKClient {
    [vdkClient refresh];
    cardWidget = nil;
    hasPaymentMethods = NO;
    [self.tableView reloadData];
    if (vdkClient) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    }
    [self becomeFirstResponder];
}

- (void)logoutAndRestartVDKClient {
    [vdkClient restartSession];
    cardWidget = nil;
    hasPaymentMethods = NO;
    [self.tableView reloadData];
    if (vdkClient) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    }
    [self becomeFirstResponder];
}

- (void)paymentMethodFound {
    hasPaymentMethods = YES;

    [self.tableView insertSections:[NSIndexSet indexSetWithIndex:0]
                  withRowAnimation:UITableViewRowAnimationAutomatic];
    [self performSelector:@selector(reloadTitle) withObject:nil afterDelay:.3];
}

- (void)reloadTitle {
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:(hasPaymentMethods ? 1 : 0)]
                  withRowAnimation:UITableViewRowAnimationNone];
}

- (void)logoutVenmoSDK {
    if ([self.tableView numberOfSections] == 2) {
        hasPaymentMethods = NO;
        [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:0]
                      withRowAnimation:UITableViewRowAnimationAutomatic];
        [self performSelector:@selector(reloadTitle) withObject:nil afterDelay:.3];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return (hasPaymentMethods ? 2 : 1);
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (hasPaymentMethods && indexPath.section == 0) {
        return 81;
    } else if (indexPath.row == 5) {
        return 66;
    } else {
        return 44;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 40)];
    view.backgroundColor = APP_COLOR;
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 10, 280, 20)];
    titleLabel.backgroundColor = APP_COLOR;
    titleLabel.textColor = APP_TEXT_COLOR;
    titleLabel.font = [UIFont boldSystemFontOfSize:16];
    titleLabel.shadowOffset = CGSizeMake(0, 1);
    titleLabel.shadowColor = APP_TEXT_SHADOW_COLOR;
    [view addSubview:titleLabel];
    if (hasPaymentMethods && section == 0) {
        titleLabel.text = @"Select a card:";
    } else {
        titleLabel.text = (hasPaymentMethods ? @"OR, add a new card:" : @"Add a new card:");
    }
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 40;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (hasPaymentMethods && section == 0) {
        return 1;
    } else {
        return 7;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellIdentifier = WidgetCellIdentifier;
    if (((indexPath.section == 1 && hasPaymentMethods) || (indexPath.section == 0 && !hasPaymentMethods))
        && indexPath.row < 5) {
        cellIdentifier = FormCellIdentifier;
    } else if (indexPath.row == 5) {
        cellIdentifier = CheckboxCellIdentifier;
    } else if (indexPath.row == 6) {
        cellIdentifier = SubmitCellIdentifier;
    }

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:cellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }

    // Add text field, if need be.
    if ([cellIdentifier isEqualToString:FormCellIdentifier] &&
        ![cell.contentView viewWithTag:1337]) {
        [cell.contentView addSubview:[textFields objectAtIndex:indexPath.row]];
    }
    else if ([cellIdentifier isEqualToString:SubmitCellIdentifier] &&
             ![cell.contentView viewWithTag:1338]) {
        // Add the submit card button, if need be
        UIButton *submitButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        submitButton.frame = CGRectMake(5, 5, 290, 35);
        submitButton.tag = 1338;
        [submitButton setTitle:@"Submit" forState:UIControlStateNormal];
        [submitButton addTarget:self action:@selector(submitNewCard:)
               forControlEvents:UIControlEventTouchUpInside];
        [cell.contentView addSubview:submitButton];
    }

    UITextField *textField = (UITextField *)[cell.contentView viewWithTag:1337];
    if (textField) {
        if (indexPath.row == 0) {
            textField.placeholder = @"Number";
        } else if (indexPath.row == 1) {
            textField.placeholder = @"Expiration Month";
        } else if (indexPath.row == 2) {
            textField.placeholder = @"Expiration Year";
        } else if (indexPath.row == 3) {
            textField.placeholder = @"CVV";
        } else if (indexPath.row == 4) {
            textField.placeholder = @"Zip code";
        }
    }

    return cell;
}

- (void)setUpCardWidgetForCell:(UITableViewCell *)cell {
    if (!cardWidget) {
        cardWidget = [[VDKClient sharedClient] cardWidget];
    }

    if (cardWidget && cell) {
        [cardWidget setOrigin:CGPointMake(0, 0)];
        [cardWidget setBackgroundColor:[UIColor colorWithRed:245/255.0f green:245/255.0f
                                                        blue:245/255.0f alpha:1.0f]];
        [cardWidget setWidth:300];
        cardWidget.layer.cornerRadius = 8;    //round the corners
        cardWidget.layer.masksToBounds = YES;
        cardWidget.pictureHidden = YES;

        [cell.contentView addSubview:cardWidget];
    }
}

- (void)setUpCheckboxWidgetForCell:(UITableViewCell *)cell {
    if (!cell) {
        return;
    }

    if (!checkboxWidget) {
        checkboxWidget = [[VDKClient sharedClient] checkboxWidget];
        [checkboxWidget setOrigin:CGPointMake(0, 0)];
        [checkboxWidget setWidth:300];
        [checkboxWidget setBackgroundColor:[UIColor clearColor]];
        [checkboxWidget setTextColor:[UIColor grayColor]];
    }

    [cell.contentView addSubview:checkboxWidget];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {

    // Create and display the card widget, if possible
    if (hasPaymentMethods && indexPath.section == 0) {
        [self setUpCardWidgetForCell:cell];
        return;
    }

    // Create and display the checkbox
    if (indexPath.row == 5 && [cell.reuseIdentifier isEqualToString:CheckboxCellIdentifier]) {
        [self setUpCheckboxWidgetForCell:cell];
    }
}

- (void)submitNewCard:(UIButton *)button {

    if (!vdkClient) { //if no client (e.g. iOS 4.3) don't submit card
        return;
    }

    for (UITextField *textField in textFields) {
        if (!textField.text || [textField.text isEqualToString:@""]) {
            return;
        }
    }

    button.enabled = NO;

    // Option 1 - Encrypt card data individually, then append "venmo_sdk_session"
// This requires the BraintreeEncryption library
//    BraintreeEncryption *braintreeEncryption = [[BraintreeEncryption alloc]
//                                                initWithPublicKey:BRAINTREE_KEY];
//
//    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:6];
//    NSInteger i=0;
//    NSString *key;
//    for (UITextField *textField in textFields) {
//        if (i==0) key = @"enc_card_number";
//        else if (i==1) key = @"enc_expiration_month";
//        else if (i==2) key = @"enc_expiration_year";
//        else if (i==3) key = @"enc_cvv";
//        else if (i==4) key = @"enc_zipcode";
//        [params setObject:[braintreeEncryption encryptString:textField.text] forKey:key];
//        //        NSLog(@"key: %@ -- value: %@", key, textField.text);
//        //        [params setObject:textField.text forKey:key];
//        i++;
//    }
//    [params setObject:[vdkClient venmoSDKSession] forKey:@"enc_venmo_sdk_session"];
//    NSLog(@"params:\n%@", params);

    // Option 2 - Convenience method to encrypt card data that also adds "venmo_sdk_session"
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithCapacity:5];
    NSInteger i=0;
    NSString *key;
    for (UITextField *textField in textFields) {
        if (i==0) key = @"enc_card_number";
        else if (i==1) key = @"enc_expiration_month";
        else if (i==2) key = @"enc_expiration_year";
        else if (i==3) key = @"enc_cvv";
        else if (i==4) key = @"enc_zipcode";
        [parameters setObject:textField.text forKey:key];
        i++;
    }
    NSDictionary *params = [vdkClient encryptedCardDataAndVenmoSDKSessionWithCardDictionary:parameters];
    NSMutableDictionary *newParams = [NSMutableDictionary dictionaryWithDictionary:params];
    [newParams setObject:[params objectForKey:@"venmo_sdk_session"]
                  forKey:@"enc_venmo_sdk_session"];
    //    NSLog(@"params: %@", newParams);

    [activityOverlayView show];

    // Send card information to the test merchant server.
    NSString *urlString = [NSString stringWithFormat:@"%@%@", SANDBOX_MERCHANT_URL, @"/card/add"];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    FSNConnection *connection =
    [FSNConnection
     withUrl:[NSURL URLWithString:urlString]
     method:FSNRequestMethodPOST
     headers:nil
     parameters:newParams
     parseBlock:^id(FSNConnection *c, NSError **error) {
         NSDictionary *dictionary = [c.responseData dictionaryFromJSONWithError:error];
         if (!dictionary) return nil;
         if (c.response.statusCode != 200) {
             *error = [NSError errorWithDomain:@"FSAPIErrorDomain"
                                          code:1
                                      userInfo:[dictionary objectForKey:@"meta"]];
         }
         return dictionary;
     } completionBlock:^(FSNConnection *c) {
         [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
         NSDictionary *response = (NSDictionary *)[c parseResult];
         NSInteger statusCode = [c.response statusCode];
         NSString *serverError = [response objectForKey:@"error"];
 //         NSLog(@"url: %@", c.url);
 //         NSLog(@"status code: %i", [c.response statusCode]);
 //         NSLog(@"response: %@", response);
 //         NSLog(@"error: %@", serverError);
         BOOL success = [[response objectForKey:@"success"] isEqualToNumber:@1];

         [activityOverlayView dismissAnimated:YES];

         UIAlertView *alertView =
         [[UIAlertView alloc] initWithTitle:(success ? @"Nice!" : @"Error Sending Card")
                                    message:nil delegate:nil cancelButtonTitle:@"OK"
                          otherButtonTitles:nil];

         alertView.message =
         (success ?
          [NSString stringWithFormat:@"Successfully submitted a new card."] :
          [NSString stringWithFormat:@"Error (%i) sending card to merchant server:%@",
           statusCode, (serverError ? serverError : response)]);

         button.enabled = YES;
         [alertView show];
     }
     progressBlock:nil];
    [connection start];
}

- (void)prefillAction {
    NSInteger i = 0;
    for (UITextField *textField in textFields) {
        if (i == 0) {
            textField.text = @"4111111111111111";
        } else if (i == 1) {
            textField.text = @"05";
        } else if (i == 2) {
            textField.text = @"2014";
        } else if (i == 3) {
            textField.text = @"123";
        } else if (i == 4) {
            textField.text = @"10001";
        }
        i++;
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - VDKClientDelegate

- (void)client:(VDKClient *)client didReceivePaymentMethodOptionStatus:(VDKPaymentMethodOptionStatus)paymentMethodOptionStatus {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    NSLog(@"loading finished: %i", paymentMethodOptionStatus);
    if (paymentMethodOptionStatus == VDKPaymentMethodOptionStatusYes) {
        // Force tableview to reloadData, which renders card widget
        NSLog(@"payment method on file");
        [self paymentMethodFound];
    }
}

- (void)client:(VDKClient *)client didFinishLoadingLiveStatus:(VDKLiveStatus)liveStatus {
    if (liveStatus == VDKLiveStatusYes) {
        // Create checkbox
    }
}

// DEPRECATED delegate method
//- (void)client:(VDKClient *)client didFinishLoadingIsLive:(VDKIsLive)isLive {
//    if (isLive == VDKIsLiveYes) {
//        // Create checkbox
//    }
//}

-(void)client:(VDKClient *)client approvedPaymentMethodWithCode:(NSString *)paymentMethodCode {
    // User approved a card --> upload it to merchant server in order to fwd it braintree
    NSString *urlString = [NSString stringWithFormat:@"%@%@",
                           SANDBOX_MERCHANT_URL, @"/card/payment_method_code"];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];

    [activityOverlayView show];

    FSNConnection *connection =
    [FSNConnection
     withUrl:[NSURL URLWithString:urlString]
     method:FSNRequestMethodPOST
     headers:nil
     parameters:[NSDictionary dictionaryWithObject:paymentMethodCode
                                            forKey:@"enc_payment_method_code"]
     parseBlock:^id(FSNConnection *c, NSError **error) {
         NSDictionary *dictionary = [c.responseData dictionaryFromJSONWithError:error];
         if (!dictionary) return nil;
         if (c.response.statusCode != 200) {
             *error = [NSError errorWithDomain:@"FSAPIErrorDomain"
                                          code:1
                                      userInfo:[dictionary objectForKey:@"meta"]];
         }
         return dictionary;
     } completionBlock:^(FSNConnection *c) {
         [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
         NSDictionary *response = (NSDictionary *)[c parseResult];
         NSString *paymentMethodToken = [response objectForKey:@"payment_method_token"];

         [activityOverlayView dismissAnimated:YES];

         UIAlertView *alertView =
         [[UIAlertView alloc] initWithTitle:(!paymentMethodToken ? @"Error using card" : @"Rock on!")
                                    message:nil delegate:nil cancelButtonTitle:@"OK"
                          otherButtonTitles:nil];

         alertView.message =
         (!paymentMethodToken ?
          [NSString stringWithFormat:@"Error (%i) sending payment method code card to merchant server: %@",
           c.response.statusCode, response] :
          [NSString stringWithFormat:@"Payment method token successfully created on merchant server: %@",
           paymentMethodToken]);
         [alertView show];
     }
     progressBlock:nil];
    [connection start];
    
}

-(void)clientDidLogout:(VDKClient *)client {
    [self logoutVenmoSDK];
}

@end
