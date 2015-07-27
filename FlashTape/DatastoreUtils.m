//
//  DatastoreUtils.m
//  FlashTape
//
//  Created by Baptiste Truchot on 5/26/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
#import "ABContact.h"
#import "Follow.h"
#import "Message.h"
#import "User.h"
#import "VideoPost.h"

#import "ConstantUtils.h"
#import "DatastoreUtils.h"

#define LAST_MESSAGE_DICTIONNARY @"Last Message date dictionnary"

@implementation DatastoreUtils


// --------------------------------------------
#pragma mark - Users
// --------------------------------------------

// Following
+ (void)getFollowingRelationsLocallyAndExecuteSuccess:(void(^)(NSArray *followingRelations))successBlock
                                              failure:(void(^)(NSError *error))failureBlock
{
    PFQuery *query = [PFQuery queryWithClassName:[Follow parseClassName]];
    [query fromLocalDatastore];
    [query whereKey:@"from" equalTo:[User currentUser]];
    [query whereKey:@"to" notEqualTo:[User currentUser]];
    [query includeKey:@"to"];
    [query setLimit:1000];
    [query findObjectsInBackgroundWithBlock:^(NSArray *followingRelations, NSError *error) {
        if (!error) {
            // Get last message date from user default
            NSDictionary *lastMessageDic = [DatastoreUtils getLastMessageDateDictionnary];
            for (Follow *follow in followingRelations) {
                User *followedUser = follow.to;
                followedUser.lastMessageDate = lastMessageDic[followedUser.objectId] ? lastMessageDic[followedUser.objectId] : [NSDate dateWithTimeIntervalSince1970:0];
            }
            
            if (successBlock) {
                successBlock(followingRelations);
            }
        } else {
            // Log details of the failure
            NSLog(@"Error in following from local datastore: %@ %@", error, [error userInfo]);
            if (failureBlock)
                failureBlock(error);
        }
    }];
}

// Followers
+ (void)getFollowerRelationsLocallyAndExecuteSuccess:(void(^)(NSArray *followerRelations))successBlock
                                             failure:(void(^)(NSError *error))failureBlock
{
    PFQuery *query = [PFQuery queryWithClassName:[Follow parseClassName]];
    [query fromLocalDatastore];
    [query whereKey:@"to" equalTo:[User currentUser]];
    [query whereKey:@"from" notEqualTo:[User currentUser]];
    [query includeKey:@"from"];
    [query setLimit:1000];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            if (successBlock) {
                successBlock(objects);
            }
        } else {
            // Log details of the failure
            NSLog(@"Error in followers from local datastore: %@ %@", error, [error userInfo]);
            if (failureBlock)
                failureBlock(error);
        }
    }];
}

// Unfollowed Followers
+ (void)getUnfollowedFollowersLocallyAndExecuteSuccess:(void(^)(NSArray *followers))successBlock
                                               failure:(void(^)(NSError *error))failureBlock
{
    PFQuery *followerQuery = [PFQuery queryWithClassName:[Follow parseClassName]];
    [followerQuery fromLocalDatastore];
    [followerQuery whereKey:@"to" equalTo:[User currentUser]];
    
    PFQuery *followingQuery = [PFQuery queryWithClassName:[Follow parseClassName]];
    [followingQuery fromLocalDatastore];
    [followingQuery whereKey:@"from" equalTo:[User currentUser]];
    
    PFQuery *userQuery = [User query];
    [userQuery setLimit:1000];
    [userQuery fromLocalDatastore];
    [userQuery whereKey:@"this" matchesKey:@"from" inQuery:followerQuery];
    [userQuery whereKey:@"this" doesNotMatchKey:@"to" inQuery:followingQuery];
    
    [userQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
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

// Get unrelated user in addressbook
+ (void)getUnrelatedUserInAddressBook:(NSArray *)number
                              success:(void(^)(NSArray *unrelatedUser))successBlock
                              failure:(void(^)(NSError *error))failureBlock
{
    PFQuery *followerRelationQuery = [PFQuery queryWithClassName:[Follow parseClassName]];
    [followerRelationQuery fromLocalDatastore];
    [followerRelationQuery whereKey:@"to" equalTo:[User currentUser]];
    // Strange artefact because we can't use two doesNotMatchKey: inquery: with parse
    PFQuery *followerQuery = [User query];
    [followerQuery whereKey:@"this" matchesKey:@"from" inQuery:followerRelationQuery];
    
    PFQuery *followingQuery = [PFQuery queryWithClassName:[Follow parseClassName]];
    [followingQuery fromLocalDatastore];
    [followingQuery whereKey:@"from" equalTo:[User currentUser]];
    
    PFQuery *userQuery = [User query];
    [userQuery setLimit:1000];
    [userQuery fromLocalDatastore];
    [userQuery whereKey:@"username" notEqualTo:[User currentUser].username];
    [userQuery whereKey:@"username" containedIn:number];
    [userQuery whereKey:@"this" doesNotMatchKey:@"to" inQuery:followingQuery];
    [userQuery whereKey:@"this" doesNotMatchQuery:followerQuery];
    
    [userQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
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

+ (Follow *)getRelationWithFollower:(User *)follower
                          following:(User *)following
{
    PFQuery *query = [PFQuery queryWithClassName:[Follow parseClassName]];
    [query setLimit:1000];
    [query fromLocalDatastore];
    [query whereKey:@"to" equalTo:following];
    [query whereKey:@"from" equalTo:follower];
    return [query findObjects].firstObject;
}

// Any
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

// --------------------------------------------
#pragma mark - ABContacts
// --------------------------------------------
+ (void)getAllABContactsLocallySuccess:(void(^)(NSArray *contacts))successBlock
                                failure:(void(^)(NSError *error))failureBlock
{
    PFQuery *query = [PFQuery queryWithClassName:[ABContact parseClassName]];
    [query fromLocalDatastore];
    [query fromPinWithName:kParseABContacts];
    [query setLimit:1000];
    [query whereKey:@"isFlasher" notEqualTo:[NSNumber numberWithBool:true]];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            if (successBlock) {
                successBlock(objects);
            }
        } else {
            if (failureBlock)
                failureBlock(error);
        }
    }];
}

// --------------------------------------------
#pragma mark - Videos
// --------------------------------------------

+ (void)getVideoLocallyFromUsers:(NSArray *)users
                         success:(void(^)(NSArray *videos))successBlock
                         failure:(void(^)(NSError *error))failureBlock
{
    PFQuery *query = [PFQuery queryWithClassName:[VideoPost parseClassName]];
    [query fromLocalDatastore];
    [query whereKey:@"createdAt" greaterThan:[[NSDate date] dateByAddingTimeInterval:-3600*kFeedHistoryInHours]];
    [query whereKey:@"user" containedIn:users];
    [query orderByAscending:@"recordedAt"];
    [query setLimit:1000];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            [VideoPost downloadVideoFromPosts:objects];
            if (successBlock) {
                successBlock(objects);
            }
        } else {
            // Log details of the failure
            NSLog(@"Error in video from local datastore: %@ %@", error, [error userInfo]);
            if (failureBlock)
                failureBlock(error);
        }
    }];
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
    PFQuery *query = [PFQuery queryWithClassName:[VideoPost parseClassName]];
    [query fromLocalDatastore];
    [query setLimit:1000];
    [query whereKeyExists:@"objectId"]; // to avoid unsent vids
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
    PFQuery *query = [PFQuery queryWithClassName:[VideoPost parseClassName]];
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

+ (void)unpinVideoAsUnsend:(VideoPost *)post {
    [post unpinInBackgroundWithName:kParseFailedPostsName];
}

+ (void)pinVideoAsUnsend:(VideoPost *)post {
    [post pinInBackgroundWithName:kParseFailedPostsName];
}

+ (void)getUnsendVideosSuccess:(void(^)(NSArray *videos))successBlock
                       failure:(void(^)(NSError *error))failureBlock {
    PFQuery *query = [PFQuery queryWithClassName:[VideoPost parseClassName]];
    [query fromLocalDatastore];
    [query fromPinWithName:kParseFailedPostsName];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (error == nil) {
            for (VideoPost *post in objects) {
                post.localUrl = [post videoLocalURL];
            }
            if (successBlock) {
                successBlock(objects);
            }
        } else {
            if (failureBlock) {
                failureBlock(error);
            }
        }
    }];
}

// --------------------------------------------
#pragma mark - Messages
// --------------------------------------------

+ (void)getUnreadMessagesLocallySuccess:(void(^)(NSArray *messages))successBlock
                                failure:(void(^)(NSError *error))failureBlock
{
    PFQuery *query = [PFQuery queryWithClassName:[Message parseClassName]];
    [query fromLocalDatastore];
    [query orderByAscending:@"sentAt"];
    [query whereKey:@"read" equalTo:[NSNumber numberWithBool:false]];
    [query includeKey:@"sender"];
    [query setLimit:1000];
    [query findObjectsInBackgroundWithBlock:^(NSArray *messages, NSError *error) {
        if (!error) {
            if (successBlock) {
                successBlock(messages);
            }
        } else {
            if (failureBlock) {
                failureBlock(error);
            }
        }
    }];
}




@end
