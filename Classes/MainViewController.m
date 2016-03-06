//
//  MainViewController.m
//  PocDoc
//
//  Created by Atrain on 6/17/10.
//  Copyright University of Cincinnati 2010. All rights reserved.
//

#import "MainViewController.h"
#import "AnalyzeAudio.h"

@implementation MainViewController

@synthesize statusLabel;
@synthesize angleLabel;
@synthesize analyzeButton;
@synthesize calibrateButton;
@synthesize analyzeAudio;
@synthesize gaugeNeedleView;
@synthesize gaugeFrontView;
@synthesize analyzingIndicator;


//View stuff shouldnt be in viewDidLoad

//Loads guage view- no longer neccesary so I should infact delete this!
-(void)loadSubViews
{
    // set up guage image
//    UIImageView *gaugeFront = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Gauge2.png"]];
//    [gaugeFront setCenter:[[self view] center]];
//    [gaugeFront setOpaque:YES];
    
    // Set up the guage arm.
//    gaugeNeedleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"GaugeNeedle.png"]];
//	[gaugeNeedleView setCenter:[[self view] center]];
//    [gaugeNeedleView setOpaque:YES];
    
    // Add the views in proper order and location.
//    [[self view] addSubview:gaugeFrontView];
//    [gaugeFrontView addSubview:gaugeNeedleView];
	
	// Move the anchor point so rotations occur around that point.
//    gaugeNeedleView.layer.anchorPoint = CGPointMake(0.0, 0.0);
	
	//	CGFloat centerY = self.center.y + (self.bounds.size.height/2);
	//	gaugeNeedleView.center = CGPointMake(self.center.x, centerY);
	
//    [gaugeFront release]; 
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    
	// Move the anchor point of the needle so it rotates about bottom
	gaugeNeedleView.layer.anchorPoint = CGPointMake(0.5, 1.0);
	
	//anchorPoint throws off the centering of the needle as well so we must recenter
	CGFloat centerY = gaugeNeedleView.center.y + (gaugeNeedleView.bounds.size.height/2);
	gaugeNeedleView.center = CGPointMake(gaugeNeedleView.center.x, centerY);
	
	//rotate needle to off position
	 CATransform3D rotationTransform = CATransform3DIdentity;
	 rotationTransform = CATransform3DRotate(rotationTransform, -3.14/2.0, 0.0, 0.0, 1.0);
	 gaugeNeedleView.layer.transform = rotationTransform;
	 
	 
	self.analyzeAudio = [[AnalyzeAudio alloc] init];
	[analyzeAudio initAnalyze: self];
}

//Rotates the needle arm from fromAngle to toAngle in radians
- (void)rotateGaugeArm:(float)fromAngle:(float)toAngle
{
    /*
    //Rotate without animation
    CATransform3D rotationTransform = CATransform3DIdentity;
    rotationTransform = CATransform3DRotate(rotationTransform, 3.14/3.0, 0.0, 0.0, 1.0);
    gaugeNeedleView.layer.transform = rotationTransform;
    */
	
    // Create rotation animation around z axis.
    CABasicAnimation *rotateAnimation = [CABasicAnimation animation];
    rotateAnimation.keyPath = @"transform.rotation.z";
    rotateAnimation.fromValue = [NSNumber numberWithFloat:fromAngle];
    rotateAnimation.toValue = [NSNumber numberWithFloat:toAngle];
    rotateAnimation.duration = 1.5;
    rotateAnimation.removedOnCompletion = NO;
    // leaves presentation layer in final state; preventing snap-back to original state
    rotateAnimation.fillMode = kCAFillModeBoth; 
    rotateAnimation.repeatCount = 0;
    rotateAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    
    // Add the animation to the selection layer. This causes it to begin animating. 
    [gaugeNeedleView.layer addAnimation:rotateAnimation forKey:@"rotateAnimation"];

}

- (IBAction)analyzeButtonPressed:(UIButton*)sender
{
	statusLabel.text = @"Please Wait...";
	[analyzeAudio startAnalysis];
}

- (IBAction)calibrateButtonPressed:(UIButton*)sender
{
	statusLabel.text = @"Please Wait...";
	[analyzeAudio startCalibration];
}

- (void)flipsideViewControllerDidFinish:(FlipsideViewController *)controller {
    
	[self dismissModalViewControllerAnimated:YES];
}


- (IBAction)showInfo:(id)sender {    
	
	FlipsideViewController *controller = [[FlipsideViewController alloc] initWithNibName:@"FlipsideView" bundle:nil];
	controller.delegate = self;
	
	//We must pass in our analyzedAudio instance so that controller can access it's data
	[controller setAnalyzedAudio:[self analyzeAudio]];
	
	//If there is no data to display or it is currently analyzing issue popup message and release controller
	if (![analyzeAudio hasData] || [analyzeAudio isAnalyzing]) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"No Data!"
													   delegate:(NSString*)nil cancelButtonTitle:@"Ok" otherButtonTitles:(NSString*)nil];
		[alert show];
		[alert release];
		
		[controller release];
		
		return;
	}
	
	controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	[self presentModalViewController:controller animated:YES];
	
	[controller release];
}


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc. that aren't in use.
}


- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}



// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations.
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
//	return YES;
}



- (void)dealloc {
    [super dealloc];
	
	[statusLabel release];
	[analyzeButton release];
	
	[analyzeAudio release];
}


@end
