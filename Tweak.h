@interface PGPictureInPictureViewController : UIViewController
@end

@interface SBPIPInteractionController : NSObject
@property (nonatomic, readonly) UIView *targetView; // iOS 15+ property
-(UIView *)targetView; // Method accessor fallback
-(void)handlePanGesture:(UIPanGestureRecognizer *)arg1;
-(void)handlePinchGesture:(UIPinchGestureRecognizer *)arg1;
-(void)handleRotationGesture:(UIRotationGestureRecognizer *)arg1;
@end

@interface SBPIPContainerViewController : UIViewController
// iOS 15+ standard
-(PGPictureInPictureViewController *)contentViewController; 
// Legacy
-(PGPictureInPictureViewController *)pictureInPictureViewController; 

// Gestures
-(void)_handlePanGesture:(UIPanGestureRecognizer *)arg1;
-(void)_handleRotationGesture:(UIRotationGestureRecognizer *)arg1;
-(void)_handlePinchGesture:(UIPinchGestureRecognizer *)arg1;
-(void)handlePanGesture:(UIPanGestureRecognizer *)arg1; // Possible variant

-(void)setupBorder;
-(void)handleLongPressGesture:(UILongPressGestureRecognizer *)sender;
@end