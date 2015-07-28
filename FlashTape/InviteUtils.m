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

#define GHOST_INVITE_COUNT @"Ghost Invite Count Pref"

@implementation InviteUtils

+ (void)pickContactsToPresent:(NSInteger)count
                      success:(void(^)(NSArray *contacts))successBlock
                      failure:(void(^)(NSError *error))failureBlock
{
   [DatastoreUtils getAllABContactsLocallySuccess:^(NSArray *aBContacts) {
       if (aBContacts.count <= count) {
           successBlock(aBContacts);
       }
       
       NSArray *sortedContacts = [aBContacts sortedArrayUsingComparator:^NSComparisonResult(ABContact *obj1, ABContact *obj2) {
           if ([obj1 contactScore] >= [obj2 contactScore]) {
               return NSOrderedAscending;
           } else {
               return NSOrderedDescending;
           }
       }];
       if (successBlock) {
           successBlock([sortedContacts subarrayWithRange:NSMakeRange(0, count)]);
       }
   } failure:^(NSError *error) {
       if (failureBlock) {
           failureBlock(error);
       }
   }];
}

+ (BOOL)shouldPresentInviteController {
    return [InviteUtils getVideoSeenSinceLastInvitePresentedCount] > kMaxVideoSeenBetweenInvite * (1 + MIN(50,[User currentUser].score) / 10.);
}

+ (NSInteger)getVideoSeenSinceLastInvitePresentedCount
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    return [prefs objectForKey:VIDEO_SEEN_SINCE_LAST_INVITE] ? [[prefs objectForKey:VIDEO_SEEN_SINCE_LAST_INVITE] integerValue]: 12;
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

+ (void)setGhostInviteCount:(NSInteger)count
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:[NSNumber numberWithInteger:count] forKey:GHOST_INVITE_COUNT];
    [prefs synchronize];
}

+ (NSInteger)getGhostInviteCount
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    return [prefs objectForKey:GHOST_INVITE_COUNT] ? [[prefs objectForKey:GHOST_INVITE_COUNT] integerValue] : 0;
}

@end
