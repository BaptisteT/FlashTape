//
//  TrackingUtils.h
//  FlashTape
//
//  Created by Baptiste Truchot on 5/10/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "User.h"

@interface TrackingUtils : NSObject

+ (void)identifyUser:(User *)user signup:(BOOL)flag;

+ (void)trackVideoSent;

+ (void)trackVideoSendingFailure;

+ (void)trackVideoSeen;

+ (void)trackVideoDeleted;

+ (void)trackReplayVideos;

+ (void)trackSession:(NSNumber *)length;

+ (void)trackInviteButtonClicked;

+ (void)trackInviteSent;

+ (void)trackMessageSent;

+ (void)trackMessageRead;

+ (void)trackMessageSendingFailed;

+ (void)trackAddFriend;

+ (void)trackBlockFriend;

@end
