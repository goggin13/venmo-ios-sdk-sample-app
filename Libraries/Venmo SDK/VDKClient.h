/*
 * Venmo SDK
 *
 ******************************
 ******************************
 * VDKClient.h
 ******************************
 ******************************
 *
 * The VDKClient manages all delegate and view creation methods so your users can more quickly and
 * securely make payments. If a payment method was previously entered in another app on the
 * Braintree network, you can prompt the user to use that card without her having to retype
 * the payment method credentials (i.e. credit card number).
 *
 * Please create a single instance of VDKClient within your app to manage all payment method
 * interactions.
 *
 * When users enter a new payment method from scratch, please create and add a VDKCheckboxWidget
 * near the form.
 *
 * If there is at least 1 payment method on file for that user, you will be able to create a
 * VDKCardWidget and display that to the user. The VDKCardWidget will present the user with a
 * payment method that was entered in a previous app on this phone. The user will then have the
 * option to select that payment method for use in your app, or continue with the default
 * flow to add a new payment method. We recommend adding the VDKCardWidget directly above the
 * manual credit card entry form for optimal conversion.
 *
 *
 *
 ******************************
 * Adding a card to Braintree
 ******************************
 *
 * After a user enters card information to your app, it is app's job to encrypt the card
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
 * 2. "[vdkClient encryptCardFormDataWithVenmoSDKSession:cardInformationDictionary]" will accept
 *    a read-only NSDictionary of your unencrypted card values and encrypt them using your
 *    Braintree key. Then, it add the "venmo_sdk_session" data as an additional item in the
 *    parameters. Finally, it will return a new NSDictionary with the encrypted card data and
 *    the additional "venmo_sdk_session" parameter.
 *
 */

#import <Foundation/Foundation.h>

@class VDKCardWidget, VDKCheckboxWidget;

// Specifies if the user has a payment method on file. If a request is still loading, the
// client's paymentMethodOptionStatus will be PaymentMethodOptionStatusPending. If the client's
// paymentMethodOptionStatus is PaymentMethodOptionStatusYes, you should create and display
// a VDKCardWidget.
typedef enum {
    PaymentMethodOptionStatusPending,
    PaymentMethodOptionStatusNo,
    PaymentMethodOptionStatusYes,
} PaymentMethodOptionStatus;

// When init'ing the VDKClient, you can set the environment to production or sandbox for testing.
// Sandbox testing will be used in conjunction with the open-source'd VenmoSDKTestApp.
typedef enum {
    VenmoSDKEnvironmentProduction,
    VenmoSDKEnvironmentSandbox,
} VenmoSDKEnvironment;

@protocol VDKClientDelegate;

@interface VDKClient : NSObject

@property (nonatomic, retain, readonly) NSString *merchantID;
@property (nonatomic, retain, readonly) NSString *braintreePublicEncryptionKey;
@property (nonatomic, retain, readonly) NSString *versionNumber;
@property (strong, nonatomic) id<VDKClientDelegate>delegate;

// Inits a VDKClient object.
// Default Venmo SDK environment is VenmoSDKEnvironmentProduction.
- (id)initWithMerchantID:(NSString *)theMerchantID braintreePublicEncryptionKey:(NSString *)publicEncryptionKey;

// Inits a VDKClient object where you can specify the VenmoSDKEnvironment
- (id)initWithMerchantID:(NSString *)theMerchantID braintreePublicEncryptionKey:(NSString *)publicEncryptionKey
     venmoSDKEnvironment:(VenmoSDKEnvironment)venmoSDKEnvironment;

// Returns the status of a user's payment methods as defined by PaymentMethodOptionStatus.
- (PaymentMethodOptionStatus)paymentMethodOptionStatus;

// You must use this method to create a VDKCardWidget, do NOT use [[VDKCardWidget alloc] init].
// If your VDKClient's paymentMethodOptionStatus is paymentMethodOptionStatusPending or
// paymentMethodOptionStatusNo, this method will return nil.
// Default behavior is to not show a picture (can be changed dynamically).
- (VDKCardWidget *)cardWidget;

// Creates a VDKCardWidget view with a flag to show or hide the picture.
- (VDKCardWidget *)cardWidgetShowingPicture:(BOOL)showingMerchantPicture;

// Creates a VDKCheckboxWidget view, do NOT use [[VDKCheckboxWidget alloc] init].
- (VDKCheckboxWidget *)checkboxWidget;

// Returns encryptedCardForm based on a dictionary of the card input information.
// You must send to your servers and exchange it with Braintree for a payment_token.
- (NSDictionary *)encryptCardFormDataWithVenmoSDKSession:(NSDictionary *)formData;

// Returns an encrypted string using your braintreePublicEncryptionKey. You must include this string
// as an additional parameter with the key "venmo_sdk_session" when submiting a card to the
// Braintree vault from your server.
- (NSString *)venmoSDKSession;

// Restarts the session for this device. If the user had any payment methods on file, those
// payment methods will no longer be on file. This method will only work for testing on sandbox,
// e.g. if your VDKClient was init'd with VenmoSDKEnvironment as VenmoSDKEnvironmentSandbox.
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
- (void)vdkClient:(VDKClient *)client paymentMethodOptionStatusDidFinishLoading:(PaymentMethodOptionStatus)paymentMethodOptionStatus;

// After a user gives permission to use this card and answers any security questions, this delegate
// method will fire. The venmoSDKPaymentMethodCode return value can be used to make payments
// through the Braintree gateway.
- (void)vdkClient:(VDKClient *)client userDidSelectPaymentMethod:(NSString *)venmoSDKPaymentMethodCode;

// If a user logs out, all sessions are deleted and you should remove any card widgets.
- (void)vdkClientUserDidLogout:(VDKClient *)client;

@end
