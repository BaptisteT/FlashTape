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

#define LAST_INVITE_PRESENTED_DATE @"Last Invite Presented Date"
#define INVITE_PRESENTED_COUNT @"Invite Presented Count"

@implementation InviteUtils

+ (ABContact *)contactToBePresented {
    // get all contacts
    NSArray *aBContacts = [DatastoreUtils getAllABContactsLocally];
    
    // attribute score
    NSInteger maxScore = 0;
    NSMutableArray *maxScoreContacts = [NSMutableArray new];
    for (ABContact *contact in aBContacts) {
        NSInteger score = contact.users.count / (1 + contact.inviteCount);
        if (score == maxScore) {
            [maxScoreContacts addObject:contact];
        } else if (score > maxScore) {
            maxScore = score;
            [maxScoreContacts removeAllObjects];
            [maxScoreContacts addObject:contact];
        }
    }
    
    // Get one randomly
    return [maxScoreContacts objectAtIndex:(arc4random() % [maxScoreContacts count])];
}

+ (BOOL)shouldPresentInviteController {
    return [InviteUtils getInvitePresentedCount] < kMaxInvitePresentedCount && ([[NSDate date] compare:[[InviteUtils getLastInvitePresentedDate] dateByAddingTimeInterval:kMinInvitePresentedInterval]] == NSOrderedDescending);
}

+ (NSDate *)getLastInvitePresentedDate
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    return [prefs objectForKey:LAST_INVITE_PRESENTED_DATE] ? [prefs objectForKey:LAST_INVITE_PRESENTED_DATE] : [NSDate date];
}

+ (void)setLastInvitePresentedDate:(NSDate *)date
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:date forKey:LAST_INVITE_PRESENTED_DATE];
    [prefs synchronize];
}

+ (NSInteger)getInvitePresentedCount
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    return [prefs objectForKey:INVITE_PRESENTED_COUNT] ? [[prefs objectForKey:INVITE_PRESENTED_COUNT] integerValue]: 0;
}

+ (void)incrementInvitePresentedCount
{
    NSInteger count = [InviteUtils getInvitePresentedCount] + 1;
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:[NSNumber numberWithInteger:count] forKey:INVITE_PRESENTED_COUNT];
    [prefs synchronize];
}

@end
