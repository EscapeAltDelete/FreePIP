#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "Tweak.h"

#define UIViewParentController(__view) ({ \
        UIResponder *__responder = __view; \
        while ([__responder isKindOfClass:[UIView class]]) \
        __responder = [__responder nextResponder]; \
        (UIViewController *)__responder; \
    })

static BOOL locked = NO;

// Safely get content view on any iOS version
static UIView *getContentView(SBPIPContainerViewController *self) {
    if ([self respondsToSelector:@selector(contentViewController)]) {
        return self.contentViewController.view;
    }
    if ([self respondsToSelector:@selector(pictureInPictureViewController)]) {
        return self.pictureInPictureViewController.view;
    }
    return nil;
}

// Safely get target view from interaction controller
static UIView *getTargetView(SBPIPInteractionController *self, UIGestureRecognizer *sender) {
    if ([self respondsToSelector:@selector(targetView)])
        return [self targetView];
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

// --- Group: Container Hooks (Basic UI setup) ---
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

// iOS 13/Legacy Style Gestures
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

// iOS 14+ / 17 Potential Style
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
    locked = !locked; 
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
%end 


// --- Group: Interaction Hooks (Primary gesture handler for modern iOS) ---
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
%end


%ctor {
    // Always initialize container hooks for visual setup
    %init(SBPIPContainerHooks);

    // Only hook interaction controller if it exists (iOS 14-17 check)
    if (objc_getClass("SBPIPInteractionController")) {
        %init(SBPIPInteractionHooks);
    }
}
```[[1](https://www.google.com/url?sa=E&q=https%3A%2F%2Fvertexaisearch.cloud.google.com%2Fgrounding-api-redirect%2FAUZIYQHW-bSfoYd5QWeeKTUHBukDuovamceJEV7pp0ZQD8fPs89Ek4jmtTADpfROk2Xw4c9xTxGWGVDO0KyrIOgKYpiRo4HHQIVVnCbFHQ-NNMZpL_fiMlu4l4k-GXfAGUmsRIu3_-Q4TxzsBRw4q17xCrBkeaLXP7mDV4gL3g8%3D)]