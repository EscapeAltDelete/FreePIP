#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <string.h> // Required for strcmp

// --- Configuration ---
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

// Override the content width limit
- (CGFloat)preferredMinimumWidth {
    return isUnlimited ? 10.0 : %orig;
}

// Override sizing constraints
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
        @try {
            [self setValue:@(0.1) forKey:@"minimumScale"];
            [self setValue:@(5.0) forKey:@"maximumScale"];
        } @catch (NSException *e) {}
    }
}

%end
%end // SpringBoardHooks


// ============================================================================
// INITIALIZATION (Crash Fixed)
// ============================================================================
%ctor {
    @autoreleasepool {
        // Use C-string conversion to avoid 'isEqualToString:' crash with uninitialized string literals
        const char *bundleID = [[[NSBundle mainBundle] bundleIdentifier] UTF8String];

        if (bundleID) {
            // 1. SpringBoard Logic
            if (strcmp(bundleID, "com.apple.springboard") == 0) {
                %init(SpringBoardHooks);
            }
            // 2. App Logic (YouTube, Safari, etc.)
            else {
                // Only init if the Pegasus class exists (Safety check)
                if (objc_getClass("PGPictureInPictureViewController")) {
                    %init(PegasusHooks);
                }
            }
        }
    }
}