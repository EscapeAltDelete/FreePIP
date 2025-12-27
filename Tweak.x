#import <UIKit/UIKit.h>

// Minimal Interfaces
@interface SBPIPInteractionController : NSObject
@property (nonatomic, readonly) UIView *targetView;
@end

@interface SBPIPContainerViewController : UIViewController
@property (nonatomic, readonly) UIViewController *contentViewController;
@end

// State Tracking (Defaults to Free mode)
static BOOL isFree = YES;

%hook SBPIPInteractionController

- (void)handlePanGesture:(UIPanGestureRecognizer *)sender {
    if (!isFree) { %orig; return; }

    if (sender.state == UIGestureRecognizerStateChanged) {
        UIView *view = self.targetView;
        CGPoint trans = [sender translationInView:view];
        // GPU-accelerated translation
        view.transform = CGAffineTransformTranslate(view.transform, trans.x, trans.y);
        [sender setTranslation:CGPointZero inView:view];
    }
}

- (void)handlePinchGesture:(UIPinchGestureRecognizer *)sender {
    if (!isFree) { %orig; return; }

    if (sender.state == UIGestureRecognizerStateChanged) {
        UIView *view = self.targetView;
        CGFloat scale = sender.scale;
        // GPU-accelerated scaling
        view.transform = CGAffineTransformScale(view.transform, scale, scale);
        sender.scale = 1.0;
    }
}

- (void)handleRotationGesture:(UIRotationGestureRecognizer *)sender {
    if (!isFree) %orig;
}

%end

%hook SBPIPContainerViewController

- (void)loadView {
    %orig;
    // Inject Toggle Gesture
    UIView *view = self.contentViewController.view;
    if (view) {
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(fp_toggle:)];
        [view addGestureRecognizer:longPress];
    }
}

// Disable system snapping animations
- (void)setContentViewPadding:(UIEdgeInsets)padding animationDuration:(double)duration animationOptions:(NSUInteger)options {
    if (!isFree) %orig;
}

- (void)setContentViewPadding:(UIEdgeInsets)padding {
    if (isFree) padding = UIEdgeInsetsZero;
    %orig(padding);
}

%new
- (void)fp_toggle:(UILongPressGestureRecognizer *)sender {
    // Pure boolean toggle. No haptics, no visuals, no overhead.
    if (sender.state == UIGestureRecognizerStateBegan) {
        isFree = !isFree;
    }
}

%end