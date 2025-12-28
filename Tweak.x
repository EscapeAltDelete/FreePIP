#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <string.h>
#import <dlfcn.h>

// --- State ---
static BOOL isUnlimited = YES;

// --- Interfaces ---
@interface PGPictureInPictureViewController : UIViewController
@property (nonatomic, assign) CGFloat preferredMinimumWidth;
@end

@interface SBPIPInteractionController : NSObject
@end

// ============================================================================
// GROUP 1: Pegasus Hooks (YouTube, Safari, etc.)
// ============================================================================
%group PegasusHooks

// 1. Hook the Controller
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

%end // End PGPictureInPictureViewController

// 2. Hook the Settings Object
%hook PGMobilePIPSettings

- (double)minimumScale {
    return isUnlimited ? 0.01 : %orig;
}

- (double)maximumScale {
    return isUnlimited ? 10.0 : %orig;
}

%end // End PGMobilePIPSettings

%end // End Group PegasusHooks


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
%end // End Group SpringBoardHooks


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
                // We call dlopen but don't store the result to avoid "unused variable" warnings
                dlopen("/System/Library/PrivateFrameworks/Pegasus.framework/Pegasus", RTLD_NOW);
                
                // Only init if the class exists
                if (objc_getClass("PGPictureInPictureViewController")) {
                    %init(PegasusHooks);
                }
            }
        }
    }
}