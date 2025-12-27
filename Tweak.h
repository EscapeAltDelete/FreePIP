@interface PGPictureInPictureViewController : UIViewController
@end

@interface SBPIPInteractionController : NSObject
@property (nonatomic, readonly) UIView *targetView;
-(UIView *)targetView;
-(void)handlePanGesture:(UIPanGestureRecognizer *)arg1;
-(void)handlePinchGesture:(UIPinchGestureRecognizer *)arg1;
-(void)handleRotationGesture:(UIRotationGestureRecognizer *)arg1;
@end

@interface SBPIPContainerViewController : UIViewController
-(PGPictureInPictureViewController *)contentViewController; // iOS 15+
-(PGPictureInPictureViewController *)pictureInPictureViewController; // Legacy

-(void)_handlePanGesture:(UIPanGestureRecognizer *)arg1;
-(void)_handleRotationGesture:(UIRotationGestureRecognizer *)arg1;
-(void)_handlePinchGesture:(UIPinchGestureRecognizer *)arg1;
-(void)handlePanGesture:(UIPanGestureRecognizer *)arg1; 

-(void)setupBorder;
-(void)handleLongPressGesture:(UILongPressGestureRecognizer *)sender;
@end