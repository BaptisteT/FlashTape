//
//  TrackingUtils.m
//  FlashTape
//
//  Created by Baptiste Truchot on 5/10/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
#import <Parse/parse.h>

#import "TrackingUtils.h"

@implementation TrackingUtils

+ (void)trackVideoSent {
    [PFAnalytics trackEvent:@"video.sent"];
}

+ (void)trackVideoSendingFailure {
    [PFAnalytics trackEvent:@"video.failed"];
}

+ (void)trackVideoSeen {
    [PFAnalytics trackEvent:@"video.seen"];
}

+ (void)trackReplayButtonClicked {
    [PFAnalytics trackEvent:@"replay.clicked"];
}

+ (void)trackOpenApp
{
    [PFAnalytics trackEvent:@"app.open"];
}

@end
