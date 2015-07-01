//
//  InviteUtils.m
//  FlashTape
//
//  Created by Baptiste Truchot on 6/29/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
#import "ABContact.h"
#import "DatastoreUtils.h"

#import "ConstantUtils.h"
#import "InviteUtils.h"

#define VIDEO_SEEN_SINCE_LAST_INVITE @"Video Seen Since Last Invite Presented Count"

@implementation InviteUtils

+ (ABContact *)contactToBePresented {
    // get all contacts
    NSArray *aBContacts = [DatastoreUtils getAllABContactsLocally];
    
    // attribute score
    NSInteger maxScore = 0;
    NSMutableArray *maxScoreContacts = [NSMutableArray new];
    for (ABContact *contact in aBContacts) {
        if (!contact.isFlasher) {
            NSInteger score = [contact contactScore];
            if (score == maxScore) {
                [maxScoreContacts addObject:contact];
            } else if (score > maxScore) {
                maxScore = score;
                [maxScoreContacts removeAllObjects];
                [maxScoreContacts addObject:contact];
            }
        }
    }
    
    // Get one randomly
    return [maxScoreContacts objectAtIndex:(arc4random() % [maxScoreContacts count])];
}

+ (BOOL)shouldPresentInviteController {
    return [InviteUtils getVideoSeenSinceLastInvitePresentedCount] > kMaxVideoSeenBetweenInvite;
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
