@interface PGPictureInPictureViewController : UIViewController
@end

@interface SBPIPInteractionController : NSObject
@property (nonatomic, readonly) UIView *targetView; // iOS 15+ property
-(UIView *)targetView; // Fallback accessor
-(void)handlePanGesture:(UIPanGestureRecognizer *)arg1;
-(void)handlePinchGesture:(UIPinchGestureRecognizer *)arg1;
-(void)handleRotationGesture:(UIRotationGestureRecognizer *)arg1;
@end

@interface SBPIPContainerViewController : UIViewController
// iOS 15+
-(PGPictureInPictureViewController *)contentViewController; 
// Legacy
-(PGPictureInPictureViewController *)pictureInPictureViewController; 

// Gestures
-(void)_handlePanGesture:(UIPanGestureRecognizer *)arg1;
-(void)_handleRotationGesture:(UIRotationGestureRecognizer *)arg1;
-(void)_handlePinchGesture:(UIPinchGestureRecognizer *)arg1;
-(void)handlePanGesture:(UIPanGestureRecognizer *)arg1; 

// Custom
-(void)setupBorder;
-(void)handleLongPressGesture:(UILongPressGestureRecognizer *)sender;
@end