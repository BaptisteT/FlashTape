//
//  ApiManager.m
//  FlashTape
//
//  Created by Baptiste Truchot on 4/26/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
// With Parse, an API manager is not necessary. However I build this layer to be able to switch to our own backend in the future
#import <Bolts/Bolts.h>
#import <Parse/parse.h>

#import "ApiManager.h"
#import "User.h"
#import "VideoPost.h"

#import "ConstantUtils.h"

@implementation ApiManager

// --------------------------------------------
#pragma mark - Sign up
// --------------------------------------------

+ (void)requestSmsCode:(NSString *)phoneNumber
                 retry:(BOOL)retry
               success:(void(^)(NSInteger code))successBlock
               failure:(void(^)())failureBlock
{
    [PFCloud callFunctionInBackground:@"sendVerificationCode"
                       withParameters:@{ @"phoneNumber" : phoneNumber }
                                block:^(id object, NSError *error) {
                                    if (error != nil) {
                                        if (failureBlock)
                                            failureBlock();
                                    } else {
                                        if (successBlock) {
                                            successBlock([object integerValue]);
                                        }
                                    }
                                }];
}

// Create user if it does not exists, and log him in
+ (void)logInUser:(NSString *)phoneNumber
          success:(void(^)())successBlock
          failure:(void(^)())failureBlock
{
    PFQuery *query = [User query];
    [query whereKey:@"username" equalTo:phoneNumber];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            if (objects.count == 0) {
                // create user
                User *user = [User createUserWithNumber:phoneNumber];
                [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    if (!error) {
                        if (successBlock)
                            successBlock();
                    } else {
                        if (failureBlock)
                            failureBlock();
                    }
                }];
            } else {
                // sign in
                [User logInWithUsernameInBackground:phoneNumber
                                             password:@""
                                                block:^(PFUser *user, NSError *error) {
                                                    if (user) {
                                                        if (successBlock)
                                                            successBlock();
                                                    } else { 
                                                        if (failureBlock)
                                                            failureBlock();
                                                    }
                                                }];
            }
        } else {
            if (failureBlock)
                failureBlock();
        }
    }];
}

+ (void)getListOfFriends:(NSArray *)contactsPhoneNumbers
                 success:(void(^)(NSArray *friends))successBlock
                 failure:(void(^)(NSError *error))failureBlock
{
    PFQuery *query = [User query];
    [query whereKey:@"username" containedIn:contactsPhoneNumbers];
    [query orderByDescending:@"score"];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            [[PFObject unpinAllObjectsInBackgroundWithName:@"Friends"] continueWithSuccessBlock:^id(BFTask *ignored) {
                // Cache the new results.
                return [PFObject pinAllInBackground:objects withName:@"Friends"];
            }];
            if (successBlock) {
                successBlock(objects);
            }
        } else {
            // Log details of the failure
            NSLog(@"Error: %@ %@", error, [error userInfo]);
            if (failureBlock)
                failureBlock(error);
        }
    }];
}

+ (void)getFriendsLocalDatastoreSuccess:(void(^)(NSArray *friends))successBlock
                                failure:(void(^)(NSError *error))failureBlock
{
    PFQuery *query = [User query];
    [query fromLocalDatastore];
    [query orderByDescending:@"score"];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            if (successBlock) {
                successBlock(objects);
            }
        } else {
            // Log details of the failure
            NSLog(@"Error in friends from local datastore: %@ %@", error, [error userInfo]);
            if (failureBlock)
                failureBlock(error);
        }
    }];
}

// --------------------------------------------
#pragma mark - Video
// --------------------------------------------

+ (void)saveVideoPost:(VideoPost *)post
    andExecuteSuccess:(void(^)())successBlock
              failure:(void(^)(NSError *error))failureBlock
{
    NSURL *url = post.localUrl;
    if (!url || !post.user) {
        failureBlock(nil);
        return;
    }
    // Upload data
    if (!post.videoData)
        post.videoData = [NSData dataWithContentsOfURL:url];
    PFFile *file = [PFFile fileWithName:@"video.mp4" data:post.videoData];
    [file saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            post.videoFile = file;
            [post saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (succeeded) {
                    // save the data to a permanent url and release it
                    post.localUrl = [post videoLocalURL];
                    if (![post.videoData writeToURL:post.localUrl options:NSAtomicWrite error:nil]) {
                        NSLog(@"Failure saving created post");
                    }
                    post.videoData = nil;
                    
                    // Increment user score
                    [post.user incrementKey:@"score"];
                    [post.user saveInBackground];
                    
                    // Success block
                    if (successBlock)
                        successBlock();
                } else {
                    // Log details of the failure
                    NSLog(@"Error: %@ %@", error, [error userInfo]);
                    if (failureBlock)
                        failureBlock(error);
                }
            }];
        } else {
            // Log details of the failure
            NSLog(@"Error: %@ %@", error, [error userInfo]);
            if (failureBlock)
                failureBlock(error);
        }
    }];
}

+ (void)getVideoFromContacts:(NSArray *)contactsPhoneNumbers
                     success:(void(^)(NSArray *posts))successBlock
                     failure:(void(^)(NSError *error))failureBlock
{
    PFQuery *userQuery = [User query];
    [userQuery whereKey:@"username" containedIn:contactsPhoneNumbers];
    
    PFQuery *query = [PFQuery queryWithClassName:@"VideoPost"];
    [query whereKey:@"createdAt" greaterThan:[[NSDate date] dateByAddingTimeInterval:-3600*kFeedHistoryInHours]];
    [query whereKey:@"user" matchesQuery:userQuery];
    [query orderByAscending:@"createdAt"];
    [query includeKey:@"user"];
    [query setLimit:1000];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            // Download video
            [VideoPost downloadVideoFromPosts:objects];
            
            // Return
            NSLog(@"Successfully retrieved %lu videos.", (unsigned long)objects.count);
            if (successBlock) {
                successBlock(objects);
            }
        } else {
            // Log details of the failure
            NSLog(@"Get Video Error: %@ %@", error, [error userInfo]);
            if (failureBlock)
                failureBlock(error);
        }
    }];
}


@end
