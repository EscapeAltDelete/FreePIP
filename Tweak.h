@interface PGPictureInPictureViewController : UIViewController
@end

@interface SBPIPInteractionController : NSObject
@property (nonatomic, readonly) UIView *targetView; // iOS 15+ property often
-(UIView *)targetView; // Method accessor
-(void)handlePanGesture:(UIPanGestureRecognizer *)arg1;
-(void)handlePinchGesture:(UIPinchGestureRecognizer *)arg1;
-(void)handleRotationGesture:(UIRotationGestureRecognizer *)arg1;
@end

@interface SBPIPContainerViewController : UIViewController
// iOS 15+
-(PGPictureInPictureViewController *)contentViewController; 
// iOS <= 14
-(PGPictureInPictureViewController *)pictureInPictureViewController; 

// Gesture handlers (names vary by iOS version)
-(void)_handlePanGesture:(UIPanGestureRecognizer *)arg1;
-(void)_handleRotationGesture:(UIRotationGestureRecognizer *)arg1;
-(void)_handlePinchGesture:(UIPinchGestureRecognizer *)arg1;
-(void)handlePanGesture:(UIPanGestureRecognizer *)arg1; // Possible iOS 17 variant

// Custom methods
-(void)setupBorder;
-(void)handleLongPressGesture:(UILongPressGestureRecognizer *)sender;
@end