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
 * You must use [vdkClient cardWidget] to alloc and init a VDKCardWidget. Do not create 
 * a VDKCardWidget with [[VDKCardWidget alloc] init]
 *
 * The default size of a VDKCardWidget is 300 width x 80 height.
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface VDKCardWidget : UIView

// Sets width to the specified value.
// Width must be >= 280
- (void)setWidth:(CGFloat)newWidth;

// Convenience method to set the origin of the card widget.
- (void)setOrigin:(CGPoint)origin;

// Shows/hides the picture associated with the Venmo user or previous merchant where the card was used.
- (void)setShowsPicture:(BOOL)showsThePicture;

// Sets the color of labels and button titles.
- (void)setTextColor:(UIColor *)color;

// Default UIView method overridden to propogate self's backgroundColor to subviews.
- (void)setBackgroundColor:(UIColor *)backgroundColor;

@end
