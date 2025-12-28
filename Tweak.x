#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <string.h>
#import <dlfcn.h> // Required for dlopen

// --- State ---
static BOOL isUnlimited = YES;

// --- Interfaces ---
@interface PGPictureInPictureViewController : UIViewController
@property (nonatomic, assign) CGFloat preferredMinimumWidth;
@end

@interface SBPIPInteractionController : NSObject
@end

// --- Helper to log (Debugging only, doesn't affect performance) ---
static void FPLog(NSString *msg) {
    NSLog(@"[FreePIP] %@", msg);
}

// ============================================================================
// GROUP 1: Pegasus Hooks (YouTube, Safari, etc.)
// ============================================================================
%group PegasusHooks

// 1. Hook the Controller (Your screenshot #13)
%hook PGPictureInPictureViewController

- (CGFloat)preferredMinimumWidth {
    return isUnlimited ? 20.0 : %orig;
}

- (CGSize)minimumStashTabSize {
    return isUnlimited ? CGSizeMake(10, 10) : %orig;
}

- (CGSize)microPIPSize {
    return isUnlimited ? CGSizeMake(20, 20) : %orig;
}

// 2. Hook the Settings Object (Your screenshot #17)
// This object often holds the hard limits for the physics engine
%hook PGMobilePIPSettings

- (double)minimumScale {
    return isUnlimited ? 0.01 : %orig;
}

- (double)maximumScale {
    return isUnlimited ? 10.0 : %orig;
}

%end // PGMobilePIPSettings

%end
%end // PegasusHooks


// ============================================================================
// GROUP 2: SpringBoard Hooks (System Physics)
// ============================================================================
%group SpringBoardHooks

%hook SBPIPInteractionController

- (double)minimumScale {
    return isUnlimited ? 0.01 : %orig;
}

- (double)maximumScale {
    return isUnlimited ? 10.0 : %orig;
}

// iOS 17 fallback: force values if system tries to recalculate them
- (void)_updateScaleLimits {
    %orig;
    if (isUnlimited) {
        @try {
            [self setValue:@(0.01) forKey:@"minimumScale"];
            [self setValue:@(10.0) forKey:@"maximumScale"];
        } @catch (NSException *e) {}
    }
}

%end
%end // SpringBoardHooks


// ============================================================================
// INITIALIZATION
// ============================================================================
%ctor {
    @autoreleasepool {
        const char *bundleID = [[[NSBundle mainBundle] bundleIdentifier] UTF8String];
        
        if (bundleID) {
            // 1. SpringBoard: Init immediately
            if (strcmp(bundleID, "com.apple.springboard") == 0) {
                %init(SpringBoardHooks);
            }
            // 2. Apps (YouTube, etc.): Force load framework, then init
            else {
                // Force load Pegasus so we can hook it even if the app hasn't started a video yet
                void *handle = dlopen("/System/Library/PrivateFrameworks/Pegasus.framework/Pegasus", RTLD_NOW);
                
                // Only init if the class exists (it should now, unless the iOS version is very old)
                if (objc_getClass("PGPictureInPictureViewController")) {
                    %init(PegasusHooks);
                }
                
                if (handle) dlclose(handle); // Clean up handle, framework stays loaded
            }
        }
    }
}