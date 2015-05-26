//
//  AppDelegate.m
//  FlashTape
//
//  Created by Baptiste Truchot on 4/25/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
#import <Parse/Parse.h>
#import <ParseCrashReporting/ParseCrashReporting.h>

#import "User.h"

#import "AppDelegate.h"
#import "WelcomeViewController.h"

#import "ColorUtils.h"
#import "DatastoreUtils.h"
#import "GeneralUtils.h"
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
        WelcomeViewController* welcomeViewController = (WelcomeViewController *)  self.window.rootViewController.childViewControllers[0];
        [welcomeViewController performSegueWithIdentifier:@"Video From Welcome" sender:nil];
    }
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [TrackingUtils trackOpenApp];
}

@end
