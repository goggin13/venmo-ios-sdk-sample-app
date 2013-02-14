#import <UIKit/UIKit.h>

@interface ActivityOverlayView : UIView

@property (nonatomic, retain, readonly) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic, retain, readonly) UILabel *titleLabel;

+ (id)sharedOverlayView; // default title is @"Loading..."

- (void)show;
- (void)dismissAnimated:(BOOL)animated;

@end
