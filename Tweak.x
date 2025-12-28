#import <UIKit/UIKit.h>

// --- State Tracking ---
static BOOL isUnlimited = YES;

// --- Interfaces ---
@interface PGPictureInPictureViewController : UIViewController
@property (nonatomic, assign) CGFloat preferredMinimumWidth;
@end

@interface SBPIPInteractionController : NSObject
@property (nonatomic, assign) double minimumScale;
@property (nonatomic, assign) double maximumScale;
@end

// --- Hooks ---

// 1. Target the Pegasus Controller (The "Content" logic found in your screenshot)
%hook PGPictureInPictureViewController

- (CGFloat)preferredMinimumWidth {
    if (isUnlimited) {
        // Return a tiny width (e.g., 32pts) instead of the default 192 found in your screenshot.
        // This allows the content to shrink much further.
        return 32.0;
    }
    return %orig;
}

- (void)viewDidLoad {
    %orig;
    // Add Toggle Gesture (Long Press) to the window to switch modes
    if (self.view) {
        UILongPressGestureRecognizer *toggle = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(fp_toggle:)];
        toggle.minimumPressDuration = 0.8;
        [self.view addGestureRecognizer:toggle];
    }
}

%new
- (void)fp_toggle:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        isUnlimited = !isUnlimited;
        // Pure boolean toggle. No haptics/sounds to keep it lightweight.
        
        // Force a layout update so the change happens immediately if resized
        [self.view setNeedsLayout];
    }
}

%end

// 2. Target the SpringBoard Interaction Controller (The "Physics" logic in the parent)
%hook SBPIPInteractionController

- (double)minimumScale {
    return isUnlimited ? 0.1 : %orig;
}

- (double)maximumScale {
    return isUnlimited ? 5.0 : %orig;
}

// iOS 17 specific: Force override limits when the system calculates them
- (void)_updateScaleLimits {
    %orig;
    if (isUnlimited) {
        // Use KVC to force values into properties, even if they are internal/private
        @try {
            [self setValue:@(0.1) forKey:@"minimumScale"];
            [self setValue:@(5.0) forKey:@"maximumScale"];
        } @catch (NSException *e) {}
    }
}

%end