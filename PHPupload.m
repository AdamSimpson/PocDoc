//
//  PHPupload.m
//  PocDoc
//
//  Created by Atrain on 7/29/10.
//  Copyright (c) 2010 University of Cincinnati. All rights reserved.
//

#import "PHPupload.h"
#import "ASIFormDataRequest.h"

@implementation PHPupload

//Havent tested if this works, may be need to save to file and use setFile:
+(void)uploadImage:(UIImage*)image
{
	/*
	 turning the image into a NSData object
	 getting the image back out of the UIImageView
	 setting the quality to 90
     */
    
	NSData *imageData = UIImageJPEGRepresentation(image, 90);
	// setting up the URL to post to
	NSString *urlString = @"http://www.physics.uc.edu/~simpson/PocDoc/test-upload.php";
    
    ASIFormDataRequest *request = [[[ASIFormDataRequest alloc] initWithURL:[NSURL URLWithString:urlString]] autorelease];
    [request setData:imageData forKey:@"userfile"];//actual file to send
    [request startSynchronous];//send file
}

+(void)uploadText:(NSString*)filePath
{
	// setting up the URL to post to
	NSString *urlString = @"http://www.physics.uc.edu/~simpson/PocDoc/test-upload.php";
    NSLog(@"boner");
    ASIFormDataRequest *request = [[[ASIFormDataRequest alloc] initWithURL:[NSURL URLWithString:urlString]] autorelease];
//    [request setPostValue:@"userfile" forKey:@"name"];//name to use on server side
//    [request setPostValue:@"data.csv" forKey:@"filename"];//original name of file
    [request setFile:filePath forKey:@"userfile"];//actual file to send
    [request startSynchronous];//send file
    
}


-(void)dealloc
{
    [super dealloc];
}

@end
