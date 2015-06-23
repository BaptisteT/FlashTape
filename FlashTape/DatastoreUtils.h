//
//  DatastoreUtils.h
//  FlashTape
//
//  Created by Baptiste Truchot on 5/26/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
#import <Foundation/Foundation.h>
@class User;
@class Follow;

@interface DatastoreUtils : NSObject

// --------------------------------------------
#pragma mark - Users
// --------------------------------------------

// Following
+ (void)getFollowingRelationsLocallyAndExecuteSuccess:(void(^)(NSArray *followingRelations))successBlock
                                              failure:(void(^)(NSError *error))failureBlock;

// Followers
+ (void)getFollowerRelationsLocallyAndExecuteSuccess:(void(^)(NSArray *followerRelations))successBlock
                                             failure:(void(^)(NSError *error))failureBlock;

// Unfollowed Followers
+ (void)getUnfollowedFollowerRelationsLocallyAndExecuteSuccess:(void(^)(NSArray *followerRelations))successBlock
                                                       failure:(void(^)(NSError *error))failureBlock;

+ (Follow *)getRelationWithFollower:(User *)follower
                          following:(User *)following;

+ (NSArray *)getNamesOfUsersWithId:(NSArray *)idsArray;


+ (NSDictionary *)getLastMessageDateDictionnary;

+ (void)saveLastMessageDate:(NSDate *)date ofUser:(NSString *)userId;

// --------------------------------------------
#pragma mark - Video
// --------------------------------------------
+ (void)getVideoLocallyFromUsers:(NSArray *)users
                         success:(void(^)(NSArray *videos))successBlock
                         failure:(void(^)(NSError *error))failureBlock;

+ (void)getExpiredVideoFromLocalDataStoreAndExecute:(void(^)(NSArray *posts))block;

+ (void)deleteExpiredPosts;

+ (void)deleteLocalPostsNotInRemotePosts:(NSArray *)remotelyRetrievedPosts;


// --------------------------------------------
#pragma mark - Messages
// --------------------------------------------

+ (NSArray *)getUnreadMessagesLocally;

+ (NSArray *)getMessagesLocallyFromUser:(User *)user;


@end
