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
    contact.inviteSeenCount = [NSNumber numberWithInt:0];
    return contact;
}

- (CGFloat)contactScore {
    CGFloat inviteSendCount = self.inviteCount ? self.inviteCount : 0.;
    CGFloat invitePresentedCount = self.inviteSeenCount ? [self.inviteSeenCount integerValue] : 0.;
    return (CGFloat) self.users.count / ( 1 + 1.5 * inviteSendCount + 0.5 * invitePresentedCount);
}

+ (NSArray *)sortABContacts:(NSArray *)contacts contactDictionnary:(NSDictionary *)contactDictionnary
{
    return [contacts sortedArrayUsingComparator:^NSComparisonResult(ABContact *obj1, ABContact *obj2) {
        if ([obj1 contactScore] > [obj2 contactScore]) {
            return NSOrderedAscending;
        } else if ([obj1 contactScore] < [obj2 contactScore]) {
            return NSOrderedDescending;
        } else {
            NSString *name1 = contactDictionnary[obj1.number] ? contactDictionnary[obj1.number] : @"?";
            NSString *name2 = contactDictionnary[obj2.number] ? contactDictionnary[obj2.number] : @"?";
            return [name1 caseInsensitiveCompare:name2];
        }
    }];
}



@end
