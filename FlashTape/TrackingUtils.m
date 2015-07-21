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
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [self setPeopleProperties:@{@"name": user.flashUsername ? user.flashUsername : @"", @"number": user.username, @"score": [NSNumber numberWithInteger:user.score]}];
    [mixpanel identify:user.objectId];
    
    if (flag) {
        [TrackingUtils trackEvent:EVENT_USER_SIGNUP properties:nil];
        [TrackingUtils setPeopleProperties:@{@"signup.date": [NSDate date]}];
    }
}

+ (void)trackEvent:(NSString *)eventName properties:(NSDictionary *)properties
{
    // Parse
    [PFAnalytics trackEventInBackground:eventName block:nil];
    
    // Mixpanel
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    
    NSArray *arrayWithoutMixpanelEventTracking = @[EVENT_VIDEO_SEEN, EVENT_MESSAGE_READ, EVENT_CAMERA_FLIP_CLICKED, EVENT_CAPTION_CLICKED, EVENT_FRIEND_BUTTON_CLICKED, EVENT_PLAYING_TAP];
    if ([arrayWithoutMixpanelEventTracking indexOfObject:eventName] == NSNotFound) {
        [mixpanel track:eventName properties:properties];
    }
    
    NSArray *arrayWithMixpanelPeopleTracking = @[EVENT_SESSION, EVENT_VIDEO_SENT, EVENT_VIDEO_SEEN, EVENT_MESSAGE_SENT];
    if ([arrayWithMixpanelPeopleTracking indexOfObject:eventName] != NSNotFound) {
        [mixpanel.people increment:eventName by:[NSNumber numberWithInt:1]];
    }
}

+ (void)setPeopleProperties:(NSDictionary *)properties
{
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel.people set:properties];
}





@end
