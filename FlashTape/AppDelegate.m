//
//  AppDelegate.m
//  FlashTape
//
//  Created by Baptiste Truchot on 4/25/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
#import <AudioToolbox/AudioToolbox.h>
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>
#import "Flurry.h"
#import <Parse/Parse.h>
#import <ParseCrashReporting/ParseCrashReporting.h>
#import <AVFoundation/AVFoundation.h>

#import "User.h"

#import "AppDelegate.h"
#import "WelcomeViewController.h"

#import "ColorUtils.h"
#import "ConstantUtils.h"
#import "DatastoreUtils.h"
#import "GeneralUtils.h"
#import "NotifUtils.h"
#import "TrackingUtils.h"


@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //Stop app pausing other sound.
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord
                                     withOptions:AVAudioSessionCategoryOptionDuckOthers | AVAudioSessionCategoryOptionDefaultToSpeaker
                                           error:nil];
    // -------------------------------
    // Parse
    // -------------------------------
    // Enable Parse local datastore
    [Parse enableLocalDatastore];
    // Initialize Parse.
    [Parse setApplicationId:@"mn69Nl3gxgRzsKqJkx6YlIMgJAT2zZwMLokBF8xj"
                  clientKey:@"lhOVSqnmPBhitovjldmyTXht3OKuVFZhLrmLH0d7"];
    // Track statistics around application opens.
    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
    
# ifdef DEBUG
    BOOL debug = true;
# else
    BOOL debug = false;
# endif
    if (!debug) {
        // Flurry
        [Flurry startSession:kProdFlurryToken];
        [Flurry setBackgroundSessionEnabled:NO];
        
        // Fabrick
        [Fabric with:@[CrashlyticsKit]];
    }
    
    // Clean video data
    [DatastoreUtils deleteExpiredPosts];
    
    if ([User currentUser]) {
        // Register for notif
        [NotifUtils registerForRemoteNotif];
        
        // Check if we come from a new message notif
        NSNumber *notifOpening = [NSNumber numberWithBool:NO];
        NSDictionary *remoteNotif = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
        if (remoteNotif) {
            if ([[remoteNotif valueForKey:@"notif_type"] isEqualToString:@"new_message"]) {
                notifOpening = [NSNumber numberWithBool:YES];
            }
        }
        
        // Navigate
        WelcomeViewController* welcomeViewController = (WelcomeViewController *)  self.window.rootViewController.childViewControllers[0];
        [welcomeViewController performSegueWithIdentifier:@"Video From Welcome" sender:notifOpening];
    }
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [TrackingUtils trackOpenApp];
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
            [[NSNotificationCenter defaultCenter] postNotificationName:@"retrieve_video"
                                                                object:nil
                                                              userInfo:nil];
        }
    } else if ([[userInfo valueForKey:@"notif_type"] isEqualToString:@"new_message"]) {
        if (state == UIApplicationStateActive) {
            // sound
            AudioServicesPlaySystemSound(1114);
            
            // load new messages
            [[NSNotificationCenter defaultCenter] postNotificationName:@"retrieve_message"
                                                                object:nil
                                                              userInfo:nil];
        } else {
            // navigate to chat
            [[NSNotificationCenter defaultCenter] postNotificationName:@"new_message_clicked"
                                                                object:nil
                                                              userInfo:nil];
        }
    }
}


@end
