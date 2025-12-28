#import <UIKit/UIKit.h>

// --- Interface Definitions ---

@interface SBPIPInteractionController : NSObject
@property (assign, nonatomic) double minimumScale;
@property (assign, nonatomic) double maximumScale;
@end

@interface SBPIPContainerViewController : UIViewController
@property (nonatomic, readonly) UIViewController *contentViewController;
@end

// --- State Tracking ---
// Default to unlocked size limits
static BOOL isUnlimited = YES;

// --- Hooks ---

%hook SBPIPInteractionController

// Override the minimum allowed size (0.1 = 10% of original size)
- (double)minimumScale {
    if (isUnlimited) {
        return 0.15; 
    }
    return %orig;
}

// Override the maximum allowed size (5.0 = 500% of original size)
- (double)maximumScale {
    if (isUnlimited) {
        return 5.0;
    }
    return %orig;
}

%end

%hook SBPIPContainerViewController

- (void)loadView {
    %orig;
    
    // Inject the Toggle Gesture (Long Press) onto the PiP window
    // This allows you to revert to "Apple Stock Sizes" if needed on the fly
    UIView *view = self.contentViewController.view;
    if (view) {
        UILongPressGestureRecognizer *togglePress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(fp_toggleState:)];
        togglePress.minimumPressDuration = 0.8; // Reduce accidental triggers
        [view addGestureRecognizer:togglePress];
    }
}

%new
- (void)fp_toggleState:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        isUnlimited = !isUnlimited;
        
        // Optional: A visual indicator could go here, but per request, 
        // we keep it pure. The user will know it's working because 
        // they can suddenly pinch it larger/smaller.
    }
}

%end