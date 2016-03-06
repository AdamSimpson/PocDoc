//
//  AnalyzeAudio.mm
//  PocDoc
//
//  Created by Adam Simpson on 6/4/10.
//  Copyright 2010 University of Cincinnati. All rights reserved.
//

#import "AnalyzeAudio.h"
#import "MainViewController.h"
#import "PHPupload.h"

@implementation AnalyzeAudio

@synthesize audioSession;
@synthesize player;
@synthesize recorder;
@synthesize viewController;
@synthesize isAnalyzing;
@synthesize recordFileURL;
@synthesize nsObtainedReal;
@synthesize normReal;
@synthesize hasData;
@synthesize numFreqs;
@synthesize freqFilePath;
@synthesize freqValues;
@synthesize normFilePath;
@synthesize normValues;
@synthesize processIsCalibration;
@synthesize derivativeArray;
@synthesize normRealSmooth;
@synthesize maxSlopePosition;
@synthesize minSlopePosition;
@synthesize freqValuesSmooth;
@synthesize adjustedAngle;
@synthesize patientDataFilePath;

//////////////Multiplied slope by 260 in calculatenagle2

//Calculate smoothed frequies when taking derivative
//Deal with extra deriviative array points better
//Normalized to max 1 data makes angle over a shorter range

#pragma mark Initialization methods
///////////////////////////////////////////////////////////////////////////
//Initialize all audio resources
///////////////////////////////////////////////////////////////////////////
-(void)initAudio
{			
	///////////////////////////////////////////////////////////////////////////
	//Setup AudioSession
	///////////////////////////////////////////////////////////////////////////
	[self setAudioSession: [AVAudioSession sharedInstance]];
	NSError *err = nil;
	[audioSession setCategory :AVAudioSessionCategoryPlayAndRecord error:&err];
	[audioSession setDelegate: self];
	[audioSession setActive: YES error: nil];
	[audioSession setPreferredHardwareSampleRate:32768.0 error:&err]; //48000 Push the limits of 3GS...Iphone4?
//	[audioSession setPreferredIOBufferDuration:.005 error: nil];
/*	UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;
	AudioSessionSetProperty (kAudioSessionProperty_OverrideAudioRoute,
							 sizeof(audioRouteOverride),&audioRouteOverride);*/
	
	NSLog(@"SampleRate: %f",[audioSession preferredHardwareSampleRate]);
	NSLog(@"Current Rate: %f",[audioSession currentHardwareSampleRate]);
	
	///////////////////////////////////////////////////////////////////////////
	//Setup Audio Player
	///////////////////////////////////////////////////////////////////////////
	//Set filepath for sound file to play
	NSString *soundFilePath = [[NSBundle mainBundle] pathForResource: @"SumWave131" ofType: @"wav"];
	//[[NSBundle mainBundle] pathForResource: @"longChirp" ofType: @"wav"];
	
	//Create soundfile URL
	NSURL *fileURL = [[NSURL alloc] initFileURLWithPath: soundFilePath];
	
	//Allocate sound player
	AVAudioPlayer *newPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:nil];
	[fileURL release];
	[self setPlayer: newPlayer];
	[newPlayer release];
	
	[[self player] setVolume:1.0];  // available range is 0.0 through 1.0
	
	[[self player] setDelegate: self];//AnalyzeAudio will handle delegate methods
	
	[[self player] prepareToPlay]; //preloads buffers and acquires audio hardware needed for playback
	
	///////////////////////////////////////////////////////////////////////////
	//Setup Audio Recorder
	///////////////////////////////////////////////////////////////////////////
	
	//Obtain path to documents directory
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSString *recordFilePath = [NSString stringWithFormat:@"%@/recorded.caf", documentsDirectory];
	
//    NSString *recordFilePath = [documentsDirectory stringByAppendingString: @"recorded.caf"];
	
	//Set the URL for recorded audio
    [self setRecordFileURL: [[NSURL alloc] initFileURLWithPath: recordFilePath]];
	
	//Main Recording settings:
	NSDictionary *recordSettings = [[NSDictionary alloc] initWithObjectsAndKeys:
									[NSNumber numberWithFloat: 32768.0], AVSampleRateKey, //48kHz max for Mic on iphone 3gs
									[NSNumber numberWithInt: 1], AVNumberOfChannelsKey,
									//[NSNumber numberWithInt: AVAudioQualityMax], AVEncoderAudioQualityKey,//Needed for PCM?									
									//[NSNumber numberWithInt:AVAudioQualityMax],  AVSampleRateConverterAudioQualityKey, //Needed for PCM?
									[NSNumber numberWithInt: kAudioFormatLinearPCM], AVFormatIDKey,
									[NSNumber numberWithInt: 32], AVLinearPCMBitDepthKey, //32 bit max(for now atleast?)
									[NSNumber numberWithBool: NO], AVLinearPCMIsBigEndianKey,
									[NSNumber numberWithBool: YES], AVLinearPCMIsFloatKey,
									nil];
	
	AVAudioRecorder *newRecorder = [[AVAudioRecorder alloc] initWithURL: recordFileURL
															   settings: recordSettings error: nil];
	[recordSettings release];
	[self setRecorder: newRecorder];
	[newRecorder release];
	
	[recorder setDelegate: self];
	[recorder prepareToRecord]; //Creates file and prepares to record	
}

///////////////////////////////////////////////////////////////////////////
//Initialize all FFT resources
///////////////////////////////////////////////////////////////////////////
-(void)initFFT
{	
	
	///////////////////////////////////////////////////////////////////////////
	//Read in superposition frequencies
	///////////////////////////////////////////////////////////////////////////
	[self setFreqFilePath:[[NSBundle mainBundle] pathForResource: @"supFreqs131" ofType: nil]];
	NSArray *tempFreqArray = [[NSArray alloc] initWithContentsOfFile:freqFilePath];
	[self setFreqValues:tempFreqArray];
	[tempFreqArray release];
	//Number of frequencies that make up the audio signal
	[self setNumFreqs:[freqValues count]];
	
	
	//FFT paramaters
	log2n = 15; //2^log2n elements long
	n = 1 << log2n; //actual number of elements long
	stride = 1; //step through vectors 1 at a time
	nOver2 = n/2; //some results only n/2 elements long
	
	///////////////////////////////////////////////////////////////////////////
	//Allocate memory for the input operands and check its availability,
	//use the vector version to get 16-byte alignment.
	///////////////////////////////////////////////////////////////////////////
	output.realp = (float *) malloc(nOver2 * sizeof(float));
    output.imagp = (float *) malloc(nOver2 * sizeof(float));
    originalReal = (float *) malloc(n * sizeof(float));
	obtainedReal = (float *) malloc(nOver2 * sizeof(float));
	window = (float *) malloc(n * sizeof(float));
	windowedReal = (float *) malloc(n* sizeof(float)); 
	//Make sure all arrays allocated properly
    if (originalReal == NULL || output.realp == NULL || output.imagp == NULL || obtainedReal == NULL) {
        NSLog(@"\n FFT vectors failed to allocate memory \n");
		exit(0);
    }
	/* Set up the required memory for the FFT routines and check  its
     * availability. */
    setupReal = vDSP_create_fftsetup(log2n, FFT_RADIX2);
    if (setupReal == NULL) {
        NSLog(@"\n FFT_Setup creation failed \n");
		exit(0);
    }
	
	//Create window function vector
	vDSP_hann_window(window, n, vDSP_HANN_NORM);
	if (window == NULL) {
        NSLog(@"\n window vector creation failed\n");
		exit(0);
    }
	
	///////////////////////////////////////////////////////////////////////////
	//resources for opening recorded audio file
	///////////////////////////////////////////////////////////////////////////
	numFrames = n; //number of frames to read in from sourceFile
	//prepare struct that holds audio file info/data
	fillBufList.mNumberBuffers = 1;
	fillBufList.mBuffers[0].mNumberChannels = 1;
	fillBufList.mBuffers[0].mDataByteSize = sizeof(float)*n;
	fillBufList.mBuffers[0].mData = originalReal; //save file data into array
	
	//Final output packed into NSArray
	nsObtainedReal = [[NSMutableArray alloc] initWithCapacity:numFreqs];
	for (NSUInteger i=0; i<[self numFreqs]; i++) {
        [nsObtainedReal insertObject:[NSNumber numberWithFloat:0] atIndex:i];
	}
	
	//final normalized output of desired frequencies
	normReal = [[NSMutableArray alloc] initWithCapacity:numFreqs];
	for (NSUInteger i=0; i<[self numFreqs]; i++) {
        [normReal insertObject:[NSNumber numberWithFloat:0] atIndex:i];
	}

	//final normalized output of desired frequencies
	normRealSmooth = [[NSMutableArray alloc] initWithCapacity:numFreqs];
	for (NSUInteger i=0; i<[self numFreqs]; i++) {
        [normRealSmooth insertObject:[NSNumber numberWithFloat:0] atIndex:i];
	}
	
	//calculated derivative of normReal
	derivativeArray = [[NSMutableArray alloc] initWithCapacity:numFreqs];
	/////
	//THIS IS WRONG AND NEEDS CHANGED-DERIVATIVE USES SMOOTH DATA SO MORE THAN -1
	/////
	//numFreqs - 1 due to derivative loosing one point
	for (NSUInteger i=0; i<([self numFreqs]-1); i++) {
        [derivativeArray insertObject:[NSNumber numberWithFloat:0] atIndex:i];
	}
	
	//calculated derivative of normReal
	freqValuesSmooth = [[NSMutableArray alloc] initWithCapacity:numFreqs];
	/////
	//THIS IS WRONG AND NEEDS CHANGED-DERIVATIVE USES SMOOTH DATA SO MORE THAN -1
	/////
	//numFreqs - 1 due to derivative loosing one point
	for (NSUInteger i=0; i<([self numFreqs]-1); i++) {
        [freqValuesSmooth insertObject:[NSNumber numberWithFloat:0] atIndex:i];
	}
	
	///////////////////////////////////////////////////////////////////////////
	//Obtain path to documents directory
	///////////////////////////////////////////////////////////////////////////
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];

	///////////////////////////////////////////////////////////////////////////
	//Read in normilization values. If non exist use default supplied values
	///////////////////////////////////////////////////////////////////////////
	
	[self setNormFilePath:[NSString stringWithFormat:@"%@/normValues", documentsDirectory]];
	
	BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:normFilePath];
	
	//If user normalization file doesn't exist use default values
	if (!fileExists) {
		NSLog(@"No file found");
		[self setNormFilePath:[[NSBundle mainBundle] pathForResource: @"defaultNormValues131" ofType: nil]];
	}
	
	//set normilization array with values of some sort
	NSMutableArray *tempNormArray = [[NSMutableArray alloc] initWithContentsOfFile:normFilePath];
	[self setNormValues:tempNormArray];
	[tempNormArray release];
	
	NSLog(@"length norm: %d",[normValues count]);
	
	//Is not Analyzing and does not have fft data yet
	[self setIsAnalyzing:NO];
	[self setHasData:NO];
	[self setProcessIsCalibration:NO];
}

///////////////////////////////////////////////////////////////////////////
//Initializes all resources used by AnalyzeAudio: must be called before use
///////////////////////////////////////////////////////////////////////////
-(void)initAnalyze:(MainViewController*) viewControl
{
	//Passed in viewController so we can update the GUI
	[self setViewController: viewControl];
	
	[self initAudio];
	[self initFFT];
	
	[self setAdjustedAngle:180.0];
}

#pragma mark Analyze Methods
///////////////////////////////////////////////////////////////////////////
//Entry point for analysis: rest of process ensues continues on record stop
///////////////////////////////////////////////////////////////////////////
-(void)startAnalysis
{
	if ([self isAnalyzing] == NO) {
		[self setIsAnalyzing:YES];
		[[viewController analyzingIndicator] startAnimating];
        [[self player] play];
		[[self recorder] record];
	}
}

-(void)startCalibration
{
	if ([self isAnalyzing] == NO) {
		[self setIsAnalyzing:YES];
		[self setProcessIsCalibration:YES];
        [[self player] play];
		[[self recorder] record];
	}
}

/////////////////////////////////////////////////////////////////////////
//preform single precision fft from recorded audio - a mix of c and objc
/////////////////////////////////////////////////////////////////////////
-(void)fft
{			
	///////////////////////////////////////////////////////////////////////////
	//Read in signal to originalReal array using Extended Audio File Services
	//Can also use Audio File Services directly, perhaps more direct?
	///////////////////////////////////////////////////////////////////////////
	
	//Open recorded audio file
	ExtAudioFileOpenURL((CFURLRef)recordFileURL, &sourceFile);
	
	//Test if the number of samples is long enough to preform requested FFT
	OSStatus result;
	UInt32 dataSize;
	SInt64 frameCount;
	dataSize = sizeof(frameCount);
	result = ExtAudioFileGetProperty(sourceFile, kExtAudioFileProperty_FileLengthFrames, &dataSize, &frameCount);
	
	//fill buffers as defined in the AudioBufferList
	ExtAudioFileRead(sourceFile, &numFrames, &fillBufList);
	
	//Dispose of object and close file
	ExtAudioFileDispose(sourceFile);

	
	//If the recorded samples is shorter than requested FFT pad recording with zeros
	if (frameCount < numFrames) {
		NSLog(@"Warning: recording shorter than numFrames: %@, Padding with zeros", result); //Not sure result will print correctly
		uint padSize = frameCount - numFrames;
	
		for (uint i = numFrames; i < padSize; i++) {
			originalReal[i] = 0.0f;
		}
	}
	
	///////////////////////////////////////////////////////////////////////////
	//Apply window function to data
	///////////////////////////////////////////////////////////////////////////
	vDSP_vmul(originalReal, 1, window, 1, windowedReal, 1, n);
//	windowedReal = originalReal;
	
	/////////////////////////////////////////////////////////////////////////
	//preform FFT on windowed data and get real results
	/////////////////////////////////////////////////////////////////////////
	
	/* Look at the real signal as an interleaved complex vector  by
     * casting it.  Then call the transformation function vDSP_ctoz to
     * get a split complex vector, which for a real signal, divides into
     * an even-odd configuration. */
    vDSP_ctoz((COMPLEX *) windowedReal, 2, &output, 1, nOver2);
	
    //preform the actual FFT
    vDSP_fft_zrip(setupReal, &output, stride, log2n, FFT_FORWARD);
	
	//Take complex FFT'd vectors absolute magnitute so we have useful results
	vDSP_zvmags(&output, stride, obtainedReal, stride, nOver2);

	//Pack real values at frequencies of interest into NSArray
	uint freq;
	for (NSUInteger i=0; i<[self numFreqs]; i++) {
		freq = [[freqValues objectAtIndex:i] unsignedIntegerValue];// - 1; //"Must"(unless you don't subtract anything) subtract one as arrays are 0 indexed
        [nsObtainedReal replaceObjectAtIndex: i withObject:[NSNumber numberWithFloat:obtainedReal[freq]]];
	}
	
	/*
	/////////////////////////////////////////////////////////////////////////
	//Write full value of FFT to file
	/////////////////////////////////////////////////////////////////////////
	//final normalized output of desired frequencies
	NSMutableArray *nsDirty = [[NSMutableArray alloc] initWithCapacity:n];
	for (NSUInteger i=0; i<nOver2; i++) {
        [nsDirty insertObject:[NSNumber numberWithFloat:0] atIndex:i];
	}
	//Pack real values at frequencies of interest into NSArray
	for (NSUInteger i=0; i<nOver2; i++) {
        [nsDirty replaceObjectAtIndex: i withObject:[NSNumber numberWithFloat:obtainedReal[i]]];
	}
	NSString *tempDir = NSTemporaryDirectory();
	NSString *filePath = [tempDir stringByAppendingString: @"FULLFFT.txt"];
	NSError *werr = nil;
	NSStringEncoding enc = NSASCIIStringEncoding;
	[[nsDirty componentsJoinedByString:@" "] writeToFile:filePath atomically:YES encoding:enc error:&werr];	
	[nsDirty release];
	/////////////////////////////////////////////////////////////////////////
	//
	/////////////////////////////////////////////////////////////////////////
	*/
}

-(void)normalizeData
{	
	//Find maximum value of FFT points of interest so we can normalize our data
//	float maxVal = [[nsObtainedReal valueForKeyPath:@"@max.floatValue"] floatValue];
	
	float normVal;
	float obtainedVal;
	
	for (NSUInteger i = 0; i<[self numFreqs]; i++) {
		normVal = [[[self normValues] objectAtIndex:i] floatValue];
		obtainedVal = [[[self nsObtainedReal] objectAtIndex:i] floatValue];
		[normReal replaceObjectAtIndex: i withObject:[NSNumber numberWithFloat:(obtainedVal/normVal)]]; 
	}
	
	/*
	//Normalize final data so we can plot it with max(or min) value of 1
	float minVal = [[normReal valueForKeyPath:@"@min.floatValue"] floatValue];
	maxVal = [[normReal valueForKeyPath:@"@max.floatValue"] floatValue];
	float norm = maxVal>fabs(minVal)?maxVal:fabs(minVal);	
	
	for (NSUInteger i = 0; i<[self numFreqs]; i++) {
		obtainedVal = [[[self normReal] objectAtIndex:i] floatValue];
		[normReal replaceObjectAtIndex: i withObject:[NSNumber numberWithFloat:(obtainedVal/norm)]]; 
	}
	*/
	 
	//Used primarily to tell GUI we have valid data to display
	[self setHasData: YES];	
	
	NSLog(@"Array Length: %d", [normReal count]);
	
}

-(void)createCalibration
{	
	//Find maximum value of FFT points of interest so we can normalize our data
//	float maxVal = [[nsObtainedReal valueForKeyPath:@"@max.floatValue"] floatValue];
	
	//normalize data
//	float obtainedVal;
//	for (NSUInteger i = 0; i<[self numFreqs]; i++) {
//		obtainedVal = [[[self nsObtainedReal] objectAtIndex:i] floatValue];
//		[normValues replaceObjectAtIndex: i withObject:[NSNumber numberWithFloat:(obtainedVal/maxVal)]];
//	}
	
	[normValues setArray:nsObtainedReal];
	
	//save to file
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	[self setNormFilePath:[NSString stringWithFormat:@"%@/normValues", documentsDirectory]];
//	[normValues writeToFile:normFilePath atomically:NO];
	[nsObtainedReal writeToFile:normFilePath atomically:NO];
	
	[self setProcessIsCalibration:NO];
}

-(void)processRecording
{
	[self fft]; //preform FFT
	
	if ([self processIsCalibration]) {
		[self createCalibration];
	}
	else {
		[self normalizeData];
		[self movingAverage:normReal:normRealSmooth :2];
		[self movingAverage:freqValues:freqValuesSmooth :2];
		[self takeDerivative:freqValuesSmooth:normRealSmooth: derivativeArray];
//		float low = 177.3;//This is the lowest angle we can record, used to adjust the displayed angle between 0 and 180 degrees
		float rawAngle = [self calculateAngle2];
		float oldAdjustedAngle = [self adjustedAngle];
//		[self setAdjustedAngle: ((180.0/(180.0-low))*rawAngle - ((180.0*low)/(180.0-low)))];
		[self setAdjustedAngle:rawAngle];
		[self printLevel:ceil(rawAngle)];
		[[self viewController] rotateGaugeArm: (-1.0*oldAdjustedAngle+90)*3.14/180.0: (-1.0*adjustedAngle+90)*3.14/180];
		
		/////////////////////////////////////////////////////////////////////////
		//Write abs value of FFT to file and include patient data
		/////////////////////////////////////////////////////////////////////////	
		NSString *tempDir = NSTemporaryDirectory();
		
		//Get date and time information for filename
		NSDateFormatter *datetimeFormat = [[NSDateFormatter alloc] init];
		[datetimeFormat setDateFormat:@"yyyyMMddHHmmss"];
		
		NSDate *now = [[NSDate alloc] init];
		
		NSString *theDateTime = [datetimeFormat stringFromDate:now];
		
		[self setPatientDataFilePath:[NSString stringWithFormat:@"%@%@%@", tempDir, theDateTime, @".csv"]];
		NSLog(@"path: %@",patientDataFilePath);
	    
		NSError *werr = nil;
		NSStringEncoding enc = NSASCIIStringEncoding;
		//Actual data
		[[normReal componentsJoinedByString:@","] writeToFile:[self patientDataFilePath] atomically:YES encoding:enc error:&werr]; 
		//Append Patient Name to file
		NSFileHandle *myHandle = [NSFileHandle fileHandleForUpdatingAtPath:[self patientDataFilePath]];
		[myHandle seekToEndOfFile];
//		NSString *stringAngle = [NSString stringWithFormat:@"%@%@",[[NSNumber numberWithFloat:ceil(rawAngle)] stringValue],@"\u00B0"];
		NSString *stringAngle = [[NSNumber numberWithFloat:ceil(rawAngle)] stringValue];
		// convert the string to an NSData object
		NSString *extraData = [NSString stringWithFormat:@"\n%@%@\n%@%@\n%@%@\n%@%@", @"PATIENT,", @"John Doe", @"DATETIME,",theDateTime,@"ANGLE,",stringAngle,@"AGE,",@"25"];
		NSLog(@"string: %@ ", extraData);
		NSData *textData = [extraData dataUsingEncoding:enc];
		[myHandle writeData:textData];
		[myHandle closeFile];
		
		[now release];
		[datetimeFormat release];
	}
	 
}

#pragma mark AVAudioPlayer delegate methods
///////////////////////////////////////////////////////////////////////////
//Delegate methods for AVAudioPlayer
///////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////
//When audio is finished playing comence analyzing data
///////////////////////////////////////////////////////////////////////////
-(void)audioPlayerDidFinishPlaying: (AVAudioPlayer *) passedPlayer
					  successfully: (BOOL) completed 
{
	if ([passedPlayer isEqual:[self player]]) {

		//used to delay stop recording due to lag between delegate getting called and audio finish playing
		[recorder performSelector:@selector(stop) withObject:nil afterDelay:0.2];		
//		[[self recorder] stop]; //Stop recording
		
		NSLog(@"sucessful record");
		
		//If an error occurs during audio play
		if (completed == NO)
		{
			[[self player] prepareToPlay]; //preloads buffers and acquires audio hardware needed for playback
			[[self recorder] prepareToRecord]; //create file and prepare to record
			[viewController statusLabel].text = @"Error: Try Again";	//Tell GUI we have error
			NSLog(@"Error: Audio did not successfully complete playing");
		}
	}
}
///////////////////////////////////////////////////////////////////////////
//If audio is interupted stop playing and recording
///////////////////////////////////////////////////////////////////////////
-(void)audioPlayerBeginInterruption:(AVAudioPlayer *)passedPlayer
{
	if ([passedPlayer isEqual:[self player]]) {
		[[self player] stop];
		[[self recorder] stop];			
		NSLog(@"Interuption Begin: Audio did not successfully complete playing");
	}
}
///////////////////////////////////////////////////////////////////////////
//When interuption is done reset audio components
///////////////////////////////////////////////////////////////////////////
-(void)audioPlayerEndInterruption:(AVAudioPlayer *)passedPlayer
{	
	if ([passedPlayer isEqual:[self player]]) {
		[[self player] prepareToPlay]; //preloads buffers and acquires audio hardware needed for playback
		[[self recorder] prepareToRecord]; //create file and prepare to record
		NSLog(@"Interuption End: Audio did not successfully complete playing");
	}
}
///////////////////////////////////////////////////////////////////////////
//Error decoding input file
///////////////////////////////////////////////////////////////////////////
-(void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)passedPlayer error:(NSError *)error
{
	if ([passedPlayer isEqual:[self player]]) {
		[[self player ] stop];
		[[self recorder] stop];
		
		NSLog(@"Player Decode Error %@\n", error);
	}
}

#pragma mark AVAudioRecorder delegate methods
///////////////////////////////////////////////////////////////////////////
//Delegate methods for AVAudioRecorder
///////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////
//When audio is done recording move on with rest of analysis
///////////////////////////////////////////////////////////////////////////
-(void)audioRecorderDidFinishRecording:(AVAudioRecorder *)passedRecorder successfully:(BOOL) flag
{
	if ([passedRecorder isEqual:[self recorder]]) {
		///////////////////////////////////////////////////////////////////////////
		//When audio is done recording preform our fft, finish up
		///////////////////////////////////////////////////////////////////////////
		
		if (flag == YES) //If audio did record succesfully
		{
			[self processRecording];
			
			//Setup for another button press
			[[self player] prepareToPlay]; //preloads buffers and acquires audio hardware needed for playback
			
			//Can't call prepareToRecord if the audio file is to be extracted
			[[self recorder] prepareToRecord]; //Creates file and prepares to record
			
			//Tell GUI we have finished
			[viewController statusLabel].text = @"Ready to Record";
			
			//Done analyzing
			[self setIsAnalyzing:NO];
			[[viewController analyzingIndicator] stopAnimating];
			
		}
		else { //If audio did not record successfully
			[[self player] prepareToPlay]; //preloads buffers and acquires audio hardware needed for playback
			[[self recorder] prepareToRecord]; //create file and prepare to record
			[viewController statusLabel].text = @"Error: Try Again";	//Tell GUI we have error
			NSLog(@"Error: Audio did not successfully complete recording");
		}
	}
	
}
///////////////////////////////////////////////////////////////////////////
//If audio is interupted stop playing and recording
///////////////////////////////////////////////////////////////////////////
-(void)audioRecorderBeginInterruption:(AVAudioRecorder *)passedRecorder
{
	if ([passedRecorder isEqual:[self recorder]]) {
		[[self player] stop];
		[[self recorder] stop];
		NSLog(@"Interuption Begin: Audio did not successfully complete recording");
	}
}
///////////////////////////////////////////////////////////////////////////
//When interuption is done reset audio components
///////////////////////////////////////////////////////////////////////////
-(void)audioRecorderEndInterruption:(AVAudioRecorder *)passedRecorder
{
	if ([passedRecorder isEqual:[self recorder]]) {
		[[self player] prepareToPlay]; //preloads buffers and acquires audio hardware needed for playback
		[[self recorder] prepareToRecord]; //create file and prepare to record
		NSLog(@"Interuption End: Audio did not successfully complete recording");
	}
}
///////////////////////////////////////////////////////////////////////////
//Error decoding input file
///////////////////////////////////////////////////////////////////////////
-(void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)passedRecorder error:(NSError *)error
{
	if ([passedRecorder isEqual:[self recorder]]) {
		[[self player ] stop];
		[[self recorder] stop];
		
		NSLog(@"Recorder Decode Error %@\n", error);
	}
}

#pragma mark SignalProcessing
-(void)movingAverage:(NSArray*) inputArray:(NSMutableArray*)outputArray: (uint)numAverage
{	
	//If the number to average is 0 just return original array
	if (numAverage == 0) {
		[outputArray setArray:inputArray];
		return;
	}
	
	//Preform the moving average
	float sum, average;
	for (uint i = numAverage; i < [inputArray count]-numAverage; i++) {
		sum = 0.0;
		for (uint j = i-numAverage; j <= i+numAverage; j++) {
			sum += [[inputArray objectAtIndex:j] floatValue];
		}
		
		average = sum/(float)(2*numAverage+1);
		
		//Place average into outputarray
		[outputArray replaceObjectAtIndex:(i-numAverage) withObject:[NSNumber numberWithFloat:average]];
	}
	
	NSLog(@"outLength:%i",[outputArray count]);
	NSLog(@"rawL:%i", [inputArray count]);
}

-(void)takeDerivative:(NSArray*)inputArrayX:(NSArray*)inputArrayY:(NSMutableArray*)outputArray
{
	float fxMinus1,fxPlus1, fprime, step, xMinus1, xPlus1;
	
	//Compute the numeric derivative of our FFT data: f'(x) = (f(x+step)-f(x-step))/step
	for (uint i = 1; i<(([inputArrayX count]-1)-1); i++) {
		//FFT(x-step)
		fxMinus1 = [[inputArrayY objectAtIndex:(i-1)] floatValue];
		//FFT(x+step)
		fxPlus1 = [[inputArrayY objectAtIndex:(i+1)] floatValue];
		
		//frequency+step
		xPlus1 = [[inputArrayX objectAtIndex:(i+1)] floatValue];
		//frequency-step
		xMinus1 = [[inputArrayX objectAtIndex:(i-1)] floatValue];
		step = xPlus1-xMinus1;
		
		//Calculate the derivative, centered around frequency(i)
		fprime = (fxPlus1 - fxMinus1)/(step);
		
		[outputArray replaceObjectAtIndex:i withObject:[NSNumber numberWithFloat:fprime]];
	}
	
	/////////////////////////////////////////////////////////////////////////
	//Write abs value of FFT to file
	/////////////////////////////////////////////////////////////////////////	
	NSString *tempDir = NSTemporaryDirectory();
	NSString *filePath = [tempDir stringByAppendingString: @"FFTprime.txt"];
	
	NSError *werr = nil;
	NSStringEncoding enc = NSASCIIStringEncoding;
	[[outputArray componentsJoinedByString:@","] writeToFile:filePath atomically:YES encoding:enc error:&werr];	 
	
}

//calculate angle from two slopes
-(float)calculateAngle
{
	float maxVal, tempMax;
	maxVal = 0;
	for (int i = 0 ; i<[derivativeArray count]-8; i++) {
		tempMax = [[derivativeArray objectAtIndex:i] floatValue];
		
		if (tempMax > maxVal) {
			maxVal = tempMax;
			[self setMaxSlopePosition:i];
		}
	}
	
	float minVal, tempMin;
	minVal = 0;
	//-8 is because moving average goes to 0 at end for overshoot
	for (int i = [self maxSlopePosition]; i<[derivativeArray count]-8; i++) {
		tempMin = [[derivativeArray objectAtIndex:i] floatValue];
		
		if (tempMin < minVal) {
			minVal = tempMin;
			[self setMinSlopePosition:i];
		}
	}
	
	float angle;
	
	//260 is scaling factor to replicate EarCheck results
	angle = (fabs(atan(1/(260*maxVal))) + fabs(atan(1/(260*minVal)))) * 180/3.1415926;
	
	NSLog(@"Min Position:%u Max Position:%u",minSlopePosition,maxSlopePosition);
	NSLog(@"Min:%f Max:%f",minVal,maxVal);
	NSLog(@"angle:%f", angle);
	return angle;
}

//Calculate angle from + to - slope change
-(float)calculateAngle2
{	
    float maxVal, tempMax;
	maxVal = 0;
	for (int i = 0 ; i<[derivativeArray count]-8; i++) {
		tempMax = [[derivativeArray objectAtIndex:i] floatValue];
		
		if (tempMax > maxVal) {
			maxVal = tempMax;
			[self setMaxSlopePosition:i];
		}
	}
    
    //Find the point, after the maximum slope, where the slope changes from positive to negative
    
	float tmpVal = 0.0;
    float negVal = 0.0;
    float posVal = 0.0;
	//-8 is because moving average goes to 0 at end for overshoot
	for (int i = [self maxSlopePosition]; i<[derivativeArray count]-8; i++) {
		tmpVal = [[derivativeArray objectAtIndex:i] floatValue];
		NSLog(@"tmp: %f ",tmpVal);
        //Point at which slope changes from positive to negative
		if (tmpVal <= 0.0) {
            negVal = [[derivativeArray objectAtIndex:(i+3)] floatValue]*260;
            posVal = [[derivativeArray objectAtIndex:(i-5)] floatValue]*260;
			[self setMinSlopePosition:(i+3)];
            [self setMaxSlopePosition:(i-5)];
            break;
		}
	}
    
	float angle;
	angle = (fabs(atan(1.0/posVal)) + fabs(atan(1.0/negVal))) * 180/3.1415926;
	
	NSLog(@"Min Position:%u Max Position:%u",minSlopePosition,maxSlopePosition);
	NSLog(@"Min:%f Max:%f",negVal,posVal);
	NSLog(@"angle:%f", angle);
	return angle;

}

-(void)printLevel:(float)angle
{
	/*
	if (angle > 179.83)
		[viewController numberLabel].text = @"1";
	else if (angle > 179.775)
		[viewController numberLabel].text = @"2";
	else if (angle > 179.6960)
		[viewController numberLabel].text = @"3";
	else if (angle > 179.6707)
		[viewController numberLabel].text = @"4";
	else
		[viewController numberLabel].text = @"5";
*/	

	[viewController angleLabel].text =  [NSString stringWithFormat:@"%@%@",[[NSNumber numberWithFloat:angle] stringValue],@"\u00B0"];

}

#pragma mark Cleanup
///////////////////////////////////////////////////////////////////////////
//Cleaning everything up
///////////////////////////////////////////////////////////////////////////
-(void)dealloc
{
	[super dealloc];
	
	[audioSession release];
	[player release];
	[recorder release];
	[viewController release];
	
    vDSP_destroy_fftsetup(setupReal);
    free(originalReal);
    free(output.realp);
    free(output.imagp);
	free(windowedReal);
	free(window);
	free(obtainedReal);
	
	[nsObtainedReal release];
	[normReal release];
	
	[freqValues release];
	[normValues release];
	
	[recordFileURL release];
	
	[derivativeArray release];
}

@end
