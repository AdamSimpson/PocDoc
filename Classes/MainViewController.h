//
//  MainViewController.h
//  PocDoc
//
//  Created by Atrain on 6/17/10.
//  Copyright University of Cincinnati 2010. All rights reserved.
//

#import "FlipsideViewController.h"

@class AnalyzeAudio;

@interface MainViewController : UIViewController <FlipsideViewControllerDelegate> {
	IBOutlet UILabel	*statusLabel;
	IBOutlet UILabel	*angleLabel;
	IBOutlet UIButton	*analyzeButton;
	IBOutlet UIButton	*calibrateButton;
	
	IBOutlet UIImageView *gaugeFrontView;
    IBOutlet UIImageView *gaugeNeedleView;
	IBOutlet UIActivityIndicatorView *analyzingIndicator;
    
	AnalyzeAudio *analyzeAudio;
}

- (IBAction)showInfo:(id)sender;

- (IBAction)analyzeButtonPressed:(UIButton*)sender;
- (IBAction)calibrateButtonPressed:(UIButton*)sender;
- (void)rotateGaugeArm:(float)fromAngle:(float)toAngle;
- (void)loadSubViews;

@property (nonatomic, retain) UILabel	*statusLabel;
@property (nonatomic, retain) UILabel	*angleLabel;
@property (nonatomic, retain) UIButton	*analyzeButton;
@property (nonatomic, retain) UIButton	*calibrateButton;
@property (nonatomic, assign) AnalyzeAudio *analyzeAudio;
@property (nonatomic, assign) IBOutlet UIImageView *gaugeNeedleView;
@property (nonatomic, assign) IBOutlet UIImageView *gaugeFrontView;
@property (nonatomic, retain) UIActivityIndicatorView *analyzingIndicator;

@end
