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
#import "FlashLogger.h"

#define LAST_MESSAGE_DICTIONNARY @"Last Message date dictionnary"
#define FLASHDATASTORELOG YES && GLOBALLOGENABLED

@implementation DatastoreUtils


// --------------------------------------------
#pragma mark - Users
// --------------------------------------------

// Following
+ (void)getFollowingRelationsLocallyAndExecuteSuccess:(void(^)(NSArray *followingRelations))successBlock
                                              failure:(void(^)(NSError *error))failureBlock
{
    FlashLog(FLASHDATASTORELOG,@"Datastore => get following relations");
    PFQuery *query = [PFQuery queryWithClassName:[Follow parseClassName]];
    [query fromLocalDatastore];
    [query whereKey:@"from" equalTo:[User currentUser]];
    [query whereKey:@"to" notEqualTo:[User currentUser]];
    [query includeKey:@"to"];
    [query setLimit:1000];
    [query findObjectsInBackgroundWithBlock:^(NSArray *followingRelations, NSError *error) {
        if (!error) {
            FlashLog(FLASHDATASTORELOG,@"Datastore => %lu following relations found",followingRelations.count);
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
            FlashLog(FLASHDATASTORELOG,@"Error in following from local datastore: %@ %@", error, [error userInfo]);
            if (failureBlock)
                failureBlock(error);
        }
    }];
}

// Followers
+ (void)getFollowerRelationsLocallyAndExecuteSuccess:(void(^)(NSArray *followerRelations))successBlock
                                             failure:(void(^)(NSError *error))failureBlock
{
    FlashLog(FLASHDATASTORELOG,@"Datastore => get follower relations");
    PFQuery *query = [PFQuery queryWithClassName:[Follow parseClassName]];
    [query fromLocalDatastore];
    [query whereKey:@"to" equalTo:[User currentUser]];
    [query whereKey:@"from" notEqualTo:[User currentUser]];
    [query includeKey:@"from"];
    [query setLimit:1000];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            FlashLog(FLASHDATASTORELOG,@"Datastore => %lu follower relations found",objects.count);
            if (successBlock) {
                successBlock(objects);
            }
        } else {
            // Log details of the failure
            FlashLog(FLASHDATASTORELOG,@"Error in followers from local datastore: %@ %@", error, [error userInfo]);
            if (failureBlock)
                failureBlock(error);
        }
    }];
}

// Unfollowed Followers
+ (void)getUnfollowedFollowersLocallyAndExecuteSuccess:(void(^)(NSArray *followers))successBlock
                                               failure:(void(^)(NSError *error))failureBlock
{
    FlashLog(FLASHDATASTORELOG,@"Datastore => get unfollowed followers");
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
            FlashLog(FLASHDATASTORELOG,@"Datastore => %lu unfollowed followers found",objects.count);
            if (successBlock) {
                successBlock(objects);
            }
        } else {
            // Log details of the failure
            FlashLog(FLASHDATASTORELOG,@"Error in followers from local datastore: %@ %@", error, [error userInfo]);
            if (failureBlock)
                failureBlock(error);
        }
    }];
}

// Get unrelated user in addressbook
+ (void)getUnrelatedUserInAddressBook:(NSArray *)phoneNumbers
                              success:(void(^)(NSArray *unrelatedUser))successBlock
                              failure:(void(^)(NSError *error))failureBlock
{
    FlashLog(FLASHDATASTORELOG,@"Datastore => get unrelated user");
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
    
    NSMutableArray *numbers = [NSMutableArray arrayWithArray:phoneNumbers];
    [numbers removeObject:[User currentUser].username];
    [userQuery whereKey:@"username" containedIn:numbers];
    [userQuery whereKey:@"this" doesNotMatchKey:@"to" inQuery:followingQuery];
    [userQuery whereKey:@"this" doesNotMatchQuery:followerQuery];
    
    [userQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            FlashLog(FLASHDATASTORELOG,@"Datastore => %lu unrelated users found",objects.count);
            if (successBlock) {
                successBlock(objects);
            }
        } else {
            // Log details of the failure
            FlashLog(FLASHDATASTORELOG,@"Datastore => error in unrelated users %@ %@", error, [error userInfo]);
            if (failureBlock)
                failureBlock(error);
        }
    }];
}

+ (Follow *)getRelationWithFollower:(User *)follower
                          following:(User *)following
{
    FlashLog(FLASHDATASTORELOG,@"Datastore => get relation with follower");
    PFQuery *query = [PFQuery queryWithClassName:[Follow parseClassName]];
    [query setLimit:1000];
    [query fromLocalDatastore];
    [query whereKey:@"to" equalTo:following];
    [query whereKey:@"from" equalTo:follower];
    return [query findObjects].firstObject;
}

+ (NSArray *)getNamesOfUsersWithId:(NSArray *)idsArray
{
    FlashLog(FLASHDATASTORELOG,@"Datastore => get name of users");
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
    FlashLog(FLASHDATASTORELOG,@"Datastore => get last message date");
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    return [prefs objectForKey:LAST_MESSAGE_DICTIONNARY];
}

+ (void)saveLastMessageDate:(NSDate *)date ofUser:(NSString *)userId
{
    FlashLog(FLASHDATASTORELOG,@"Datastore => save last message date");
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
    FlashLog(FLASHDATASTORELOG,@"Datastore => get all AB Contacts");
    PFQuery *query = [PFQuery queryWithClassName:[ABContact parseClassName]];
    [query fromLocalDatastore];
    [query fromPinWithName:kParseABContacts];
    [query setLimit:1000];
    [query whereKey:@"isFlasher" notEqualTo:[NSNumber numberWithBool:true]];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            FlashLog(FLASHDATASTORELOG,@"Datastore => %lu AB Contacts found",objects.count);
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
    FlashLog(FLASHDATASTORELOG,@"Datastore => get video from friends");
    PFQuery *query = [PFQuery queryWithClassName:[VideoPost parseClassName]];
    [query fromLocalDatastore];
    [query whereKey:@"createdAt" greaterThan:[[NSDate date] dateByAddingTimeInterval:-3600*kFeedHistoryInHours]];
    [query whereKey:@"user" containedIn:users];
    [query orderByAscending:@"recordedAt"];
    [query setLimit:1000];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            FlashLog(FLASHDATASTORELOG,@"Datastore => %lu video found",objects.count);
            [VideoPost downloadVideoFromPosts:objects];
            if (successBlock) {
                successBlock(objects);
            }
        } else {
            // Log details of the failure
            FlashLog(FLASHDATASTORELOG,@"Error in video from local datastore: %@ %@", error, [error userInfo]);
            if (failureBlock)
                failureBlock(error);
        }
    }];
}

+ (void)deleteLocalPostsNotInRemotePosts:(NSArray *)remotelyRetrievedPosts
{
    FlashLog(FLASHDATASTORELOG,@"Datastore => delete local posts not in remote");
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [DatastoreUtils getVideoInLocalDatastoreAndExecute:^(NSArray *posts) {
        NSError *error;
        for (VideoPost *post in posts) {
            if ([remotelyRetrievedPosts indexOfObject:post] == NSNotFound) {
                // Delete object
                if (![fileManager fileExistsAtPath:[post videoLocalURL].path]) {
                    [post unpinInBackgroundWithName:kParsePostsName];
                } else if (![fileManager removeItemAtURL:[post videoLocalURL] error:&error]) {
                    FlashLog(FLASHDATASTORELOG,@"Error deleting: %@",error);
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
            FlashLog(FLASHDATASTORELOG,@"Local Datastore Expired Video Error: %@ %@", error, [error userInfo]);
        }
    }];
}

+ (void)getExpiredVideoFromLocalDataStoreAndExecute:(void(^)(NSArray *posts))block
{
    FlashLog(FLASHDATASTORELOG,@"Datastore => get expired videos");
    PFQuery *query = [PFQuery queryWithClassName:[VideoPost parseClassName]];
    [query fromLocalDatastore];
    [query whereKey:@"createdAt" lessThan:[[NSDate date] dateByAddingTimeInterval:-3600*kFeedHistoryInHours]];
    [query setLimit:1000];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (error == nil) {
            block(objects);
        } else {
            FlashLog(FLASHDATASTORELOG,@"Local Datastore Expired Video Error: %@ %@", error, [error userInfo]);
        }
    }];
}

+ (void)deleteExpiredPosts
{
    FlashLog(FLASHDATASTORELOG,@"Datastore => delete expired videos");
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [DatastoreUtils getExpiredVideoFromLocalDataStoreAndExecute:^(NSArray *posts) {
        NSError *error;
        for (VideoPost *post in posts) {
            if (![fileManager fileExistsAtPath:[post videoLocalURL].path]) {
                 [post unpinInBackgroundWithName:kParsePostsName];
            } else if (![fileManager removeItemAtURL:[post videoLocalURL] error:&error]) {
                 FlashLog(FLASHDATASTORELOG,@"Error deleting: %@",error);
            } else {
                [post unpinInBackgroundWithName:kParsePostsName];
            }
        }
    }];
}

+ (void)unpinVideoAsUnsend:(VideoPost *)post {
    FlashLog(FLASHDATASTORELOG,@"Datastore => unpin video failed");
    [post unpinInBackgroundWithName:kParseFailedPostsName];
}

+ (void)pinVideoAsUnsend:(VideoPost *)post {
    FlashLog(FLASHDATASTORELOG,@"Datastore => pin video failed");
    [post pinInBackgroundWithName:kParseFailedPostsName];
}

+ (void)getUnsendVideosSuccess:(void(^)(NSArray *videos))successBlock
                       failure:(void(^)(NSError *error))failureBlock
{
    FlashLog(FLASHDATASTORELOG,@"Datastore => get unsend videos");
    PFQuery *query = [PFQuery queryWithClassName:[VideoPost parseClassName]];
    [query fromLocalDatastore];
    [query fromPinWithName:kParseFailedPostsName];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (error == nil) {
            FlashLog(FLASHDATASTORELOG,@"Datastore => %lu unsend videos",objects.count);
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
    FlashLog(FLASHDATASTORELOG,@"Datastore => get unread messages");
    PFQuery *query = [PFQuery queryWithClassName:[Message parseClassName]];
    [query fromLocalDatastore];
    [query orderByAscending:@"sentAt"];
    [query whereKey:@"read" equalTo:[NSNumber numberWithBool:false]];
    [query includeKey:@"sender"];
    [query setLimit:1000];
    [query findObjectsInBackgroundWithBlock:^(NSArray *messages, NSError *error) {
        if (!error) {
            FlashLog(FLASHDATASTORELOG,@"Datastore => %lu unread messages found",messages.count);
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
