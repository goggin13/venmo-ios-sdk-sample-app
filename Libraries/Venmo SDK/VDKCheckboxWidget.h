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
 * You must use [vdkClient checkboxWidget] to alloc and init a VDKCheckboxWidget. Do not create
 * a VDKCheckboxWidget with [[VDKCheckboxWidget alloc] init]
 *
 * The default size of a VDKCheckBoxWidget is 300 width x 44 height.
 */


#import <UIKit/UIKit.h>

@interface VDKCheckboxWidget : UIView

// Sets the text color description text.
- (void)setTextColor:(UIColor *)newColor;

// Default UIView method overridden that sets the background view of this view and its subviews.
- (void)setBackgroundColor:(UIColor *)backgroundColor;

// Convenience method to set the origin of the VDKCheckboxWidget.
- (void)setOrigin:(CGPoint)newOrigin;

// Convenience method to set the width of the VDKCheckboxWidget.
- (void)setWidth:(CGFloat)newWidth;

@end
