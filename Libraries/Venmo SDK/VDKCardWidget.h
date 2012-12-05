/*
 * Venmo SDK
 *
 ******************************
 * VDKCardWidget.h
 ******************************
 *
 * This view allows you to suggest existing payment methods to your users, so they don't have to
 * type in their card details. You can style it and set its origin & bounds by using the public
 * methods provided below.
 *
 * There is no VDKCardWidgetDelegate. This is just a view that you should add to your payment
 * entry form. All delegate callbacks are handled through the delegate of your VDKClient.
 *
 * Custom public methods on VDKChardWidget widget are just for styling.
 *
 * You must use [vdkClient cardWidget] to alloc and init a VDKCardWidget.
 * Do NOT create a VDKCardWidget with [[VDKCardWidget alloc] init]
 *
 * The default size of a VDKCardWidget is 300 width x 80 height. The height can not be changed,
 * but the width can be set to any value at least 280.
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface VDKCardWidget : UIView

// Shows/hides the picture associated with the Venmo user or previous merchant where the card was used.
@property (nonatomic, getter=isPictureHidden) BOOL pictureHidden; // default is NO.

// Sets the color of labels and button titles.
// The color of the "How it works" link can't be changed right now right now.
@property (strong, nonatomic) UIColor *textColor; // default is nil (text draws black)

// Set the widget's background color using the default setBackgroundColor method on UIView.

// Convenience method to set the width of the card widget.
// Width must be >= 280
- (void)setWidth:(CGFloat)newWidth;

// Convenience method to set the origin of the card widget.
- (void)setOrigin:(CGPoint)origin;

@end
