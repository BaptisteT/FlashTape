//
//  NotifUtils.h
//  FlashTape
//
//  Created by Baptiste Truchot on 5/26/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NotifUtils : NSObject

// Resgister user notification settings (request permission to user on 1st call)
+ (void)registerForRemoteNotif;

// Get token without asking notif permissions --> for silent notif (ios8 + only)
+ (void)registerForSilentRemoteNotif;


@end
