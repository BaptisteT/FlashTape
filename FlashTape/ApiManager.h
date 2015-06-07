//
//  ApiManager.h
//  FlashTape
//
//  Created by Baptiste Truchot on 4/26/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
// With Parse, an API manager is not necessary. However I build this layer to be able to switch to our own backend in the future

#import <Foundation/Foundation.h>

@class VideoPost;
@class User;
@class Message;

@interface ApiManager : NSObject

// --------------------------------------------
#pragma mark - User
// --------------------------------------------

+ (void)requestSmsCode:(NSString *)phoneNumber
                 retry:(BOOL)retry
               success:(void(^)(NSInteger code))successBlock
               failure:(void(^)())failureBlock;

// Create user if it does not exists, and log him in
+ (void)logInUser:(NSString *)phoneNumber
          success:(void(^)())successBlock
          failure:(void(^)())failureBlock;

+ (void)saveUsername:(NSString *)username
             success:(void(^)())successBlock
             failure:(void(^)(NSError *error))failureBlock;

// --------------------------------------------
#pragma mark - Follow
// --------------------------------------------

+ (void)findUserByUsername:(NSString *)flashUserName
                   success:(void(^)(User *user))successBlock
                   failure:(void(^)(NSError *error))failureBlock;

//+ (void)getFollowingAndExecuteSuccess:(void(^)(NSArray *friends))successBlock
//                              failure:(void(^)(NSError *error))failureBlock;

+ (void)fillFollowersTableWithUsers:(NSArray *)contacts
                            success:(void(^)(NSArray *friends))successBlock
                            failure:(void(^)(NSError *error))failureBlock;

+ (void)createRelationWithFollowing:(User *)followedUser
                            success:(void(^)())successBlock
                            failure:(void(^)(NSError *error))failureBlock;

+ (void)deleteRelationWithFollowing:(User *)followedUser
                            success:(void(^)())successBlock
                            failure:(void(^)(NSError *error))failureBlock;

// --------------------------------------------
#pragma mark - Video
// --------------------------------------------

+ (void)saveVideoPost:(VideoPost *)post
    andExecuteSuccess:(void(^)())successBlock
              failure:(void(^)(NSError *error))failureBlock;

+ (void)getVideoFromFriends:(NSArray *)friends
                     success:(void(^)(NSArray *posts))successBlock
                     failure:(void(^)(NSError *error))failureBlock;

+ (void)updateVideoPosts:(NSArray *)videoPosts;

+ (void)deletePost:(VideoPost *)post
           success:(void(^)())successBlock
           failure:(void(^)(NSError *error))failureBlock;

+ (void)sendMessage:(Message *)message
            success:(void(^)())successBlock
            failure:(void(^)(NSError *error))failureBlock;


// --------------------------------------------
#pragma mark - Message
// --------------------------------------------

+ (void)retrieveUnreadMessagesAndExecuteSuccess:(void(^)(NSArray *messagesArray))successBlock
                                        failure:(void(^)(NSError *error))failureBlock;

+ (void)markMessageAsRead:(Message *)message
                  success:(void(^)())successBlock
                  failure:(void(^)(NSError *error))failureBlock;

@end
