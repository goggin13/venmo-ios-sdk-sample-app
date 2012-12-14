/*
 * Venmo SDK - Version 1.0.0
 *
 ******************************
 ******************************
 * VDKClient.h
 ******************************
 ******************************
 *
 * The VDKClient manages all view creation and delegate methods so that your users can more
 * quickly and securely make payments. If a payment method was previously entered in another
 * app on the Braintree network, you can prompt the user to use that card without her having
 * to retype the payment method credentials (i.e. credit card number).
 *
 * Please create a single instance of a VDKClient within your app to manage all payment method
 * interactions. Once a client has been created using one of the custom "initWithMechantID..."
 * methods (shown below), you may use "[VDKClient sharedClient]" to return a singleton of the
 * client object.
 *
 * When users manually enter a new payment method, please create and add a VDKCheckboxWidget
 * near the form.
 *
 * If there is at least 1 payment method on file for that user, you will be able to create a
 * VDKCardWidget and display that to the user. The VDKCardWidget will present the user with a
 * payment method that was entered in a previous app on this phone. The user will then have the
 * option to select that payment method for use in your app or continue with the default
 * flow to add a new payment method. We recommend adding the VDKCardWidget directly above the
 * manual credit card entry form for optimal conversion.
 *
 * The Venmo SDK does not support iOS versions below 5.0. For iOS devices running iOS below 5.0,
 * initializing a VDKClient object will return nil. Similarly, initializing widgets on devices
 * below iOS 5.0 will return nil.
 *
 ******************************
 * Adding a card to Braintree
 ******************************
 *
 * After a user manually enters card information to your app, it is the app's job to encrypt the card (described below)
 * information and send it to the merchant's servers. Then, the merchant server will send the
 * encrypted card information to Braintree for a payment token. There is one additional parameter
 * that is required to send to the Braintree servers, the parameter is called "venmo_sdk_session".
 * It is the app's job to get the "venmo_sdk_session" parameter and send it to the the merchant
 * servers alongside the encrypted credit card data.
 *
 * The app can get the "venmo_sdk_session" string in two different ways:
 *
 * 1. "[vdkClient venmoSDKSession]" returns an encrypted string. It is your job to encrypt the
 *    card data using the BraintreeEncryption library and then include the "venmo_sdk_session" as
 *    an additional parameter.
 *
 * 2. "[vdkClient encryptedCardDataAndVenmoSDKSessionWithCardDictionary:cardInformationDictionary]" 
 *    will accept a read-only NSDictionary of your unencrypted card values and encrypt them using 
 *    your Braintree key. Then, it will add the "venmo_sdk_session" data as an additional item
 *    in the parameters. Finally, it will return a new NSDictionary with the encrypted card
 *    data and the additional "venmo_sdk_session" parameter.
 *
 */

#import <Foundation/Foundation.h>
#import "VDKCheckboxWidget.h"
#import "VDKCardWidget.h"

// Specifies if the user has a payment method on file. If a request is still loading, the
// client's paymentMethodOptionStatus will be PaymentMethodOptionStatusLoading. If the client's
// paymentMethodOptionStatus is PaymentMethodOptionStatusYes, you should create and display
// a VDKCardWidget. If the request for payment methods failed, you can call `refresh`.
typedef enum {
    VDKPaymentMethodOptionStatusLoading,
    VDKPaymentMethodOptionStatusFailed,
    VDKPaymentMethodOptionStatusNo,
    VDKPaymentMethodOptionStatusYes,
} VDKPaymentMethodOptionStatus;

// When initializing the VDKClient, you can set the environment to production or sandbox for testing.
// Sandbox testing is used in conjunction with the open-sourced VenmoSDKTestApp.
typedef enum {
    VDKEnvironmentProduction,
    VDKEnvironmentSandbox,
} VDKEnvironment;

// Before the Venmo SDK goes public, you should check the VDKIsLive status. If this returns
// VDKIsLiveNo, you should not show any widgets. If VDKIsLive is equal to
// VDKIsLiveLoading, the request to download that status is nil.
typedef enum {
    VDKIsLiveLoading,
    VDKIsLiveYes,
    VDKIsLiveNo,
} VDKIsLive;

@protocol VDKClientDelegate;

@interface VDKClient : NSObject

@property (nonatomic, retain, readonly) NSString *merchantID;
@property (nonatomic, retain, readonly) NSString *braintreePublicEncryptionKey;
@property (nonatomic, retain, readonly) NSString *versionNumber;
@property (strong, nonatomic) id<VDKClientDelegate>delegate;

// A convenience method that returns a singleton of the VDKClient that was created by one of
// the custom "initWithMechantID..." functions below.
+ (VDKClient *)sharedClient;

// Inits a VDKClient object.
// Default Venmo SDK environment is VDKEnvironmentProduction.
- (id)initWithMerchantID:(NSString *)merchantID braintreePublicEncryptionKey:(NSString *)braintreePublicEncryptionKey;

// Inits a VDKClient object where you can specify the VDKEnvironment
- (id)initWithMerchantID:(NSString *)merchantID braintreePublicEncryptionKey:(NSString *)braintreePublicEncryptionKey
          vdkEnvironment:(VDKEnvironment)VDKEnvironment;

// Returns the status of a user's payment methods as defined by PaymentMethodOptionStatus.
- (VDKPaymentMethodOptionStatus)paymentMethodOptionStatus;

// Creates a VDKCheckboxWidget view, do NOT use [[VDKCheckboxWidget alloc] init].
- (VDKCheckboxWidget *)checkboxWidget;

// You must use this method to create a VDKCardWidget, do NOT use [[VDKCardWidget alloc] init].
// If your VDKClient's paymentMethodOptionStatus is PaymentMethodOptionStatusLoading
// PaymentMethodOptionStatusFailed, or PaymentMethodOptionStatusNo, this method will return nil.
// Default behavior is to not show a picture (can be changed dynamically).
- (VDKCardWidget *)cardWidget;

// Creates a VDKCardWidget view with a flag to show or hide the picture.
- (VDKCardWidget *)cardWidgetShowingPicture:(BOOL)showingMerchantPicture;

// Returns encryptedCardForm based on a dictionary of the raw card input information.
// You must send it to your servers and exchange it with Braintree for a payment_token.
- (NSDictionary *)encryptedCardDataAndVenmoSDKSessionWithCardDictionary:(NSDictionary *)cardDictionary;

// Returns an encrypted string using your braintreePublicEncryptionKey. You must include this string
// as an additional parameter with the key "venmo_sdk_session" when submiting a card to the
// Braintree vault from your server.
- (NSString *)venmoSDKSession;

// Returns if the Venmo SDK is live. While the network request is still running, this will
// return VDKIsLiveLoading. If this returns VDKIsLiveNo or VDKIsLiveLoading,
// VDKCardWidget and VDKCheckboxWidget cannot be created successfully.
- (VDKIsLive)isLive;

// Refreshes the Venmo SDK by deleting any payment methods on file and re-downloading payment
// methods for that user. This will be useful, for example, if the the device has no service
// and did not successfully download cards previously
// (will be denoted by [vdkClient isLive] == VDKIsLiveLoading).
// 
// If your app is displaying any VDKCardWidgets, they should be removed from the screen and
// references to it should be set to nil. You do not have to edit or delete existing
// VDKCheckboxWidgets from the app.
- (void)refresh;

// Restarts the session for this device. If the user had any payment methods on file, those
// payment methods will no longer be on file.
//
// NOTE: This method will only work for testing on sandbox (VDKEnvironmentSandbox)
// e.g. if your VDKClient was init'd with VDKEnvironment as VDKEnvironmentSandbox.
- (void)restartSession;

@end

//__________________________________________________________________________________________________
// this protocol notifies the parent app about user state and actions performed by user on VDK widgets

@protocol VDKClientDelegate <NSObject>

@optional
// This method is triggered when the check for cards finishes loading. Once it returns, the client's
// paymentMethodOptionStatus will be set to PaymentMethodOptionStatusNo or
// PaymentMethodOptionStatusYes. You may want to implement this method if you're credit card
// input form is visible and the client has not finished its call to check for cards. Once this
// method fires, you can check the paymentMethodOptionStatus and render the a card widget
// if possible.
- (void)client:(VDKClient *)client didReceivePaymentMethodOptionStatus:(VDKPaymentMethodOptionStatus)paymentMethodOptionStatus;

// A network request is sent out to determine if the Venmo SDK is live. When it returns, this
// delegate method will trigger, returning a VDKIsLive flag. If your app isn't showing
// the VDKCheckbox unless the Venmo SDK is live, this is a good place to do so.
- (void)client:(VDKClient *)client didFinishLoadingIsLive:(VDKIsLive)isLive;

// After a user gives permission to use this card and answers any security questions, this delegate
// method will fire. The vdkPaymentMethodCode return value can be used to make payments
// through the Braintree gateway.
- (void)client:(VDKClient *)client approvedPaymentMethodWithCode:(NSString *)paymentMethodCode;

// If a user logs out, all sessions are deleted and you should remove any card widgets.
- (void)clientDidLogout:(VDKClient *)client;

@end
