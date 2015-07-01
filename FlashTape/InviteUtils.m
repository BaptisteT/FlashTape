//
//  InviteUtils.m
//  FlashTape
//
//  Created by Baptiste Truchot on 6/29/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
#import "ABContact.h"
#import "DatastoreUtils.h"
#import "User.h"

#import "ConstantUtils.h"
#import "InviteUtils.h"

#define VIDEO_SEEN_SINCE_LAST_INVITE @"Video Seen Since Last Invite Presented Count"

@implementation InviteUtils

+ (NSArray *)pickContactsToPresent:(NSInteger)count
{
    // get all contacts
    NSArray *aBContacts = [DatastoreUtils getAllABContactsLocally];
    
    if (aBContacts.count <= count) {
        return aBContacts;
    }
    
    NSArray *sortedContacts = [aBContacts sortedArrayUsingComparator:^NSComparisonResult(ABContact *obj1, ABContact *obj2) {
        if ([obj1 contactScore] >= [obj2 contactScore]) {
            return NSOrderedAscending;
        } else {
            return NSOrderedDescending;
        }
    }];
    return [sortedContacts subarrayWithRange:NSMakeRange(0, count)];
}

+ (BOOL)shouldPresentInviteController {
    return [InviteUtils getVideoSeenSinceLastInvitePresentedCount] > kMaxVideoSeenBetweenInvite * (1 + [User currentUser].score / 25.);
}

+ (NSInteger)getVideoSeenSinceLastInvitePresentedCount
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    return [prefs objectForKey:VIDEO_SEEN_SINCE_LAST_INVITE] ? [[prefs objectForKey:VIDEO_SEEN_SINCE_LAST_INVITE] integerValue]: 0;
}

+ (void)incrementVideoSeenSinceLastInvitePresentedCount
{
    NSInteger count = [InviteUtils getVideoSeenSinceLastInvitePresentedCount] + 1;
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:[NSNumber numberWithInteger:count] forKey:VIDEO_SEEN_SINCE_LAST_INVITE];
    [prefs synchronize];
}

+ (void)resetVideoSeenSinceLastInvitePresentedCount {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:[NSNumber numberWithInteger:0] forKey:VIDEO_SEEN_SINCE_LAST_INVITE];
    [prefs synchronize];
}

@end
