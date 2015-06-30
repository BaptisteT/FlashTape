//
//  TrackingUtils.h
//  FlashTape
//
//  Created by Baptiste Truchot on 5/10/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "User.h"

#define EVENT_USER_SIGNUP @"user.signup"
#define EVENT_SESSION @"session"
#define EVENT_VIDEO_SENT @"video.sent"
#define EVENT_VIDEO_FAILED @"video.failed"
#define EVENT_VIDEO_SEEN @"video.seen"
#define EVENT_VIDEO_DELETED @"video.deleted"
#define EVENT_VIDEO_REPLAY @"video.replay"
#define EVENT_INVITE_CLICKED @"invite.clicked"
#define EVENT_INVITE_SENT @"invite.sent"
#define EVENT_INVITE_PRESENTED @"invite.presented"
#define EVENT_MESSAGE_SENT @"message.sent"
#define EVENT_MESSAGE_READ @"message.read"
#define EVENT_MESSAGE_FAILED @"message.failed"
#define EVENT_FRIEND_ADD @"friend.add"
#define EVENT_FRIEND_DELETE @"friend.delete"
#define EVENT_FRIEND_MUTE @"friend.mute"
#define EVENT_FRIEND_UNMUTE @"friend.unmute"
#define EVENT_FRIEND_BLOCK @"friend.block"
#define EVENT_FRIEND_UNBLOCK @"friend.unblock"
#define EVENT_VIDEO_SAVED @"video.saved"
#define EVENT_VIDEO_SAVING_FAILURE @"video.saving_failure"
#define EVENT_CAPTION_CLICKED @"caption.clicked"
#define EVENT_CAMERA_FLIP_CLICKED @"camera_flip.clicked"
#define EVENT_FRIEND_BUTTON_CLICKED @"friend_button.clicked"
#define EVENT_ME_STORY_CLICKED @"me.story.clicked"
#define EVENT_ME_VIDEO_CLICKED @"me.video.clicked"
#define EVENT_PLAYING_SLIDE @"playing.slide"

@interface TrackingUtils : NSObject


+ (void)identifyUser:(User *)user signup:(BOOL)flag;

+ (void)trackEvent:(NSString *)eventName properties:(NSDictionary *)properties;

@end
