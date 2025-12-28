#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// --- Configuration ---
// Hardcoded 'Yes' to ensure it works without user interaction
static BOOL isUnlimited = YES;

// --- Interface Definitions ---
@interface PGPictureInPictureViewController : UIViewController
@property (nonatomic, assign) CGFloat preferredMinimumWidth;
@end

@interface SBPIPInteractionController : NSObject
@property (nonatomic, assign) double minimumScale;
@property (nonatomic, assign) double maximumScale;
@end

// ============================================================================
// GROUP 1: Pegasus Hooks (Runs inside Apps like YouTube/Safari)
// ============================================================================
%group PegasusHooks

%hook PGPictureInPictureViewController

// This is the property from your screenshot.
// We override it to allow the content to shrink way down (e.g. 10pts wide).
- (CGFloat)preferredMinimumWidth {
    return isUnlimited ? 10.0 : %orig;
}

// Override these to ensure the app doesn't send restrictive constraints to the system
- (CGSize)minimumStashTabSize {
    return isUnlimited ? CGSizeMake(10, 10) : %orig;
}

- (CGSize)microPIPSize {
    return isUnlimited ? CGSizeMake(20, 20) : %orig;
}

%end
%end // PegasusHooks


// ============================================================================
// GROUP 2: SpringBoard Hooks (Runs inside System)
// ============================================================================
%group SpringBoardHooks

%hook SBPIPInteractionController

- (double)minimumScale {
    return isUnlimited ? 0.1 : %orig;
}

- (double)maximumScale {
    return isUnlimited ? 5.0 : %orig;
}

// iOS 17 specific: Intercept dynamic limit updates
- (void)_updateScaleLimits {
    %orig;
    if (isUnlimited) {
        // Safely force our limits
        @try {
            [self setValue:@(0.1) forKey:@"minimumScale"];
            [self setValue:@(5.0) forKey:@"maximumScale"];
        } @catch (NSException *e) {}
    }
}

%end
%end // SpringBoardHooks


// ============================================================================
// INITIALIZATION (Crash Protection)
// ============================================================================
%ctor {
    @autoreleasepool {
        NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];

        // 1. SpringBoard Logic
        if ([bundleID isEqualToString:@"com.apple.springboard"]) {
            %init(SpringBoardHooks);
        }
        // 2. App Logic (ONLY if the class exists)
        else {
            // Check if the Pegasus framework class is actually loaded in this process.
            // If not, we skip initialization to prevent crashes in random apps (Mail, Calculator, etc).
            if (objc_getClass("PGPictureInPictureViewController")) {
                %init(PegasusHooks);
            }
        }
    }
}