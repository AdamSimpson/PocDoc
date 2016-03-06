//
//  AnalyzeAudio.h
//  PocDoc
//
//  Created by Adam Simpson on 6/4/10.
//  Copyright 2010 University of Cincinnati. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <Accelerate/Accelerate.h>

@class MainViewController;

@interface AnalyzeAudio : NSObject <AVAudioSessionDelegate, AVAudioPlayerDelegate,
AVAudioRecorderDelegate> 
{
	//GUI properties
	MainViewController *viewController;
	
	//Audio Properties
	AVAudioSession	*audioSession;
	AVAudioPlayer	*player;
	AVAudioRecorder *recorder;
	NSURL *recordFileURL;
	
	//is AnalyzeAudio currently busy
	BOOL isAnalyzing;
	
	//does AnalyzeAudio have recorded data ready
	BOOL hasData;
	
	/////////////////////////////////////////////////////////////////////////
	//variables needed for FFT - many accessed directly to minimize overhead
	/////////////////////////////////////////////////////////////////////////
	COMPLEX_SPLIT output; //typedef to DSPDoubleSplitcomplex
	FFTSetup setupReal;
	uint32_t n, log2n, nOver2;//n is actual number of samples
	int32_t stride;
	float *originalReal; //data read from file into here
	float *window; //window function data
	float *windowedReal; //window function applied to original data
	
	float *obtainedReal; //final output data
	NSMutableArray *nsObtainedReal; //NSArray to hold final data
	
	//Used for reading in recorded data file
	AudioBufferList fillBufList;
	ExtAudioFileRef sourceFile;	
	UInt32 numFrames; //number of frames(audio samples) to read in from sourceFile
	
	uint32_t numFreqs; //number of superposition frequencies
	NSString *freqFilePath; //file to hold superposition frequencies
	NSArray *freqValues; //frequencies of superposition
	NSMutableArray *freqValuesSmooth; //Averaged frequency values
	
	NSString *normFilePath; //file to hold normalization data
	NSMutableArray *normValues; //normilization values for FFT
	
	NSMutableArray *normReal; //final output
	
	NSMutableArray *derivativeArray;
	
	NSMutableArray *normRealSmooth;
	
	BOOL processIsCalibration;
	
	uint minSlopePosition;
	uint maxSlopePosition;
	
	float adjustedAngle;
	
	NSString *patientDataFilePath;
}

@property (nonatomic, retain) MainViewController *viewController;

@property (nonatomic, retain) AVAudioSession *audioSession;
@property (nonatomic, retain) AVAudioPlayer	*player;
@property (nonatomic, retain) AVAudioRecorder *recorder;
@property (nonatomic, retain) NSURL *recordFileURL;
@property (nonatomic, retain) NSMutableArray *nsObtainedReal;
@property (nonatomic, retain) NSMutableArray *normReal;
@property (nonatomic) uint32_t numFreqs;
@property (nonatomic, copy) NSString *freqFilePath;
@property (nonatomic, retain) NSArray *freqValues;
@property (nonatomic, copy) NSString *normFilePath;
@property (nonatomic, retain) NSMutableArray *normValues;
@property (nonatomic, retain) NSMutableArray *derivativeArray;
@property (nonatomic, retain) NSMutableArray *normRealSmooth;
@property (nonatomic, retain) NSMutableArray *freqValuesSmooth;
@property (nonatomic) float adjustedAngle;

@property (nonatomic) BOOL isAnalyzing;
@property (nonatomic) BOOL hasData;
@property (nonatomic) BOOL processIsCalibration;

@property (nonatomic) uint minSlopePosition;
@property (nonatomic) uint maxSlopePosition;

@property (nonatomic, copy) NSString *patientDataFilePath;

-(void)initAudio;
-(void)initFFT;
-(void)initAnalyze:(MainViewController*) viewControl;
-(void)startAnalysis;
-(void)fft;
-(void)normalizeData;
-(void)processRecording;
-(void)createCalibration;
-(void)startCalibration;
-(void)takeDerivative:(NSArray*)inputArrayX:(NSArray*)inputArrayY:(NSMutableArray*)outputArray;
-(void)movingAverage:(NSArray*) inputArray:(NSMutableArray*)outputArray:(uint)numAverage;
-(float)calculateAngle;
-(float)calculateAngle2;
-(void)printLevel:(float)angle;

@end
