//
//  PocDocAppDelegate.m
//  PocDoc
//
//  Created by Atrain on 6/17/10.
//  Copyright University of Cincinnati 2010. All rights reserved.
//

#import "PocDocAppDelegate.h"
#import "MainViewController.h"

@implementation PocDocAppDelegate


@synthesize window;
@synthesize mainViewController;

//Need to set devTokenBytes some something
@synthesize devTokenBytes;


#pragma mark -
#pragma mark Application lifecycle

//BUG: Bages dont actually get incremented above 1

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    
    //get dictionary for push notification payload
    NSDictionary *remoteNotif =
    [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey]; 
  
    //If there was a remote notification accepted while app was closed and not in background  
    if (remoteNotif) {
        NSString *itemName = [[[remoteNotif objectForKey:@"aps"] objectForKey:@"alert"] objectForKey:@"body"];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"PocDoc Response:" message:itemName delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        [alert release];
        
       // [viewController displayItem:itemName];
        
        //Deincriment the badge now that app has been opened
        application.applicationIconBadgeNumber = [[[remoteNotif objectForKey:@"aps"] objectForKey:@"badge"] integerValue]-1;
    }
    
    //register for push notification
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge |UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
        
    //Add the main view controller's view to the window and display.
    [window addSubview:mainViewController.view];
    [window makeKeyAndVisible];
    
    //load up any subviews: i.e. the gauge
    [mainViewController loadSubViews];
    
    return YES;
}

// Delegate method for when remote notification is recieved and app is in forground
// Not called if user presses cancel on push notification
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    
    NSString *itemName = [[[userInfo objectForKey:@"aps"] objectForKey:@"alert"] objectForKey:@"body"];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"PocDoc Response:" message:itemName delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
//    [alert setTag:12];
    [alert show];
    [alert release];
    // optional - add more buttons:
//    [alert addButtonWithTitle:@"Yes"];

    
//    [viewController displayItem:itemName];  // custom method
    
    //Deincriment the badge now that app has been opened
    application.applicationIconBadgeNumber = [[[userInfo objectForKey:@"aps"] objectForKey:@"badge"] integerValue] - 1;
}

//IUAlertView delegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
/*    if (buttonIndex == 1) {
        // do stuff based on [alertView tag]
    }
 */
}

// Delegation methods for PUSH service components
- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)devToken {
//    [self setDevTokenBytes:[devToken bytes]];
    NSLog(@"devToken=%@",devToken);
//    self.registered = YES;
//    [self sendProviderDeviceToken:devTokenBytes]; // custom method
//    NSString *deviceToken = [[webDeviceToken description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    //deviceToken = [deviceToken stringByReplacingOccurrencesOfString:@" " withString:@""];
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err {
    NSLog(@"Error in registration. Error: %@", err);
}

- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, called instead of applicationWillTerminate: when the user quits.
     */
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    /*
     Called as part of  transition from the background to the inactive state: here you can undo many of the changes made on entering the background.
     */
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}


- (void)applicationWillTerminate:(UIApplication *)application {
    /*
     Called when the application is about to terminate.
     See also applicationDidEnterBackground:.
     */
}


#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
}


- (void)dealloc {
    [mainViewController release];
    [window release];
    [super dealloc];
}

@end
