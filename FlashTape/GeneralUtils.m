//
//  GeneralUtils.m
//  FlashTape
//
//  Created by Baptiste Truchot on 4/27/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//

#import "GeneralUtils.h"

#define LAST_VIDEO_SEEN_DATE @"Last Video Seen Date"

@implementation GeneralUtils

+ (void)saveLastVideoSeenDate:(NSDate *)date
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:date forKey:LAST_VIDEO_SEEN_DATE];
}

+ (NSDate *)getLastVideoSeenDate
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    return [prefs objectForKey:LAST_VIDEO_SEEN_DATE];
}

@end
