//
//  DatastoreUtils.h
//  FlashTape
//
//  Created by Baptiste Truchot on 5/26/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
#import <Foundation/Foundation.h>
@class User;

@interface DatastoreUtils : NSObject

+ (void)getFollowingFromLocalDatastoreAndExecuteSuccess:(void(^)(NSArray *friends))successBlock
                                              failure:(void(^)(NSError *error))failureBlock;

+ (NSArray *)getNamesOfUsersWithId:(NSArray *)idsArray;

+ (NSArray *)getVideoLocallyFromUsers:(NSArray *)users;

+ (void)getExpiredVideoFromLocalDataStoreAndExecute:(void(^)(NSArray *posts))block;

+ (void)deleteExpiredPosts;

+ (void)deleteLocalPostsNotInRemotePosts:(NSArray *)remotelyRetrievedPosts;

+ (NSArray *)getUnreadMessagesLocally;

+ (NSArray *)getMessagesLocallyFromUser:(User *)user;

+ (NSDictionary *)getLastMessageDateDictionnary;

+ (void)saveLastMessageDate:(NSDate *)date ofUser:(NSString *)userId;

@end
