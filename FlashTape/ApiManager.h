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

@interface ApiManager : NSObject

+ (void)requestSmsCode:(NSString *)phoneNumber
                 retry:(BOOL)retry
               success:(void(^)(NSInteger code))successBlock
               failure:(void(^)())failureBlock;

// Create user if it does not exists, and log him in
+ (void)logInUser:(NSString *)phoneNumber
          success:(void(^)())successBlock
          failure:(void(^)())failureBlock;

+ (void)getListOfFriends:(NSArray *)contactsPhoneNumbers
                 success:(void(^)(NSArray *friends))successBlock
                 failure:(void(^)(NSError *error))failureBlock;

+ (void)getFriendsLocalDatastoreSuccess:(void(^)(NSArray *friends))successBlock
                                failure:(void(^)(NSError *error))failureBlock;

+ (void)saveVideoPost:(VideoPost *)post
    andExecuteSuccess:(void(^)())successBlock
              failure:(void(^)(NSError *error))failureBlock;

+ (void)getVideoFromContacts:(NSArray *)contactsPhoneNumbers
                     success:(void(^)(NSArray *posts))successBlock
                     failure:(void(^)(NSError *error))failureBlock;



@end
