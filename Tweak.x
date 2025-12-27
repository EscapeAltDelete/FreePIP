#import <UIKit/UIKit.h>

// Minimal Interfaces for iOS 15+
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
        // Direct transform application is more efficient than helper methods
        view.transform = CGAffineTransformTranslate(view.transform, trans.x, trans.y);
        [sender setTranslation:CGPointZero inView:view];
    }
}

- (void)handlePinchGesture:(UIPinchGestureRecognizer *)sender {
    if (!isFree) { %orig; return; }

    if (sender.state == UIGestureRecognizerStateChanged) {
        UIView *view = self.targetView;
        CGFloat scale = sender.scale;
        view.transform = CGAffineTransformScale(view.transform, scale, scale);
        sender.scale = 1.0;
    }
}

- (void)handleRotationGesture:(UIRotationGestureRecognizer *)sender {
    // Disable rotation in Free mode to prevent logic conflicts
    if (!isFree) %orig;
}

%end

%hook SBPIPContainerViewController

- (void)loadView {
    %orig;
    // Inject Toggle Gesture directly
    UIView *view = self.contentViewController.view;
    if (view) {
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(fp_toggle:)];
        [view addGestureRecognizer:longPress];
    }
}

// Block system snapping animations when in Free mode
- (void)setContentViewPadding:(UIEdgeInsets)padding animationDuration:(double)duration animationOptions:(NSUInteger)options {
    if (!isFree) %orig;
}

- (void)setContentViewPadding:(UIEdgeInsets)padding {
    if (isFree) padding = UIEdgeInsetsZero;
    %orig(padding);
}

%new
- (void)fp_toggle:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        isFree = !isFree;
        // Haptic feedback is cheaper/cleaner than drawing borders
        [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium] impactOccurred];
    }
}

%end