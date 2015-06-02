//
//  AppDelegate.m
//  FlashTape
//
//  Created by Baptiste Truchot on 4/25/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
#import <AudioToolbox/AudioToolbox.h>
#import <Parse/Parse.h>
#import <ParseCrashReporting/ParseCrashReporting.h>

#import "User.h"

#import "AppDelegate.h"
#import "WelcomeViewController.h"

#import "ColorUtils.h"
#import "DatastoreUtils.h"
#import "GeneralUtils.h"
#import "NotifUtils.h"
#import "TrackingUtils.h"


@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Enable Parse Crash Reporting
    [ParseCrashReporting enable];
    
    // Enable Parse local datastore
    [Parse enableLocalDatastore];
    
    // Initialize Parse.
    [Parse setApplicationId:@"mn69Nl3gxgRzsKqJkx6YlIMgJAT2zZwMLokBF8xj"
                  clientKey:@"lhOVSqnmPBhitovjldmyTXht3OKuVFZhLrmLH0d7"];
    
    // Track statistics around application opens.
    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
    
    // Clean data
    [DatastoreUtils deleteExpiredPosts];
    
    if ([User currentUser]) {
        // Remote notif
        [NotifUtils registerForRemoteNotif];
        
        WelcomeViewController* welcomeViewController = (WelcomeViewController *)  self.window.rootViewController.childViewControllers[0];
        [welcomeViewController performSegueWithIdentifier:@"Video From Welcome" sender:nil];
    }
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [TrackingUtils trackOpenApp];
    [self _cleanBadge];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    [self _cleanBadge];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    // Store the deviceToken in the current installation and save it to Parse.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:deviceToken];
    currentInstallation[@"user"] = [PFUser currentUser];
    [currentInstallation saveInBackground];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    UIApplicationState state = [application applicationState];
    // New video
    if ([[userInfo valueForKey:@"notif_type"] isEqualToString:@"new_video"]) {
        if (state == UIApplicationStateActive) {
            // refresh feed
            [[NSNotificationCenter defaultCenter] postNotificationName:@"new_video_posted"
                                                                object:nil
                                                              userInfo:nil];
        }
    } else if ([[userInfo valueForKey:@"notif_type"] isEqualToString:@"new_message"]) {
        if (state == UIApplicationStateActive) {
            // todo BT
            // sound + vibration
            AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
            
            // load new messages
            [[NSNotificationCenter defaultCenter] postNotificationName:@"new_message"
                                                                object:nil
                                                              userInfo:nil];
        }
    }
}

- (void)_cleanBadge {
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    if (currentInstallation.badge != 0) {
        currentInstallation.badge = 0;
        [currentInstallation saveEventually];
    }
}

@end
