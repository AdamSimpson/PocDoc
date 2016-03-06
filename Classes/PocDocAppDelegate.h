//
//  PocDocAppDelegate.h
//  PocDoc
//
//  Created by Atrain on 6/17/10.
//  Copyright University of Cincinnati 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MainViewController;

@interface PocDocAppDelegate : NSObject <UIApplicationDelegate, UIAlertViewDelegate> {
    UIWindow *window;
    MainViewController *mainViewController;
    NSString *devTokenBytes;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet MainViewController *mainViewController;
@property (nonatomic, copy) NSString *devTokenBytes;

@end

