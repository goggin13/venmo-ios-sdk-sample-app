VenmoIOSSDKSampleApp
=================

You may modify the constants defined at the top of `AppDelegate.m` to your own credentials for testing.

## Venmo SDK Documentation ##

Visit [here](https://www.braintreepayments.com/docs/ios) for the full documentation and usage of the iOS SDK.

This sample application runs in Braintree's Sandbox testing environment. It uses [CocoaPods](http://www.cocoapods.org/), a library manager for iOS.

To run the sample application:

1. Install CocoaPods (if you haven't already)
2. In the project's root directory, run 'pod install'
3. Open `VenmoIOSSDKSampleApp.xcworkspace`
4. `Run` the application

* To add sample card numbers in the test Sandbox environment, use card numbers found [here](https://www.braintreepayments.com/docs/ruby/reference/sandbox).

## Intro ##

This app is designed to help Braintree merchants test and integrate the Venmo SDK. Developers will be able to add a payment method (e.g. credit or debit card) in this application in the Sandbox environment, then see the card appear in their merchant app. Developers can also add a card, then tap "Refresh" to see the card appear in the testing app.

