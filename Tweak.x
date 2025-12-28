#import <UIKit/UIKit.h>

// --- Interfaces ---

@interface SBPIPInteractionController : NSObject
@property (nonatomic, assign) double minimumScale;
@property (nonatomic, assign) double maximumScale;
// iOS 17 specific internal property guesses
@property (nonatomic, assign) double _minimumScale; 
@property (nonatomic, assign) double _maximumScale;
@end

@interface SBPIPContainerViewController : UIViewController
@property (nonatomic, readonly) UIViewController *contentViewController;
@end

// --- State Tracking ---
static BOOL isUnlimited = YES; // Default to Enabled

// --- Hooks ---

%hook SBPIPInteractionController

// 1. Hook Setters: This forces the internal ivars to hold our values
- (void)setMinimumScale:(double)scale {
    if (isUnlimited) scale = 0.15; // 15% size
    %orig(scale);
}

- (void)setMaximumScale:(double)scale {
    if (isUnlimited) scale = 5.0; // 500% size
    %orig(scale);
}

// 2. Hook Getters: Just in case something reads the property
- (double)minimumScale {
    return isUnlimited ? 0.15 : %orig;
}

- (double)maximumScale {
    return isUnlimited ? 5.0 : %orig;
}

// 3. Hook Private Methods (The "Real" Logic often lives here)
// These methods are often used by the gesture recognizer directly
- (double)_minimumScale {
    return isUnlimited ? 0.15 : %orig;
}

- (double)_maximumScale {
    return isUnlimited ? 5.0 : %orig;
}

// Some iOS versions use this specifically for pinch gesture limits
- (double)_proratedScaleForScale:(double)scale {
    if (isUnlimited) return scale; // Bypass prorating calculation
    return %orig;
}

%end

%hook SBPIPContainerViewController

- (void)loadView {
    %orig;
    
    // Inject Toggle Gesture (Long Press)
    // Allows switching back to stock limits instantly if needed
    UIView *view = self.contentViewController.view;
    if (view) {
        UILongPressGestureRecognizer *togglePress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(fp_toggleState:)];
        togglePress.minimumPressDuration = 1.0;
        [view addGestureRecognizer:togglePress];
    }
}

%new
- (void)fp_toggleState:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        isUnlimited = !isUnlimited;
        
        // Force the Interaction Controller to re-read the values
        // We find the controller by traversing the child/parent chain or via singleton logic if available.
        // Since we can't easily access the specific interaction controller instance here without extra overhead,
        // the user will simply see the effect on the NEXT interaction (pinch).
    }
}

%end