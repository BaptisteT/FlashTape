//
//  TrackingUtils.m
//  FlashTape
//
//  Created by Baptiste Truchot on 5/10/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
#import "Mixpanel.h"
#import <Parse/parse.h>

#import "TrackingUtils.h"

@implementation TrackingUtils

+ (void)identifyUser:(User *)user signup:(BOOL)flag
{
    if (DEBUG)return;
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel.people set:@{@"name": user.flashUsername ? user.flashUsername : @"", @"number": user.username, @"score": [NSNumber numberWithInteger:user.score]}];
    [mixpanel identify:user.objectId];
    
    if (flag) {
        [TrackingUtils trackSignUp];
    }
}

+ (void)trackSignUp
{
    if (DEBUG)return;
    
    [PFAnalytics trackEvent:@"user.signup"];
    [[Mixpanel sharedInstance] track:@"user.signup"];
}

+ (void)trackSession:(NSNumber *)length
{
    if (DEBUG)return;
    
    [PFAnalytics trackEvent:@"session"];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"session" properties:@{@"Length": length}];
    [mixpanel.people increment:@"app.open" by:[NSNumber numberWithInt:1]];
}

+ (void)trackVideoSentWithProperties:(NSDictionary *)properties
{
    if (DEBUG)return;
    
    [PFAnalytics trackEvent:@"video.sent"];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"video.sent" properties:properties];
}

+ (void)trackVideoSendingFailure
{
    if (DEBUG)return;
    
    [PFAnalytics trackEvent:@"video.failed"];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"video.failed"];
}

+ (void)trackVideoSeen
{
    if (DEBUG)return;
    
    [PFAnalytics trackEvent:@"video.seen"];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"video.seen"];
    [mixpanel.people increment:@"video.seen" by:[NSNumber numberWithInt:1]];
}

+ (void)trackVideoDeleted
{
    if (DEBUG)return;
    
    [PFAnalytics trackEvent:@"video.deleted"];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"video.deleted"];
}


+ (void)trackReplayVideos {
    if (DEBUG)return;
    
    [PFAnalytics trackEvent:@"video.replay"];
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"video.replay"];
}

+ (void)trackInviteButtonClicked
{
    if (DEBUG)return;
    
    [PFAnalytics trackEvent:@"invite.clicked"];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"invite.clicked"];
}

+ (void)trackInviteSent
{
    if (DEBUG)return;
    
    [PFAnalytics trackEvent:@"invite.sent"];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"invite.sent"];
}

+ (void)trackMessageSent:(NSString *)messageType
{
    if (DEBUG)return;
    
    [PFAnalytics trackEvent:@"message.sent"];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"message.sent" properties:@{@"type": messageType}];
    [mixpanel.people increment:@"message.sent" by:[NSNumber numberWithInt:1]];
}

+ (void)trackMessageRead
{
    if (DEBUG)return;
    
    [PFAnalytics trackEvent:@"message.read"];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"message.read"];
    [mixpanel.people increment:@"message.read" by:[NSNumber numberWithInt:1]];
}

+ (void)trackMessageSendingFailed
{
    if (DEBUG)return;
    
    [PFAnalytics trackEvent:@"message.failed"];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"message.failed"];
}

+ (void)trackAddFriend
{
    if (DEBUG)return;
    
    [PFAnalytics trackEvent:@"friend.add"];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"friend.add"];
    [mixpanel.people increment:@"friend.add" by:[NSNumber numberWithInt:1]];
}

+ (void)trackBlockFriend
{
    if (DEBUG)return;
    
    [PFAnalytics trackEvent:@"friend.block"];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"friend.block"];
    [mixpanel.people increment:@"friend.block" by:[NSNumber numberWithInt:1]];
}

+ (void)trackSaveStory
{
    if (DEBUG)return;
    
    [PFAnalytics trackEvent:@"video.saved"];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"video.saved"];
}

+ (void)trackSaveStoryFailed
{
    if (DEBUG)return;
    
    [PFAnalytics trackEvent:@"video.saving_failure"];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"video.saving_failure"];
}


+ (void)trackCaptionClicked {
    if (DEBUG)return;
    
    [PFAnalytics trackEvent:@"caption.clicked"];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"caption.clicked"];
}

+ (void)trackCameraFlipClicked {
    if (DEBUG)return;
    
    [PFAnalytics trackEvent:@"camera_flip.clicked"];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"camera_flip.clicked"];
}

+ (void)trackFriendButtonClicked {
    if (DEBUG)return;
    
    [PFAnalytics trackEvent:@"friend_button.clicked"];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"friend_button.clicked"];
}

+ (void)trackMyStoryClicked {
    if (DEBUG)return;
    
    [PFAnalytics trackEvent:@"me.story.clicked"];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"me.story.clicked"];
}

+ (void)trackMyVideoClicked {
    if (DEBUG)return;
    
    [PFAnalytics trackEvent:@"me.video.clicked"];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"me.video.clicked"];
}

+ (void)trackPlayingBarSlide {
    if (DEBUG)return;
    
    [PFAnalytics trackEvent:@"playing.slide"];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"playing.slide"];
}




@end
