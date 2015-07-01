//
//  ABContact.m
//  FlashTape
//
//  Created by Baptiste Truchot on 6/29/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//

#import "ABContact.h"

@implementation ABContact

@dynamic users;
@dynamic number;
@dynamic inviteCount;
@dynamic inviteSeenCount;
@dynamic isFlasher;

+ (void)load {
    [self registerSubclass];
}

+ (NSString * __nonnull)parseClassName
{
    return NSStringFromClass([self class]);
}

+ (ABContact *)createRelationWithNumber:(NSString *)number {
    ABContact *contact = [ABContact new];
    contact.number = number;
    contact.inviteCount = 0;
    contact.inviteSeenCount = 0;
    return contact;
}

- (NSInteger)contactScore {
    NSInteger inviteSendCount = self.inviteCount ? self.inviteCount : 0;
    NSInteger invitePresentedCount = self.inviteSeenCount ? self.inviteSeenCount : 0;
    return self.users.count / ( 1 + inviteSendCount + invitePresentedCount / 5);
}

@end
