//
//  AppDelegate.m
//  FlashTape
//
//  Created by Baptiste Truchot on 4/25/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
#import <AudioToolbox/AudioToolbox.h>
#import "Branch.h"
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import "Flurry.h"
#import "Mixpanel.h"
#import <Parse/Parse.h>
#import <AVFoundation/AVFoundation.h>

#import "ApiManager.h"
#import "User.h"
#import "VideoPost.h"

#import "AppDelegate.h"
#import "InternalNotifView.h"
#import "WelcomeViewController.h"

#import "ColorUtils.h"
#import "ConstantUtils.h"
#import "DatastoreUtils.h"
#import "GeneralUtils.h"
#import "InviteUtils.h"
#import "NotifUtils.h"
#import "TrackingUtils.h"


@interface AppDelegate ()

@property (strong, nonatomic) NSDate *sessionStartDate;

@property (nonatomic, strong) NSURL *redirectURL;
@property (nonatomic, strong) NSString *alertTitle;
@property (nonatomic, strong) NSString *alertMessage;
@property (nonatomic) BOOL repeat;

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
    if (!DEBUG) {
        [Parse setApplicationId:@"mn69Nl3gxgRzsKqJkx6YlIMgJAT2zZwMLokBF8xj"
                      clientKey:@"lhOVSqnmPBhitovjldmyTXht3OKuVFZhLrmLH0d7"];
    } else {
        [Parse setApplicationId:@"3ohZiWJdynEdw17xhrQ9t9d3xYnKTVj6mxLqQb0n"
                      clientKey:@"RyeSm5oeDK9A1UL2gM0EGDtoej3UjROFC3K0lW6t"];
    }
    
    // Branch
    [[Branch getInstance] initSessionWithLaunchOptions:launchOptions andRegisterDeepLinkHandler:^(NSDictionary *params, NSError *error) {
        // personalize launch ?
//        NSString *referredName = [params objectForKey:@"referredName"];
//        if (referredName) {
//            [[[UIAlertView alloc] initWithTitle:referredName message:@"" delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil] show];
//        }
    }];
    
    // Fabrick
    [Fabric with:@[CrashlyticsKit]];
    
    if (!DEBUG) {
        // Flurry
        [Flurry startSession:kProdFlurryToken];
        [Flurry setBackgroundSessionEnabled:NO];
        
        // Mixpanel
        [Mixpanel sharedInstanceWithToken:kProdMixpanelToken launchOptions:launchOptions];
        
        // Track statistics around application opens.
        [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
    } else {
        [Mixpanel sharedInstanceWithToken:kDevMixpanelToken launchOptions:launchOptions];
    }
    
    // Obsolete API
    [ApiManager checkAppVersionAndExecuteSucess:^(NSDictionary * resultDictionnary) {
        if (resultDictionnary && [resultDictionnary valueForKey:@"title"]) {
            self.alertTitle = [resultDictionnary valueForKey:@"title"];
            self.alertMessage = [resultDictionnary valueForKey:@"message"];
            self.repeat = [[resultDictionnary valueForKey:@"blocking"] boolValue];
            if ([resultDictionnary valueForKey:@"redirect_url"]) {
                self.redirectURL = [NSURL URLWithString:[resultDictionnary valueForKey:@"redirect_url"]];
            }
            [self createObsoleteAPIAlertView];
        }
        else {
            if (resultDictionnary && [resultDictionnary valueForKey:@"hide_skip_signup"]) {
                [GeneralUtils setSkipContactPref];
            }
            if (resultDictionnary && [resultDictionnary valueForKey:@"ghost_invite_count"]) {
                [InviteUtils setGhostInviteCount:[[resultDictionnary valueForKey:@"ghost_invite_count"] integerValue]];
            }
        }
    }];
    
    // Clean video data
    [DatastoreUtils deleteExpiredPosts];
    
    User *currentUser = [User currentUser];
    if (currentUser && currentUser.flashUsername && currentUser.flashUsername.length > 0) {
        // Identify user
        [TrackingUtils identifyUser:[User currentUser] signup:NO];
        
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
    
    return [[FBSDKApplicationDelegate sharedInstance] application:application
                                    didFinishLaunchingWithOptions:launchOptions];;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    self.sessionStartDate = [NSDate date];
    
    [FBSDKAppEvents activateApp];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    NSNumber *seconds = @([[NSDate date] timeIntervalSinceDate:self.sessionStartDate]);
    [TrackingUtils trackEvent:EVENT_SESSION properties:@{@"Length": seconds}];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    // Store the deviceToken in the current installation and save it to Parse.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:deviceToken];
    currentInstallation[@"user"] = [PFUser currentUser];
    
    currentInstallation[@"iosSettings"] = [NSNumber numberWithInteger:[NotifUtils getUserNotificationSettings]];
    [currentInstallation saveInBackground];
    [TrackingUtils setPeopleProperties:@{PROPERTY_ALLOW_NOTIF: currentInstallation[@"iosSettings"]}];
    
    // This sends the deviceToken to Mixpanel
    [[Mixpanel sharedInstance].people addPushDeviceToken:deviceToken];
}



- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    UIApplicationState state = [application applicationState];
    // New video
    if ([[userInfo valueForKey:@"notif_type"] isEqualToString:@"new_video"]) {
        if (state == UIApplicationStateActive) {
            // refresh feed
            [[NSNotificationCenter defaultCenter] postNotificationName:@"retrieve_video"
                                                                object:nil
                                                              userInfo:nil];
            completionHandler(UIBackgroundFetchResultNoData);
        } else {
            // download video in background
            NSString *videoId = [userInfo valueForKey:@"video_id"];
            if (videoId && videoId.length > 0) {
                VideoPost *post = [VideoPost objectWithoutDataWithObjectId:videoId];
                [post fetchInBackgroundWithBlock:^(PFObject *post, NSError *error) {
                    if (error) {
                        completionHandler(UIBackgroundFetchResultFailed);
                    } else {
                        [(VideoPost *)post getDataInBackgroundAndExecuteSuccess:^{
                            completionHandler(UIBackgroundFetchResultNewData);
                        } failure:^(NSError *error) {
                            completionHandler(UIBackgroundFetchResultFailed);
                        }];
                    }
                }];
            }
        }
    } else if ([[userInfo valueForKey:@"notif_type"] isEqualToString:@"new_message"]) {
        if (state == UIApplicationStateActive) {
            // internal notif
            [self displayInternalNotif:userInfo];
            
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
        completionHandler(UIBackgroundFetchResultNoData);
    } else if ([[userInfo valueForKey:@"notif_type"] isEqualToString:@"new_follow"]) {
        if (state == UIApplicationStateActive) {
            // internal notif
            [self displayInternalNotif:userInfo];
            
            // Load relation ship
            [ApiManager getRelationshipsRemotelyAndExecuteSuccess:nil failure:nil];
        }
        completionHandler(UIBackgroundFetchResultNoData);
    }
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    [[Branch getInstance] handleDeepLink:url];
    return [[FBSDKApplicationDelegate sharedInstance] application:application
                                                          openURL:url
                                                sourceApplication:sourceApplication
                                                       annotation:annotation];
}

// --------------------------------------------
#pragma mark - Internal notif
// --------------------------------------------
- (void)displayInternalNotif:(NSDictionary *)userInfo {
    InternalNotifView *internalNotif = [[[NSBundle mainBundle] loadNibNamed:@"InternalNotifView" owner:self options:nil] objectAtIndex:0];
    UIView * superView = self.window.rootViewController.view;;
    [internalNotif initWithType:[userInfo valueForKey:@"notif_type"] frame:CGRectMake(0, - kInternalNotifHeight, superView.frame.size.width, kInternalNotifHeight) userId:[userInfo valueForKey:@"userId"] alert:[[userInfo valueForKey:@"aps"] valueForKey:@"alert"]];
    [superView addSubview:internalNotif];
    [UIView animateWithDuration:kNotifAnimationDuration
                     animations:^(){
                         internalNotif.frame = CGRectMake(0, 0, superView.frame.size.width, kInternalNotifHeight);
                     } completion:nil];
}


// --------------------------------------------
#pragma mark - Alert view
// --------------------------------------------
- (void)createObsoleteAPIAlertView
{
    if (self.alertTitle && self.alertMessage) {
        [[[UIAlertView alloc] initWithTitle:self.alertTitle
                                    message:self.alertMessage
                                   delegate:self
                          cancelButtonTitle:nil
                          otherButtonTitles:@"Ok",nil] show];
    }
}

// API related alert
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (self.redirectURL) {
        [[UIApplication sharedApplication] openURL:self.redirectURL];
        if (self.repeat) {
            [self createObsoleteAPIAlertView];
        }
    }
}

@end
