//
//  NotifUtils.m
//  FlashTape
//
//  Created by Baptiste Truchot on 5/26/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//

@import Foundation;
@import UIKit;

#import "NotifUtils.h"

@implementation NotifUtils

// Resgister user notification settings (request permission to user on 1st call)
// On iOS 7, acceptance  a token
+ (void)registerForRemoteNotif
{
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) { // ios 8
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert) categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    } else {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound)];
    }
}

// Get token without asking notif settings --> for silent notif (ios8 + only)
+ (void)registerForSilentRemoteNotif
{
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) { // ios 8
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    }
}

+ (BOOL)isRegisteredForRemoteNotification
{
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) { // ios 8
        return ([[UIApplication sharedApplication] isRegisteredForRemoteNotifications] && [[UIApplication sharedApplication] currentUserNotificationSettings] > 0);
    } else { // ios 7
        return [[UIApplication sharedApplication] enabledRemoteNotificationTypes] > 0;
    }
}

@end
