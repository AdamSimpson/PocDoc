//
//  FlipsideViewController.h
//  PocDoc
//
//  Created by Atrain on 6/17/10.
//  Copyright University of Cincinnati 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AnalyzeAudio;

@protocol FlipsideViewControllerDelegate;


@interface FlipsideViewController : UIViewController <CPPlotDataSource>
{
	id <FlipsideViewControllerDelegate> delegate;
	
	AnalyzeAudio *analyzedAudio;
	CPXYGraph *graph;
	NSMutableArray *dataForPlot;
	NSMutableArray *dataForMinAnglePlot;
	NSMutableArray *dataForMaxAnglePlot;
    
    IBOutlet UIButton *uploadButton;
	IBOutlet UIButton *calibrateButton;
}

@property (nonatomic, assign) AnalyzeAudio *analyzedAudio;
@property(readwrite, retain, nonatomic) NSMutableArray *dataForPlot;
@property(readwrite, retain, nonatomic) NSMutableArray *dataForMinAnglePlot;
@property(readwrite, retain, nonatomic) NSMutableArray *dataForMaxAnglePlot;

@property (nonatomic, retain) UIButton *uploadButton;
- (IBAction)uploadData;//:(UIButton*)sender;

@property (nonatomic, retain) UIButton	*calibrateButton;
- (IBAction)calibrateButtonPressed;//:(UIButton*)sender;

@property (nonatomic, assign) id <FlipsideViewControllerDelegate> delegate;
- (IBAction)done:(id)sender;
@end


@protocol FlipsideViewControllerDelegate
- (void)flipsideViewControllerDidFinish:(FlipsideViewController *)controller;
@end

