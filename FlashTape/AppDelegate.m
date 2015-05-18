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
#import "GeneralUtils.h"
#import "TrackingUtils.h"


@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Status bar
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    [[UINavigationBar appearance] setBackgroundColor:[ColorUtils navigationBarColor]];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setTitleTextAttributes: @{NSForegroundColorAttributeName: [UIColor whiteColor]}];

    // Enable Parse Crash Reporting
    [ParseCrashReporting enable];
    
    // Initialize Parse.
    [Parse setApplicationId:@"mn69Nl3gxgRzsKqJkx6YlIMgJAT2zZwMLokBF8xj"
                  clientKey:@"lhOVSqnmPBhitovjldmyTXht3OKuVFZhLrmLH0d7"];
    
    // Track statistics around application opens.
    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
    
    if ([User currentUser]) {
        WelcomeViewController* welcomeViewController = (WelcomeViewController *)  self.window.rootViewController.childViewControllers[0];
        [welcomeViewController performSegueWithIdentifier:@"Video From Welcome" sender:nil];
    }
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [TrackingUtils trackOpenApp];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    if ([GeneralUtils shouldDeleteStoredData]) {
        [GeneralUtils deleteStoredData];
    }
}
@end
