//
//  FlipsideViewController.m
//  PocDoc
//
//  Created by Atrain on 6/17/10.
//  Copyright University of Cincinnati 2010. All rights reserved.
//

#import "FlipsideViewController.h"
#import "AnalyzeAudio.h"
#import "PHPupload.h"

@implementation FlipsideViewController

@synthesize delegate;

@synthesize analyzedAudio;
@synthesize dataForPlot;
@synthesize dataForMinAnglePlot;
@synthesize dataForMaxAnglePlot;
@synthesize uploadButton;
@synthesize calibrateButton;

-(void)viewDidLoad
{
    [super viewDidLoad];
	
    // Create graph from theme
    graph = [[CPXYGraph alloc] initWithFrame:CGRectZero];
	CPTheme *theme = [CPTheme themeNamed:kCPDarkGradientTheme];
    [graph applyTheme:theme];
	
	//	CPLayerHostingView *hostingView = (CPLayerHostingView *)[[self.view subviews] objectAtIndex:1];
	CPGraphHostingView *hostingView = (CPGraphHostingView *)[self.view viewWithTag:7];
	//	CPLayerHostingView *hostingView = (CPLayerHostingView *) self.view;
	
    hostingView.hostedGraph = graph;
	
    graph.paddingLeft = 10.0;
	graph.paddingTop = 10.0;
	graph.paddingRight = 10.0;
	graph.paddingBottom = 10.0;
    
    // Setup plot space
	float maxVal = [[[analyzedAudio normReal] valueForKeyPath:@"@max.floatValue"] floatValue] + 1.0;
	
    CPXYPlotSpace *plotSpace = (CPXYPlotSpace *)graph.defaultPlotSpace;
    plotSpace.allowsUserInteraction = YES;
    plotSpace.xRange = [CPPlotRange plotRangeWithLocation:CPDecimalFromFloat(1200.0) length:CPDecimalFromFloat(4100.0)];
    plotSpace.yRange = [CPPlotRange plotRangeWithLocation:CPDecimalFromFloat(-maxVal) length:CPDecimalFromFloat(2*maxVal)];
	
    // Axes
	CPXYAxisSet *axisSet = (CPXYAxisSet *)graph.axisSet;
    CPXYAxis *x = axisSet.xAxis;
    x.majorIntervalLength = CPDecimalFromString(@"1000");
    x.orthogonalCoordinateDecimal = CPDecimalFromString(@"0");
    x.minorTicksPerInterval = 10;
	
    CPXYAxis *y = axisSet.yAxis;
    y.majorIntervalLength = CPDecimalFromString(@"5");
    y.minorTicksPerInterval = 4;
    y.orthogonalCoordinateDecimal = CPDecimalFromString(@"0");
	
	// Create a blue plot area
	CPScatterPlot *boundLinePlot = [[[CPScatterPlot alloc] init] autorelease];
    boundLinePlot.identifier = @"Fourier Coeffs";
	boundLinePlot.dataLineStyle.miterLimit = 1.0f;
	boundLinePlot.dataLineStyle.lineWidth = 1.0f;
	boundLinePlot.dataLineStyle.lineColor = [CPColor blueColor];
    boundLinePlot.dataSource = self;
	[graph addPlot:boundLinePlot];

	// Add plot symbols
	CPLineStyle *symbolLineStyle = [CPLineStyle lineStyle];
	symbolLineStyle.lineColor = [CPColor blackColor];
	CPPlotSymbol *plotSymbol = [CPPlotSymbol ellipsePlotSymbol];
	plotSymbol.fill = [CPFill fillWithColor:[CPColor blueColor]];
	plotSymbol.lineStyle = symbolLineStyle;
    plotSymbol.size = CGSizeMake(2.0, 2.0);
    boundLinePlot.plotSymbol = plotSymbol;
	
    //initial data for main frequency responce plot
	NSMutableArray *contentArray = [NSMutableArray arrayWithCapacity:[analyzedAudio numFreqs]];
	
	for (NSUInteger i = 0; i < [analyzedAudio numFreqs]; i++ ) {
		id x = [[analyzedAudio freqValues] objectAtIndex:i];
		id y = [[analyzedAudio normReal] objectAtIndex:i];
		[contentArray addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:x, @"x", y, @"y", nil]];
	}
	self.dataForPlot = contentArray;

	//If the slope doesnt occur at the beginning of the range plot the slope markers
	if ([analyzedAudio minSlopePosition] > 3 && [analyzedAudio maxSlopePosition] > 3) {
		NSLog(@"in slope action");
		// Create a minimum angle line
		CPScatterPlot *minAngleLinePlot = [[[CPScatterPlot alloc] init] autorelease];
		minAngleLinePlot.identifier = @"Min Angle Points";
		minAngleLinePlot.dataSource = self;
		[graph addPlot:minAngleLinePlot];
		minAngleLinePlot.dataLineStyle.miterLimit = 1.0f;
		minAngleLinePlot.dataLineStyle.lineWidth = 1.0f;
		minAngleLinePlot.dataLineStyle.lineColor = [CPColor redColor];
		
		CPPlotSymbol *plotSymbol2 = [CPPlotSymbol ellipsePlotSymbol];
		plotSymbol2.fill = [CPFill fillWithColor:[CPColor redColor]];
		plotSymbol2.size = CGSizeMake(5.0, 5.0);
	 //   minAngleLinePlot.plotSymbol = plotSymbol2;

		//Data for minAngle line
		NSMutableArray *tempMinAngle = [NSMutableArray arrayWithCapacity:2];
		//Extract info to calculate yIntercept and basepoint for draw line about
		uint pos = [analyzedAudio minSlopePosition];
		float midX = [[[analyzedAudio freqValuesSmooth] objectAtIndex:pos] floatValue];
		float midY = [[[analyzedAudio normRealSmooth] objectAtIndex:pos] floatValue];
		
		float slope = [[[analyzedAudio derivativeArray] objectAtIndex:pos] floatValue];
		float yIntercept = midY - slope*midX;

		//calculate 2 points to the "left" of the midpoint
		float midXminus = [[[analyzedAudio freqValuesSmooth] objectAtIndex:pos-3] floatValue];
		float midYminus = slope*midXminus + yIntercept;
		id xmin = [NSNumber numberWithFloat:midXminus];
		id ymin = [NSNumber numberWithFloat:midYminus];
		[tempMinAngle addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:xmin, @"x", ymin, @"y", nil]];
		
		//calculate 2 points to the "right" of the midppoint
		float midXplus = [[[analyzedAudio freqValuesSmooth] objectAtIndex:pos+3] floatValue];
		float midYplus = slope*midXplus + yIntercept;
		id xplus = [NSNumber numberWithFloat:midXplus];
		id yplus = [NSNumber numberWithFloat:midYplus];
		[tempMinAngle addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:xplus, @"x", yplus, @"y", nil]];
			
		self.dataForMinAnglePlot = tempMinAngle;

		// Create a maximum angle line
		CPScatterPlot *maxAngleLinePlot = [[[CPScatterPlot alloc] init] autorelease];
		maxAngleLinePlot.identifier = @"Max Angle Points";
		maxAngleLinePlot.dataSource = self;
		[graph addPlot:maxAngleLinePlot];
		maxAngleLinePlot.dataLineStyle.miterLimit = 1.0f;
		maxAngleLinePlot.dataLineStyle.lineWidth = 1.0f;
		maxAngleLinePlot.dataLineStyle.lineColor = [CPColor redColor];
	//	maxAngleLinePlot.plotSymbol = plotSymbol2;

		//Data for maxAngle line
		NSMutableArray *tempMaxAngle = [NSMutableArray arrayWithCapacity:2];
		//Extract info to calculate yIntercept and basepoint for draw line about
		pos = [analyzedAudio maxSlopePosition];
		midX = [[[analyzedAudio freqValuesSmooth] objectAtIndex:pos] floatValue];
		midY = [[[analyzedAudio normRealSmooth] objectAtIndex:pos] floatValue];
		
		slope = [[[analyzedAudio derivativeArray] objectAtIndex:pos] floatValue];
		yIntercept = midY - slope*midX;
		
		//calculate 2 points to the "left" of the midpoint
		midXminus = [[[analyzedAudio freqValuesSmooth] objectAtIndex:pos-3] floatValue];
		midYminus = slope*midXminus + yIntercept;
		xmin = [NSNumber numberWithFloat:midXminus];
		ymin = [NSNumber numberWithFloat:midYminus];
		[tempMaxAngle addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:xmin, @"x", ymin, @"y", nil]];
		
		//calculate 2 points to the "right" of the midppoint
		midXplus = [[[analyzedAudio freqValuesSmooth] objectAtIndex:pos+3] floatValue];
		midYplus = slope*midXplus + yIntercept;
		xplus = [NSNumber numberWithFloat:midXplus];
		yplus = [NSNumber numberWithFloat:midYplus];
		[tempMaxAngle addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:xplus, @"x", yplus, @"y", nil]];
		
		self.dataForMaxAnglePlot = tempMaxAngle;
	}
}

- (IBAction)calibrateButtonPressed//:(UIButton*)sender
{
//	statusLabel.text = @"Please Wait...";
	[[self analyzedAudio] startCalibration];
}

//Upload image of plot to server
- (IBAction)uploadData//:(UIButton*)sender
{
    //turn plot into UIImage
//    UIImage *image =[graph imageOfLayer];
//    [PHPupload uploadImage:image];  
	
	//Upload the file
    NSLog(@"dong");
    [PHPupload uploadText:[analyzedAudio patientDataFilePath]];
}

#pragma mark Plot Data Source Methods

-(NSUInteger)numberOfRecordsForPlot:(CPPlot *)plot {
	if ([(NSString *)plot.identifier isEqualToString:@"Fourier Coeffs"])
		return [dataForPlot count];
	else
		return 2;

}

-(NSNumber *)numberForPlot:(CPPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index 
{
	NSNumber *num;
	
	if ([(NSString *)plot.identifier isEqualToString:@"Fourier Coeffs"])
	{
		num = [[dataForPlot objectAtIndex:index] valueForKey:(fieldEnum == CPScatterPlotFieldX ? @"x" : @"y")];
	}

	//Add data to indicate angle	
	else if ([(NSString *)plot.identifier isEqualToString:@"Min Angle Points"])
	{
		num = [[dataForMinAnglePlot objectAtIndex:index] valueForKey:(fieldEnum == CPScatterPlotFieldX ? @"x" : @"y")];
	}
	else if ([(NSString *)plot.identifier isEqualToString:@"Max Angle Points"])
	{
		num = [[dataForMaxAnglePlot objectAtIndex:index] valueForKey:(fieldEnum == CPScatterPlotFieldX ? @"x" : @"y")];
	}
	else
        num = 0;
    
    return num;
}


- (IBAction)done:(id)sender {
	[self.delegate flipsideViewControllerDidFinish:self];	
}


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}


- (void)viewDidUnload {
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


/*
-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
//	return YES;
}
*/

#pragma mark 

- (void)dealloc {
	[dataForMinAnglePlot release];
	[dataForPlot release];
    [super dealloc];
}

@end
