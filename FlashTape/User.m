//
//  User.m
//  FlashTape
//
//  Created by Baptiste Truchot on 5/6/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//

#import <Parse/PFObject+Subclass.h>
#import "User.h"


@implementation User

@dynamic score;
@dynamic flashUsername;
@dynamic transformedUsername;

+ (void)load {
    [self registerSubclass];
}

+ (User *)createUserWithNumber:(NSString *)phoneNumber
{
    User *user = (User *)[PFUser user];
    user.username = phoneNumber;
    user.flashUsername = @"";
    user.transformedUsername = @"";
    user.password = @"";
    user.score = 0;
    return user;
}

+ (User *)currentUser {
    return (User *)[PFUser currentUser];
}


- (NSInteger)score {
    return [[self objectForKey:@"score"] integerValue];
}

@end
