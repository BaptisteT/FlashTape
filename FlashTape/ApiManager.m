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
#import "DatastoreUtils.h"

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

+ (void)getListOfFriends:(NSDictionary *)contactsDictionnary
                 success:(void(^)(NSArray *friends))successBlock
                 failure:(void(^)(NSError *error))failureBlock
{
    NSMutableArray *contactsPhoneNumbers = [NSMutableArray arrayWithArray:[contactsDictionnary allKeys]];
    [contactsPhoneNumbers addObject:[User currentUser].username];
    PFQuery *query = [User query];
    [query whereKey:@"username" containedIn:contactsPhoneNumbers];
    [query orderByDescending:@"score"];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            NSLog(@"Successfully retrieved %lu friends.", (unsigned long)objects.count);
            [PFObject unpinAllObjectsInBackgroundWithName:kParseFriendName block:^void(BOOL success, NSError *error) {
                // Cache the new results.
                [PFObject pinAllInBackground:objects withName:kParseFriendName];
            }];
            if (successBlock) {
                successBlock(objects);
            }
            [ApiManager fillFollowersTableWithUsers:objects contactsDictionnary:contactsDictionnary];
        } else {
            // Log details of the failure
            NSLog(@"Error: %@ %@", error, [error userInfo]);
            if (failureBlock)
                failureBlock(error);
        }
    }];
}

// Fill followers table
+ (void)fillFollowersTableWithUsers:(NSArray *)objects contactsDictionnary:(NSDictionary *)contactsDictionnary {
    NSMutableArray *followingArray = [NSMutableArray new];
    for (User *friend in objects) {
        if (![friend.objectId isEqualToString:[PFUser currentUser].objectId]) {
            PFObject *follow = [PFObject objectWithClassName:@"Follow"];
            [follow setObject:[PFUser currentUser]  forKey:@"from"];
            [follow setObject:friend forKey:@"to"];
            [follow setObject:contactsDictionnary[friend.username] forKey:@"to_name"];
            [followingArray addObject:follow];
        }
    }
    [PFObject saveAllInBackground:followingArray];
}


// --------------------------------------------
#pragma mark - Video
// --------------------------------------------
// Save
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
                    
                    // Pin
                    [post pinInBackgroundWithName:kParsePostName];
                    
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

// Get video
+ (void)getVideoFromContacts:(NSArray *)friends
                     success:(void(^)(NSArray *posts))successBlock
                     failure:(void(^)(NSError *error))failureBlock
{
    PFQuery *query = [PFQuery queryWithClassName:@"VideoPost"];
    [query whereKey:@"createdAt" greaterThan:[[NSDate date] dateByAddingTimeInterval:-3600*kFeedHistoryInHours]];
    [query whereKey:@"user" containedIn:friends];
    [query orderByAscending:@"recordedAt"];
    [query includeKey:@"user"];
    [query setLimit:1000];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            // Download video
            [VideoPost downloadVideoFromPosts:objects];
            
            // Cache the new results.
            [VideoPost pinAllInBackground:objects withName:kParsePostName];
            
            // Return
            if (successBlock) {
                successBlock(objects);
            }
            NSLog(@"Successfully retrieved %lu videos.", (unsigned long)objects.count);
            
            // Clean local datastore
            [DatastoreUtils deleteLocalPostsNotInRemotePosts:objects];
        } else {
            // Log details of the failure
            NSLog(@"Get Video Error: %@ %@", error, [error userInfo]);
            if (failureBlock)
                failureBlock(error);
        }
    }];
}

// Update post (get latest list of viewers)
+ (void)updateVideoPosts:(NSArray *)videoPosts {
    [VideoPost saveAllInBackground:videoPosts];
}

// Delete Post
+ (void)deletePost:(VideoPost *)post
           success:(void(^)())successBlock
           failure:(void(^)(NSError *error))failureBlock
{
    [post deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            if (successBlock) {
                successBlock();
            }
        } else {
            if (failureBlock) {
                failureBlock(error);
            }
        }
    }];
}

@end
