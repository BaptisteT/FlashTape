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
#import "Message.h"
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

+ (void)getFollowingAndExecuteSuccess:(void(^)(NSArray *friends))successBlock
                              failure:(void(^)(NSError *error))failureBlock
{
    // set up the query on the Follow table
    PFQuery *query = [PFQuery queryWithClassName:@"Follow"];
    [query whereKey:@"from" equalTo:[PFUser currentUser]];
    [query includeKey:@"to"];
    // execute the query
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            NSLog(@"Successfully retrieved %lu friends.", (unsigned long)objects.count);
            NSMutableArray *friends = [NSMutableArray new];
            for(PFObject *object in objects) {
                [friends addObject:[object objectForKey:@"to"]];
            }
            [User unpinAllObjectsInBackgroundWithName:kParseFriendsName block:^void(BOOL success, NSError *error) {
                // Cache the new results.
                [User pinAllInBackground:friends withName:kParseFriendsName];
            }];
            if (successBlock) {
                successBlock(friends);
            }
        } else {
            // Log details of the failure
            NSLog(@"Error: %@ %@", error, [error userInfo]);
            if (failureBlock)
                failureBlock(error);
        }
    }];
}


// Fill followers table
+ (void)fillFollowersTableWithUsers:(NSMutableSet *)contacts
                            success:(void(^)(NSArray *friends))successBlock
                            failure:(void(^)(NSError *error))failureBlock
{
    [PFCloud callFunctionInBackground:@"fillFollowTable"
                       withParameters:@{@"contacts": [contacts allObjects]}
                                block:^(NSArray *followings, NSError *error) {
                                    if (!error) {
                                        NSMutableArray *friendArray = [NSMutableArray new];
                                        // Get user from follow
                                        for(PFObject *follow in followings) {
                                            User *otherUser = [follow objectForKey:@"to"];
                                            [friendArray addObject:otherUser];
                                        }
                                        // Sort by score
                                        [friendArray sortUsingComparator:^NSComparisonResult(User *obj1, User *obj2) {
                                            return obj1.score > obj2.score ? NSOrderedAscending : NSOrderedDescending;
                                        }];
                                        
                                        // Pin
                                        [User unpinAllObjectsInBackgroundWithName:kParseFriendsName block:^void(BOOL success, NSError *error) {
                                            // Cache the new results.
                                            [User pinAllInBackground:friendArray withName:kParseFriendsName];
                                        }];
                                        if (successBlock) {
                                            successBlock(friendArray);
                                        }
                                    } else {
                                        if (failureBlock) {
                                            failureBlock(error);
                                        }
                                    }
                                }];
}

+ (void)saveUsername:(NSString *)username
             success:(void(^)())successBlock
             failure:(void(^)(NSError *error))failureBlock
{
    // todo BT uniqueness
    User *user = [User currentUser];
    user.flashUsername = username;
    [user saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
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
                    [post pinInBackgroundWithName:kParsePostsName];
                    
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
+ (void)getVideoFromFriends:(NSArray *)friends
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
            [VideoPost pinAllInBackground:objects withName:kParsePostsName];
            
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

// --------------------------------------------
#pragma mark - Message
// --------------------------------------------

// Send
+ (void)sendMessage:(Message *)message
            success:(void(^)())successBlock
            failure:(void(^)(NSError *error))failureBlock
{
    [message saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
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

// Retrieve unread messages
+ (void)retrieveUnreadMessagesAndExecuteSuccess:(void(^)(NSArray *messagesArray))successBlock
                                        failure:(void(^)(NSError *error))failureBlock
{
    PFQuery *query = [PFQuery queryWithClassName:@"Message"];
    [query whereKey:@"receiver" equalTo:[User currentUser]];
    [query whereKey:@"read" equalTo:[NSNumber numberWithBool:false]];
    [query orderByAscending:@"createdAt"];
    [query includeKey:@"sender"];
    [query setLimit:1000];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            // Pin
            [Message unpinAllObjectsInBackgroundWithName:kParseMessagesName block:^void(BOOL success, NSError *error) {
                // Cache the new results.
                [Message pinAllInBackground:objects withName:kParseMessagesName];
            }];

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

// Mark as read
+ (void)markMessageAsRead:(Message *)message
                  success:(void(^)())successBlock
                  failure:(void(^)(NSError *error))failureBlock
{
    message.read = [NSNumber numberWithBool:YES];
    // Unpin
    [message unpinInBackgroundWithName:kParseMessagesName];
    // Save as read on parse
    [message saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
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
