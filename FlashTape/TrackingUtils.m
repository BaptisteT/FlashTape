//
//  TrackingUtils.m
//  FlashTape
//
//  Created by Baptiste Truchot on 5/10/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
#import "GAI.h"
#import "GAIFields.h"
#import "GAIDictionaryBuilder.h"
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
    
    [[[GAI sharedInstance] defaultTracker] set:@"&uid" value:user.objectId];
    
    if (flag) {
        [TrackingUtils trackSignUp];
    }
}

+ (void)trackSignUp
{
    if (DEBUG)return;
    
    [PFAnalytics trackEvent:@"user.signup"];
    [[Mixpanel sharedInstance] track:@"user.signup"];
    
    
    [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createEventWithCategory:@"UX"
                                                                                        action:@"user.signup"
                                                                                         label:nil
                                                                                         value:nil] build]];
}

+ (void)trackSession:(NSNumber *)length
{
    if (DEBUG)return;
    
    [PFAnalytics trackEvent:@"session"];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"session" properties:@{@"Length": length}];
    [mixpanel.people increment:@"app.open" by:[NSNumber numberWithInt:1]];
    
    
    GAIDictionaryBuilder *builder = [GAIDictionaryBuilder createEventWithCategory:@"UX"
                                                                           action:@"app.open"
                                                                            label:nil
                                                                            value:nil];
    [builder set:@"start" forKey:kGAISessionControl];
    [[[GAI sharedInstance] defaultTracker] send:[builder build]];
}

+ (void)trackVideoSentWithProperties:(NSDictionary *)properties
{
    if (DEBUG)return;
    
    [PFAnalytics trackEvent:@"video.sent"];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"video.sent" properties:properties];
    [mixpanel.people increment:@"video.seen" by:[NSNumber numberWithInt:1]];
    
    [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createEventWithCategory:@"video"
                                                                                        action:@"video.sent"
                                                                                         label:nil
                                                                                         value:nil] build]];
}

+ (void)trackVideoSendingFailure
{
    if (DEBUG)return;
    
    [PFAnalytics trackEvent:@"video.failed"];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"video.failed"];
    
    [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createEventWithCategory:@"video"
                                                                                        action:@"video.failed"
                                                                                         label:nil
                                                                                         value:nil] build]];
}

+ (void)trackVideoSeen
{
    if (DEBUG)return;
    
    [PFAnalytics trackEvent:@"video.seen"];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"video.seen"];
    [mixpanel.people increment:@"video.seen" by:[NSNumber numberWithInt:1]];
    
    [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createEventWithCategory:@"video"
                                                                                        action:@"video.seen"
                                                                                         label:nil
                                                                                         value:nil] build]];
}

+ (void)trackVideoDeleted
{
    if (DEBUG)return;
    
    [PFAnalytics trackEvent:@"video.deleted"];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"video.deleted"];
    
    [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createEventWithCategory:@"video"
                                                                                        action:@"video.deleted"
                                                                                         label:nil
                                                                                         value:nil] build]];
}


+ (void)trackReplayVideos {
    if (DEBUG)return;
    
    [PFAnalytics trackEvent:@"video.replay"];
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"video.replay"];
    
    [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action"
                                                                                        action:@"video.replay"
                                                                                         label:nil
                                                                                         value:nil] build]];
}

+ (void)trackInviteButtonClicked
{
    if (DEBUG)return;
    
    [PFAnalytics trackEvent:@"invite.clicked"];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"invite.clicked"];
    
    [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action"
                                                                                        action:@"invite.clicked"
                                                                                         label:nil
                                                                                         value:nil] build]];
}

+ (void)trackInviteSent
{
    if (DEBUG)return;
    
    [PFAnalytics trackEvent:@"invite.sent"];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"invite.sent"];
    
    [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action"
                                                                                        action:@"invite.sent"
                                                                                         label:nil
                                                                                         value:nil] build]];
}

+ (void)trackInviteControllerPresented
{
    if (DEBUG)return;
    
    [PFAnalytics trackEvent:@"invite.presented"];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"invite.presented"];
}

+ (void)trackMessageSent:(NSString *)messageType
{
    if (DEBUG)return;
    
    [PFAnalytics trackEvent:@"message.sent"];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"message.sent" properties:@{@"type": messageType}];
    [mixpanel.people increment:@"message.sent" by:[NSNumber numberWithInt:1]];
    
    [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createEventWithCategory:@"message"
                                                                                        action:@"message.sent"
                                                                                         label:messageType
                                                                                         value:nil] build]];
}

+ (void)trackMessageRead
{
    if (DEBUG)return;
    
    [PFAnalytics trackEvent:@"message.read"];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"message.read"];
    [mixpanel.people increment:@"message.read" by:[NSNumber numberWithInt:1]];
    
    [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createEventWithCategory:@"message"
                                                                                        action:@"message.read"
                                                                                         label:nil
                                                                                         value:nil] build]];
}

+ (void)trackMessageSendingFailed
{
    if (DEBUG)return;
    
    [PFAnalytics trackEvent:@"message.failed"];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"message.failed"];
    
    [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createEventWithCategory:@"message"
                                                                                        action:@"message.failed"
                                                                                         label:nil
                                                                                         value:nil] build]];
}

+ (void)trackAddFriend
{
    if (DEBUG)return;
    
    [PFAnalytics trackEvent:@"friend.add"];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"friend.add"];
    [mixpanel.people increment:@"friend.add" by:[NSNumber numberWithInt:1]];
    
    [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createEventWithCategory:@"friend"
                                                                                        action:@"friend.add"
                                                                                         label:nil
                                                                                         value:nil] build]];
}

+ (void)trackDeleteFriend
{
    if (DEBUG)return;
    
    NSString *event = @"friend.delete";
    [PFAnalytics trackEvent:event];
    [[Mixpanel sharedInstance] track:event];
    [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createEventWithCategory:@"friend"
                                                                                        action:event
                                                                                         label:nil
                                                                                        value:nil] build]];
}

+ (void)trackMuteFriend
{
    if (DEBUG)return;
    NSString *event = @"friend.mute";
    [PFAnalytics trackEvent:event];
    [[Mixpanel sharedInstance] track:event];
    [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createEventWithCategory:@"friend"
                                                                                        action:event
                                                                                         label:nil
                                                                                         value:nil] build]];
}

+ (void)trackUnmuteFriend
{
    if (DEBUG)return;
    NSString *event = @"friend.unmute";
    [PFAnalytics trackEvent:event];
    [[Mixpanel sharedInstance] track:event];
    [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createEventWithCategory:@"friend"
                                                                                        action:event
                                                                                         label:nil
                                                                                         value:nil] build]];
}

+ (void)trackBlockFriend
{
    if (DEBUG)return;
    NSString *event = @"friend.block";
    [PFAnalytics trackEvent:event];
    [[Mixpanel sharedInstance] track:event];
    [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createEventWithCategory:@"friend"
                                                                                        action:event
                                                                                         label:nil
                                                                                         value:nil] build]];
}

+ (void)trackUnBlockFriend
{
    if (DEBUG)return;
    NSString *event = @"friend.block";
    [PFAnalytics trackEvent:event];
    [[Mixpanel sharedInstance] track:event];
    [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createEventWithCategory:@"friend"
                                                                                        action:event
                                                                                         label:nil
                                                                                         value:nil] build]];
}

+ (void)trackSaveStory
{
    if (DEBUG)return;
    
    [PFAnalytics trackEvent:@"video.saved"];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"video.saved"];
    
    [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createEventWithCategory:@"story"
                                                                                        action:@"video.saved"
                                                                                         label:nil
                                                                                         value:nil] build]];
}

+ (void)trackSaveStoryFailed
{
    if (DEBUG)return;
    
    [PFAnalytics trackEvent:@"video.saving_failure"];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"video.saving_failure"];
    
    [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createEventWithCategory:@"story"
                                                                                        action:@"video.saving_failure"
                                                                                         label:nil
                                                                                         value:nil] build]];
}


+ (void)trackCaptionClicked {
    if (DEBUG)return;
    
    [PFAnalytics trackEvent:@"caption.clicked"];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"caption.clicked"];
    
    [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action"
                                                                                        action:@"caption.clicked"
                                                                                         label:nil
                                                                                         value:nil] build]];
}

+ (void)trackCameraFlipClicked {
    if (DEBUG)return;
    
    [PFAnalytics trackEvent:@"camera_flip.clicked"];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"camera_flip.clicked"];
    
    [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action"
                                                                                        action:@"camera_flip.clicked"
                                                                                         label:nil
                                                                                         value:nil] build]];
}

+ (void)trackFriendButtonClicked {
    if (DEBUG)return;
    
    [PFAnalytics trackEvent:@"friend_button.clicked"];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"friend_button.clicked"];
    
    [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action"
                                                                                        action:@"friend_button.clicked"
                                                                                         label:nil
                                                                                         value:nil] build]];
}

+ (void)trackMyStoryClicked {
    if (DEBUG)return;
    
    [PFAnalytics trackEvent:@"me.story.clicked"];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"me.story.clicked"];
    
    [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action"
                                                                                        action:@"me.story.clicked"
                                                                                         label:nil
                                                                                         value:nil] build]];
}

+ (void)trackMyVideoClicked {
    if (DEBUG)return;
    
    [PFAnalytics trackEvent:@"me.video.clicked"];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"me.video.clicked"];
    
    [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action"
                                                                                        action:@"me.video.clicked"
                                                                                         label:nil
                                                                                         value:nil] build]];
}

+ (void)trackPlayingBarSlide {
    if (DEBUG)return;
    
    [PFAnalytics trackEventInBackground:@"playing.slide" block:^(BOOL completed, NSError *error) {
        NSLog(@"%@",error);
    }];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"playing.slide"];
    
    [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action"
                                                                                        action:@"playing.slide"
                                                                                         label:nil
                                                                                         value:nil] build]];
}




@end
