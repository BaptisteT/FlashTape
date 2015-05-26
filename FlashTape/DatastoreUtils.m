//
//  DatastoreUtils.m
//  FlashTape
//
//  Created by Baptiste Truchot on 5/26/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
#import "User.h"
#import "VideoPost.h"

#import "ConstantUtils.h"
#import "DatastoreUtils.h"


@implementation DatastoreUtils

+ (void)getFriendsFromLocalDatastoreAndExecuteSuccess:(void(^)(NSArray *friends))successBlock
                                              failure:(void(^)(NSError *error))failureBlock
{
    PFQuery *query = [User query];
    [query fromLocalDatastore];
    [query orderByDescending:@"score"];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            if (successBlock) {
                successBlock(objects);
            }
        } else {
            // Log details of the failure
            NSLog(@"Error in friends from local datastore: %@ %@", error, [error userInfo]);
            if (failureBlock)
                failureBlock(error);
        }
    }];
}

+ (NSArray *)getVideoLocallyFromUser:(User *)user
{
    PFQuery *query = [PFQuery queryWithClassName:@"VideoPost"];
    [query fromLocalDatastore];
    [query whereKey:@"createdAt" greaterThan:[[NSDate date] dateByAddingTimeInterval:-3600*kFeedHistoryInHours]];
    if (user) {
        [query whereKey:@"user"  equalTo:user];
    }
    [query orderByAscending:@"createdAt"];
    [query includeKey:@"user"];
    [query setLimit:1000];
    NSArray *results = [query findObjects];
    [VideoPost downloadVideoFromPosts:results];
    return results;
}

+ (void)getExpiredVideoFromLocalDataStoreAndExecute:(void(^)(NSArray *posts))block
{
    PFQuery *query = [PFQuery queryWithClassName:@"VideoPost"];
    [query fromLocalDatastore];
    [query whereKey:@"createdAt" lessThan:[[NSDate date] dateByAddingTimeInterval:-3600*kFeedHistoryInHours]];
    [query setLimit:1000];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (error == nil) {
            block(objects);
        } else {
            NSLog(@"Local Datastore Expired Video Error: %@ %@", error, [error userInfo]);
        }
    }];
}

+ (void)deleteExpiredPosts
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [DatastoreUtils getExpiredVideoFromLocalDataStoreAndExecute:^(NSArray *posts) {
        NSError *error;
        for (VideoPost *post in posts) {
            if (![fileManager removeItemAtURL:[post videoLocalURL] error:&error]) {
                 NSLog(@"Error deleting: %@",error);
            } else {
                [post unpinInBackground];
            }
        }
    }];
}

@end
