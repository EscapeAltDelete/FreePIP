@interface PGPictureInPictureViewController : UIViewController
@end

@interface SBPIPInteractionController : NSObject
// Defines safe access to targetView
@property (nonatomic, readonly) UIView *targetView;
-(UIView *)targetView;
-(void)handlePanGesture:(UIPanGestureRecognizer *)arg1;
-(void)handlePinchGesture:(UIPinchGestureRecognizer *)arg1;
-(void)handleRotationGesture:(UIRotationGestureRecognizer *)arg1;
@end

@interface SBPIPContainerViewController : UIViewController
// iOS 15/16/17 use contentViewController
-(PGPictureInPictureViewController *)contentViewController; 
// Legacy fallback
-(PGPictureInPictureViewController *)pictureInPictureViewController; 

// Potential gesture handlers
-(void)_handlePanGesture:(UIPanGestureRecognizer *)arg1;
-(void)_handleRotationGesture:(UIRotationGestureRecognizer *)arg1;
-(void)_handlePinchGesture:(UIPinchGestureRecognizer *)arg1;
-(void)handlePanGesture:(UIPanGestureRecognizer *)arg1; 

// Custom added methods
-(void)setupBorder;
-(void)handleLongPressGesture:(UILongPressGestureRecognizer *)sender;
@end