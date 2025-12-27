#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "Tweak.h"

// Helper to find parent view controller
#define UIViewParentController(__view) ({ \
        UIResponder *__responder = __view; \
        while ([__responder isKindOfClass:[UIView class]]) \
        __responder = [__responder nextResponder]; \
        (UIViewController *)__responder; \
    })

static BOOL locked = NO;

// Helper to get the content view across iOS versions
static UIView *getContentView(SBPIPContainerViewController *self) {
    if ([self respondsToSelector:@selector(contentViewController)]) {
        // iOS 15, 16, 17+
        return self.contentViewController.view;
    }
    if ([self respondsToSelector:@selector(pictureInPictureViewController)]) {
        // iOS 13, 14
        return self.pictureInPictureViewController.view;
    }
    return nil;
}

// Helper to get target view from InteractionController
static UIView *getTargetView(SBPIPInteractionController *self, UIGestureRecognizer *sender) {
    if ([self respondsToSelector:@selector(targetView)])
        return [self targetView];
    
    // Fallback logic
    return UIViewParentController(sender.view).view;
}

// Logic for transformations
static void handlePan(UIView *view, UIPanGestureRecognizer *sender) {
    CGPoint translation = [sender translationInView:view];
    view.transform = CGAffineTransformTranslate(view.transform, translation.x, translation.y);
    [sender setTranslation:CGPointZero inView:view];
}

static void handlePinch(UIView *view, UIPinchGestureRecognizer *sender) {
    view.transform = CGAffineTransformScale(view.transform, sender.scale, sender.scale);
    sender.scale = 1.0;
}

// --- Group: iOS 13 & Legacy / Fallback Container Logic ---
%group SBPIPContainerHooks
%hook SBPIPContainerViewController

-(void)loadView {
    %orig;
    
    UIView *targetView = getContentView(self);
    if (targetView) {
        UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGesture:)];
        [targetView addGestureRecognizer:longPressGesture];
        [self setupBorder];
    }
}

// iOS 13 Style (Underscored methods)
-(void)_handlePanGesture:(UIPanGestureRecognizer *)sender {
    if(locked) %orig;
    else if(sender.state == UIGestureRecognizerStateChanged) {
        UIView *view = getContentView(self);
        if (view) handlePan(view, sender);
    }
}

-(void)_handlePinchGesture:(UIPinchGestureRecognizer *)sender {
    if(locked) %orig;
    else if(sender.state == UIGestureRecognizerStateChanged) {
        UIView *view = getContentView(self);
        if (view) handlePinch(view, sender);
    }
}

-(void)_handleRotationGesture:(UIRotationGestureRecognizer *)sender {
    if(locked) %orig;
}

// iOS 14+ Style (if Container handles it directly in newer iOS)
-(void)handlePanGesture:(UIPanGestureRecognizer *)sender {
    if(locked) %orig;
    else if(sender.state == UIGestureRecognizerStateChanged) {
        UIView *view = getContentView(self);
        if (view) handlePan(view, sender);
    }
}

-(void)setContentViewPadding:(UIEdgeInsets)arg1 animationDuration:(double)arg2 animationOptions:(unsigned long long)arg3 {
    if(locked) %orig;
}

-(void)setContentViewPadding:(UIEdgeInsets)arg1 {
    if(!locked) arg1 = UIEdgeInsetsZero;
    %orig(arg1);
}

%new
-(void)handleLongPressGesture:(UILongPressGestureRecognizer *)sender {
    if (sender.state != UIGestureRecognizerStateBegan) return;
    locked = !locked; // Toggle
    [self setupBorder];
}

%new
-(void)setupBorder {
    UIView *view = getContentView(self);
    if (!view) return;
    
    view.layer.borderWidth = 1.5;
    if(!locked) view.layer.borderColor = [UIColor clearColor].CGColor;
    else view.layer.borderColor = [UIColor redColor].CGColor;
}

%end
%end // SBPIPContainerHooks


// --- Group: iOS 14, 15, 16, 17+ Interaction Controller ---
%group SBPIPInteractionHooks
%hook SBPIPInteractionController

-(void)handlePanGesture:(UIPanGestureRecognizer *)sender {
    if(locked) %orig;
    else if(sender.state == UIGestureRecognizerStateChanged) {
        UIView *view = getTargetView(self, sender);
        if (view) handlePan(view, sender);
    }
}

-(void)handlePinchGesture:(UIPinchGestureRecognizer *)sender {
    if(locked) %orig;
    else if(sender.state == UIGestureRecognizerStateChanged) {
        UIView *view = getTargetView(self, sender);
        if (view) handlePinch(view, sender);
    }
}

-(void)handleRotationGesture:(UIRotationGestureRecognizer *)sender {
    if(locked) %orig;
}

%end
%end // SBPIPInteractionHooks


%ctor {
    NSLog(@"[FreePIP] Loaded");

    // Always init Container hooks as it handles loadView and borders
    %init(SBPIPContainerHooks);

    // Check if SBPIPInteractionController exists (iOS 14+)
    if (objc_getClass("SBPIPInteractionController")) {
        NSLog(@"[FreePIP] SBPIPInteractionController found, initializing interaction hooks");
        %init(SBPIPInteractionHooks);
    } else {
        NSLog(@"[FreePIP] SBPIPInteractionController NOT found, relying on Container hooks");
    }
}