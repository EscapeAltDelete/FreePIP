#import <UIKit/UIKit.h>

// --- State Tracking (Global) ---
static BOOL isUnlimited = YES;

// --- Interface: Pegasus (Inside App) ---
@interface PGPictureInPictureViewController : UIViewController
@property (nonatomic, assign) CGFloat preferredMinimumWidth; // The property from your screenshot
@end

// --- Interface: SpringBoard (System) ---
@interface SBPIPInteractionController : NSObject
@property (nonatomic, assign) double minimumScale;
@property (nonatomic, assign) double maximumScale;
@end

// ============================================================================
// GROUP 1: The App Hook (Runs in YouTube, Safari, etc.)
// This overrides the "Content Preference" found in your screenshot.
// ============================================================================
%group PegasusHooks

%hook PGPictureInPictureViewController

// Override the read-only property getter
- (CGFloat)preferredMinimumWidth {
    if (isUnlimited) {
        // Return 32.0 instead of the default 192.0 shown in your screenshot.
        // This tells the system "I can shrink very small".
        return 32.0;
    }
    return %orig;
}

- (void)viewDidLoad {
    %orig;
    // Inject the Toggle Gesture (Long Press)
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
        // Force layout update to apply changes immediately
        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];
    }
}

%end
%end // PegasusHooks


// ============================================================================
// GROUP 2: The SpringBoard Hook (Runs in System)
// This overrides the "Physics Engine" limits.
// ============================================================================
%group SpringBoardHooks

%hook SBPIPInteractionController

- (double)minimumScale {
    return isUnlimited ? 0.10 : %orig;
}

- (double)maximumScale {
    return isUnlimited ? 5.00 : %orig;
}

// iOS 17 fallback: Force-set limits whenever the system calculates them
- (void)_updateScaleLimits {
    %orig;
    if (isUnlimited) {
        @try {
            [self setValue:@(0.10) forKey:@"minimumScale"];
            [self setValue:@(5.00) forKey:@"maximumScale"];
        } @catch (NSException *e) {}
    }
}

%end
%end // SpringBoardHooks


// ============================================================================
// INITIALIZATION
// ============================================================================
%ctor {
    // Determine where we are running and init the correct hooks
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];

    if ([bundleID isEqualToString:@"com.apple.springboard"]) {
        %init(SpringBoardHooks);
    } else {
        // We are in an App (YouTube, Safari, etc.)
        // Only init if the Pegasus framework is present
        %init(PegasusHooks);
    }
}