#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "Tweak.h"

// State tracking (Static is efficient here as PiP is generally a singleton usage)
static BOOL isLocked = NO; 

// --- Helper Functions (Inlined for Performance) ---

// Efficiently find the parent view controller
static inline UIViewController *UIViewParentController(UIView *view) {
    UIResponder *responder = view;
    while ((responder = [responder nextResponder])) {
        if ([responder isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)responder;
        }
    }
    return nil;
}

// Safely resolve the content view regardless of iOS version
static inline UIView *getContentView(SBPIPContainerViewController *self) {
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

// Safely get target view from InteractionController
static inline UIView *getTargetView(SBPIPInteractionController *self, UIGestureRecognizer *sender) {
    if ([self respondsToSelector:@selector(targetView)]) {
        return self.targetView;
    }
    // Fallback: traverse responder chain
    UIViewController *parent = UIViewParentController(sender.view);
    return parent ? parent.view : sender.view;
}

// Apply Translation (Pan)
static inline void applyPan(UIView *view, UIPanGestureRecognizer *sender) {
    CGPoint translation = [sender translationInView:view];
    // Apply translation to existing transform
    view.transform = CGAffineTransformTranslate(view.transform, translation.x, translation.y);
    // Reset translation to avoid compounding
    [sender setTranslation:CGPointZero inView:view];
}

// Apply Scale (Pinch)
static inline void applyPinch(UIView *view, UIPinchGestureRecognizer *sender) {
    // Apply scale to existing transform
    view.transform = CGAffineTransformScale(view.transform, sender.scale, sender.scale);
    // Reset scale to avoid compounding
    sender.scale = 1.0;
}

// --- Hooks: Container View Controller (Handles Setup & Visuals) ---

%group SBPIPContainerHooks
%hook SBPIPContainerViewController

-(void)loadView {
    %orig;
    
    UIView *targetView = getContentView(self);
    if (targetView) {
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGesture:)];
        [targetView addGestureRecognizer:longPress];
        [self setupBorder];
    }
}

// -- iOS 13 Legacy Handlers --
-(void)_handlePanGesture:(UIPanGestureRecognizer *)sender {
    if(isLocked) %orig;
    else if(sender.state == UIGestureRecognizerStateChanged) {
        UIView *view = getContentView(self);
        if (view) applyPan(view, sender);
    }
}

-(void)_handlePinchGesture:(UIPinchGestureRecognizer *)sender {
    if(isLocked) %orig;
    else if(sender.state == UIGestureRecognizerStateChanged) {
        UIView *view = getContentView(self);
        if (view) applyPinch(view, sender);
    }
}

-(void)_handleRotationGesture:(UIRotationGestureRecognizer *)sender {
    if(isLocked) %orig;
}

// -- iOS 14+ / 17 Handlers (Container Fallback) --
-(void)handlePanGesture:(UIPanGestureRecognizer *)sender {
    if(isLocked) %orig;
    else if(sender.state == UIGestureRecognizerStateChanged) {
        UIView *view = getContentView(self);
        if (view) applyPan(view, sender);
    }
}

-(void)setContentViewPadding:(UIEdgeInsets)arg1 animationDuration:(double)arg2 animationOptions:(unsigned long long)arg3 {
    // Disable automatic padding updates in Free mode
    if(isLocked) %orig;
}

-(void)setContentViewPadding:(UIEdgeInsets)arg1 {
    if(!isLocked) arg1 = UIEdgeInsetsZero;
    %orig(arg1);
}

// -- New Methods --

%new
-(void)handleLongPressGesture:(UILongPressGestureRecognizer *)sender {
    if (sender.state != UIGestureRecognizerStateBegan) return;
    
    isLocked = !isLocked; // Toggle state
    [self setupBorder];
}

%new
-(void)setupBorder {
    UIView *view = getContentView(self);
    if (!view) return;
    
    // Visual feedback: Red border when Locked (Native Snap), No border when Free
    if (isLocked) {
        view.layer.borderWidth = 2.0;
        view.layer.borderColor = [UIColor redColor].CGColor;
    } else {
        view.layer.borderWidth = 0.0;
    }
}

%end
%end // SBPIPContainerHooks


// --- Hooks: Interaction Controller (Handles Gestures on Modern iOS) ---

%group SBPIPInteractionHooks
%hook SBPIPInteractionController

-(void)handlePanGesture:(UIPanGestureRecognizer *)sender {
    if(isLocked) %orig;
    else if(sender.state == UIGestureRecognizerStateChanged) {
        UIView *view = getTargetView(self, sender);
        if (view) applyPan(view, sender);
    }
}

-(void)handlePinchGesture:(UIPinchGestureRecognizer *)sender {
    if(isLocked) %orig;
    else if(sender.state == UIGestureRecognizerStateChanged) {
        UIView *view = getTargetView(self, sender);
        if (view) applyPinch(view, sender);
    }
}

-(void)handleRotationGesture:(UIRotationGestureRecognizer *)sender {
    if(isLocked) %orig;
}

%end
%end // SBPIPInteractionHooks


// --- Initialization ---

%ctor {
    %init(SBPIPContainerHooks);

    // Only check for the interaction controller class (iOS 14+)
    if (objc_getClass("SBPIPInteractionController")) {
        %init(SBPIPInteractionHooks);
    }
}