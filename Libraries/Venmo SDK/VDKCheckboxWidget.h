/*
 * Venmo SDK
 *
 ******************************
 * VDKCheckboxWidget.h
 ******************************
 *
 * This view is required to be displayed where users enter their credit/debit card details.
 * It presents a description and checkbox that, when checked, stores the card info for
 * purchases in other apps.
 *
 * There is no VDKCheckboxWidgetDelegate. This is just a view that you should add to your payment
 * entry form. All delegate callbacks are handled through the delegate of your VDKClient.
 *
 * Custom public methods on VDKCheckboxWidget are just for styling.
 *
 * You must use [vdkClient checkboxWidget] to alloc and init a VDKCheckboxWidget.
 * Do NOT create a VDKCheckboxWidget with [[VDKCheckboxWidget alloc] init]
 *
 * The default size of a VDKCheckBoxWidget is 300 width x 66 height. The height can not be changed,
 * but the width can be set to any value at least 280.
 */


#import <UIKit/UIKit.h>

@interface VDKCheckboxWidget : UIView

// Sets the color of labels and button titles.
// The color of the "How it works" & "Terms of Service" links can't be
// changed right now right now.
@property (strong, nonatomic) UIColor *textColor; // default is nil (text draws black)

// Set the widget's background color using the default setBackgroundColor method on UIView.

// Convenience method to set the width of the checkbox widget.
// Width must be >= 280
- (void)setWidth:(CGFloat)newWidth;

// Convenience method to set the origin of the checkbox widget.
- (void)setOrigin:(CGPoint)newOrigin;

@end
