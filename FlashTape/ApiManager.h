//
//  ApiManager.h
//  FlashTape
//
//  Created by Baptiste Truchot on 4/26/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
// With Parse, an API manager is not necessary. However I build this layer to be able to switch to our own backend in the future

#import <Foundation/Foundation.h>

@class ABContact;
@class VideoPost;
@class User;
@class Message;
@class Follow;

@interface ApiManager : NSObject

+ (void)checkAppVersionAndExecuteSucess:(void(^)(NSDictionary *))successBlock;

// --------------------------------------------
#pragma mark - User
// --------------------------------------------

+ (void)requestSmsCode:(NSString *)phoneNumber
               success:(void(^)(NSInteger code))successBlock
               failure:(void(^)())failureBlock;

// Create user if it does not exists, and log him in
+ (void)logInUser:(NSString *)phoneNumber
          success:(void(^)())successBlock
          failure:(void(^)())failureBlock;

+ (void)saveUsername:(NSString *)username
             success:(void(^)())successBlock
             failure:(void(^)(NSError *error))failureBlock;

+ (void)saveAddressbookName:(NSString *)abName;

// --------------------------------------------
#pragma mark - Follow
// --------------------------------------------

+ (void)findUserByUsername:(NSString *)flashUserName
                   success:(void(^)(User *user))successBlock
                   failure:(void(^)(NSError *error))failureBlock;

+ (void)getRelationshipsRemotelyAndExecuteSuccess:(void(^)())successBlock
                                          failure:(void(^)(NSError *error))failureBlock;

+ (void)findFlashUsersContainedInAddressBook:(NSArray *)phoneNumbers
                                    success:(void(^)(NSArray *userArray))successBlock
                                    failure:(void(^)(NSError *error))failureBlock;

+ (void)fillContactTableWithContacts:(NSArray *)contacts
                           aBFlasher:(NSArray *)aBFlashers
                             success:(void(^)(NSArray *abContacts))successBlock
                             failure:(void(^)(NSError *error))failureBlock;

+ (void)saveRelation:(Follow *)follow
             success:(void(^)())successBlock
             failure:(void(^)(NSError *error))failureBlock;

+ (void)createRelationWithFollowing:(User *)following
                            success:(void(^)(Follow *follow))successBlock
                            failure:(void(^)(NSError *error))failureBlock;

+ (void)createRelationWithFollowings:(NSArray *)followings
                             success:(void(^)())successBlock
                             failure:(void(^)(NSError *error))failureBlock;

+ (void)deleteRelation:(Follow *)follow
               success:(void(^)())successBlock
               failure:(void(^)(NSError *error))failureBlock;

// --------------------------------------------
#pragma mark - Video
// --------------------------------------------

+ (void)saveVideoPost:(VideoPost *)post
    andExecuteSuccess:(void(^)())successBlock
              failure:(void(^)(NSError *error, BOOL addToFailArray))failureBlock;

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

// Used for admin messages after sign up
+ (void)createAdminMessagesWithContent:(NSArray *)messageContents
                                      success:(void(^)())successBlock
                                 failureBlock:(void(^)(NSError *error))failureBlock;

// --------------------------------------------
#pragma mark - Installation
// --------------------------------------------

+ (void)updateBadge:(NSInteger)count;

// --------------------------------------------
#pragma mark - Invite
// --------------------------------------------

+ (void)sendInviteTo:(NSString *)phoneNumber
                name:(NSString *)name
             success:(void(^)())successBlock
             failure:(void(^)())failureBlock;

+ (void)incrementInviteSeenCount:(ABContact *)contact;

// --------------------------------------------
#pragma mark - Report
// --------------------------------------------
+ (void)createReportWithUser:(User *)user;

@end
