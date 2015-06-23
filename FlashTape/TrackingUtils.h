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

+ (void)trackVideoSentWithProperties:(NSDictionary *)properties;

+ (void)trackVideoSendingFailure;

+ (void)trackVideoSeen;

+ (void)trackVideoDeleted;

+ (void)trackReplayVideos;

+ (void)trackSession:(NSNumber *)length;

+ (void)trackInviteButtonClicked;

+ (void)trackInviteSent;

+ (void)trackMessageSent:(NSString *)messageType;

+ (void)trackMessageRead;

+ (void)trackMessageSendingFailed;

+ (void)trackAddFriend;

+ (void)trackDeleteFriend;

+ (void)trackMuteFriend;

+ (void)trackUnmuteFriend;

+ (void)trackBlockFriend;

+ (void)trackUnBlockFriend;

+ (void)trackSaveStory;

+ (void)trackSaveStoryFailed;

+ (void)trackCaptionClicked;

+ (void)trackCameraFlipClicked;

+ (void)trackFriendButtonClicked;

+ (void)trackMyStoryClicked;

+ (void)trackMyVideoClicked;

+ (void)trackPlayingBarSlide;

@end
