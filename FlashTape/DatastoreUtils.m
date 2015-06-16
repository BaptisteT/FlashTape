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

#define LAST_MESSAGE_DICTIONNARY @"Last Message date dictionnary"

@implementation DatastoreUtils


// --------------------------------------------
#pragma mark - Users
// --------------------------------------------

+ (void)getFollowingFromLocalDatastoreAndExecuteSuccess:(void(^)(NSArray *following))successBlock
                                              failure:(void(^)(NSError *error))failureBlock
{
    PFQuery *query = [User query];
    [query fromLocalDatastore];
    [query fromPinWithName:kParseFollowingName];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            // Get last message date from user default
            NSDictionary *lastMessageDic = [DatastoreUtils getLastMessageDateDictionnary];
            for (User *user in objects) {
                user.lastMessageDate = lastMessageDic[user.objectId] ? lastMessageDic[user.objectId] : [NSDate dateWithTimeIntervalSince1970:0];
            }
            
            if (successBlock) {
                successBlock(objects);
            }
        } else {
            // Log details of the failure
            NSLog(@"Error in following from local datastore: %@ %@", error, [error userInfo]);
            if (failureBlock)
                failureBlock(error);
        }
    }];
}

+ (void)getFollowersFromLocalDatastoreAndExecuteSuccess:(void(^)(NSArray *followers))successBlock
                                                failure:(void(^)(NSError *error))failureBlock
{
    PFQuery *query = [User query];
    [query fromLocalDatastore];
    [query fromPinWithName:kParseFollowersName];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            if (successBlock) {
                successBlock(objects);
            }
        } else {
            // Log details of the failure
            NSLog(@"Error in folloers from local datastore: %@ %@", error, [error userInfo]);
            if (failureBlock)
                failureBlock(error);
        }
    }];
}

+ (NSArray *)getNamesOfUsersWithId:(NSArray *)idsArray
{
    PFQuery *query = [User query];
    [query fromLocalDatastore];
    [query whereKey:@"objectId" containedIn:idsArray];
    NSArray *users = [query findObjects];
    NSMutableArray *names = [NSMutableArray new];
    for (User *user in users) {
        [names addObject:user.flashUsername];
    }
    return names;
}


// --------------------------------------------
#pragma mark - Videos
// --------------------------------------------

+ (NSArray *)getVideoLocallyFromUsers:(NSArray *)users
{
    PFQuery *query = [PFQuery queryWithClassName:@"VideoPost"];
    [query fromLocalDatastore];
    [query whereKey:@"createdAt" greaterThan:[[NSDate date] dateByAddingTimeInterval:-3600*kFeedHistoryInHours]];
    [query whereKey:@"user" containedIn:users];
    [query orderByAscending:@"recordedAt"];
    [query setLimit:1000];
    NSArray *results = [query findObjects];
    [VideoPost downloadVideoFromPosts:results];
    return results;
}

+ (void)deleteLocalPostsNotInRemotePosts:(NSArray *)remotelyRetrievedPosts
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [DatastoreUtils getVideoInLocalDatastoreAndExecute:^(NSArray *posts) {
        NSError *error;
        for (VideoPost *post in posts) {
            if ([remotelyRetrievedPosts indexOfObject:post] == NSNotFound) {
                // Delete object
                if (![fileManager fileExistsAtPath:[post videoLocalURL].path]) {
                    [post unpinInBackgroundWithName:kParsePostsName];
                } else if (![fileManager removeItemAtURL:[post videoLocalURL] error:&error]) {
                    NSLog(@"Error deleting: %@",error);
                } else {
                    [post unpinInBackgroundWithName:kParsePostsName];
                }
            }
        }
    }];
}

+ (void)getVideoInLocalDatastoreAndExecute:(void(^)(NSArray *posts))block
{
    PFQuery *query = [PFQuery queryWithClassName:@"VideoPost"];
    [query fromLocalDatastore];
    [query setLimit:1000];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (error == nil) {
            block(objects);
        } else {
            NSLog(@"Local Datastore Expired Video Error: %@ %@", error, [error userInfo]);
        }
    }];
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
            if (![fileManager fileExistsAtPath:[post videoLocalURL].path]) {
                 [post unpinInBackgroundWithName:kParsePostsName];
            } else if (![fileManager removeItemAtURL:[post videoLocalURL] error:&error]) {
                 NSLog(@"Error deleting: %@",error);
            } else {
                [post unpinInBackgroundWithName:kParsePostsName];
            }
        }
    }];
}


// --------------------------------------------
#pragma mark - Messages
// --------------------------------------------

+ (NSArray *)getUnreadMessagesLocally
{
    PFQuery *query = [PFQuery queryWithClassName:@"Message"];
    [query fromLocalDatastore];
    [query orderByAscending:@"createdAt"];
    [query whereKey:@"read" equalTo:[NSNumber numberWithBool:false]];
    [query includeKey:@"sender"];
    [query setLimit:1000];
    NSArray *results = [query findObjects];
    return results;
}

+ (NSArray *)getMessagesLocallyFromUser:(User *)user
{
    PFQuery *query = [PFQuery queryWithClassName:@"Message"];
    [query fromLocalDatastore];
    [query whereKey:@"sender" equalTo:user];
    [query setLimit:1000];
    NSArray *results = [query findObjects];
    return results;
}

// --------------------------------------------
#pragma mark - Last Message date
// --------------------------------------------
+ (NSDictionary *)getLastMessageDateDictionnary {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    return [prefs objectForKey:LAST_MESSAGE_DICTIONNARY];
}

+ (void)saveLastMessageDate:(NSDate *)date ofUser:(NSString *)userId
{
    NSMutableDictionary *lastMessageDateDictionnary = [NSMutableDictionary dictionaryWithDictionary:[self getLastMessageDateDictionnary]];
    if (!lastMessageDateDictionnary) {
        lastMessageDateDictionnary = [NSMutableDictionary new];
    }
    [lastMessageDateDictionnary setObject:date forKey:userId];
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:lastMessageDateDictionnary forKey:LAST_MESSAGE_DICTIONNARY];
    [prefs synchronize];
}

@end
