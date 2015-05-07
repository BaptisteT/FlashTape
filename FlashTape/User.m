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

+ (User *)createUserWithNumber:(NSString *)phoneNumber
{
    User *user = (User *)[PFUser user];
    user.username = phoneNumber;
    user.password = @"";
    return user;
}

+ (User *)currentUser {
    return (User *)[PFUser currentUser];
}

@end
