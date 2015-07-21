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
@class VideoPost;

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
+ (void)getUnfollowedFollowersLocallyAndExecuteSuccess:(void(^)(NSArray *followers))successBlock
                                               failure:(void(^)(NSError *error))failureBlock;

// Get unrelated user in addressbook
+ (void)getUnrelatedUserInAddressBook:(NSArray *)number
                              success:(void(^)(NSArray *unrelatedUser))successBlock
                              failure:(void(^)(NSError *error))failureBlock;

+ (Follow *)getRelationWithFollower:(User *)follower
                          following:(User *)following;

+ (NSArray *)getNamesOfUsersWithId:(NSArray *)idsArray;


+ (NSDictionary *)getLastMessageDateDictionnary;

+ (void)saveLastMessageDate:(NSDate *)date ofUser:(NSString *)userId;

// --------------------------------------------
#pragma mark - ABContacts
// --------------------------------------------
+ (void)getAllABContactsLocallySuccess:(void(^)(NSArray *contacts))successBlock
                               failure:(void(^)(NSError *error))failureBlock;

// --------------------------------------------
#pragma mark - Video
// --------------------------------------------
+ (void)getVideoLocallyFromUsers:(NSArray *)users
                         success:(void(^)(NSArray *videos))successBlock
                         failure:(void(^)(NSError *error))failureBlock;

+ (void)getExpiredVideoFromLocalDataStoreAndExecute:(void(^)(NSArray *posts))block;

+ (void)deleteExpiredPosts;

+ (void)deleteLocalPostsNotInRemotePosts:(NSArray *)remotelyRetrievedPosts;

+ (void)unpinVideoAsUnsend:(VideoPost *)post;

+ (void)pinVideoAsUnsend:(VideoPost *)post;

+ (void)getUnsendVideosSuccess:(void(^)(NSArray *videos))successBlock
                       failure:(void(^)(NSError *error))failureBlock;

// --------------------------------------------
#pragma mark - Messages
// --------------------------------------------

+ (void)getUnreadMessagesLocallySuccess:(void(^)(NSArray *messages))successBlock
                                failure:(void(^)(NSError *error))failureBlock;


@end
