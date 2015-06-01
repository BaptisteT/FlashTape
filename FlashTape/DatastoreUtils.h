//
//  DatastoreUtils.h
//  FlashTape
//
//  Created by Baptiste Truchot on 5/26/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
#import <Foundation/Foundation.h>

@interface DatastoreUtils : NSObject

+ (void)getFriendsFromLocalDatastoreAndExecuteSuccess:(void(^)(NSArray *friends))successBlock
                                              failure:(void(^)(NSError *error))failureBlock;

+ (NSArray *)getVideoLocallyFromUser:(User *)user;

+ (void)getExpiredVideoFromLocalDataStoreAndExecute:(void(^)(NSArray *posts))block;

+ (void)deleteExpiredPosts;

+ (void)deleteLocalPostsNotInRemotePosts:(NSArray *)remotelyRetrievedPosts;

@end
