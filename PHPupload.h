//
//  PHPupload.h
//  PocDoc
//
//  Created by Atrain on 7/29/10.
//  Copyright (c) 2010 University of Cincinnati. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PHPupload : NSObject {
    
}

+ (void)uploadImage:(UIImage*)image;
+ (void)uploadText:(NSString*)filePath;

@end
