//
//  Follow.m
//  FlashTape
//
//  Created by Baptiste Truchot on 6/22/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//

#import "Follow.h"

#import "ConstantUtils.h"
#import "FlashLogger.h"

#define FLASHFOLLOWLOG YES && GLOBALLOGENABLED

@implementation Follow

@dynamic to;
@dynamic from;
@dynamic mute;
@dynamic blocked;

+ (void)load {
    [self registerSubclass];
}

+ (NSString * __nonnull)parseClassName
{
    return NSStringFromClass([self class]);
}

+ (Follow *)createRelationWithFollowing:(User *)user {
    Follow *follow = [Follow new];
    follow.from = [User currentUser];
    follow.to = user;
    follow.mute = NO;
    follow.blocked = NO;
    return follow;
}


@end
