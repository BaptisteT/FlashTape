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
#import "FlashLogger.h"

#define FLASHUSERLOG YES && GLOBALLOGENABLED

@implementation User

@dynamic score;
@dynamic flashUsername;
@dynamic transformedUsername;
@dynamic addressbookName;
@dynamic emojiUnlocked;
@dynamic this;

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
    user.score = kUserInitialScore;
    user.emojiUnlocked = NO;
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

+ (BOOL)contactNumber:(NSString *)number
       belongsToUsers:(NSArray *)users
{
    for (User *user in users) {
        if ([user.username isEqualToString:number]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)isDirtyForKey:(NSString * __nonnull)key {
    return [super isDirtyForKey:key];
}

- (BOOL)isDirty {
    FlashLog(FLASHUSERLOG,@"User isDirty");
    return [super isDirty];
}

@end
