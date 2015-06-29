//
//  User.m
//  FlashTape
//
//  Created by Baptiste Truchot on 5/6/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//

#import <Parse/PFObject+Subclass.h>
#import "User.h"

#import "DatastoreUtils.h"

#import "ConstantUtils.h"

@implementation User

@dynamic score;
@dynamic flashUsername;
@dynamic transformedUsername;

@synthesize lastMessageDate;

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

+ (BOOL)isAdminUser:(User *)user {
    return [user.objectId isEqualToString:kAdminUserObjectId];
}

- (NSInteger)score {
    return [[self objectForKey:@"score"] integerValue];
}

- (void)updateLastMessageDate:(NSDate *)date {
    if (!self.lastMessageDate || [self.lastMessageDate compare:date] == NSOrderedAscending) {
        self.lastMessageDate = date;
        [DatastoreUtils saveLastMessageDate:self.lastMessageDate ofUser:self.objectId];
    }
}

@end
