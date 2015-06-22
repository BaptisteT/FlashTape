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
#import "GeneralUtils.h"
#import "TrackingUtils.h"

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

+ (void)saveUsername:(NSString *)username
             success:(void(^)())successBlock
             failure:(void(^)(NSError *error))failureBlock
{
    NSString *transformedUsername = [GeneralUtils transformedUsernameFromOriginal:username];
    
    [ApiManager findUserByUsername:transformedUsername
                           success:^(User *user) {
                               if (user) { // username already taken
                                   if (failureBlock) {
                                       failureBlock(nil);
                                   }
                               } else {
                                   User *user = [User currentUser];
                                   user.flashUsername = username;
                                   user.transformedUsername = transformedUsername;
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
                           } failure:^(NSError *error) {
                               if (failureBlock) {
                                   failureBlock(error);
                               }
                           }];
}


// --------------------------------------------
#pragma mark - Follow
// --------------------------------------------

+ (void)findUserByUsername:(NSString *)flashUserName
                   success:(void(^)(User *user))successBlock
                   failure:(void(^)(NSError *error))failureBlock
{
    PFQuery *query = [User query];
    [query whereKey:@"transformedUsername" equalTo:flashUserName];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            if (successBlock) {
                successBlock(objects.count > 0 ? [objects firstObject] : nil);
            }
        } else {
            if (failureBlock) {
                failureBlock(error);
            }
        }
    }];
}

+ (void)getFollowersAndExecuteSuccess:(void(^)(NSArray *friends))successBlock
                              failure:(void(^)(NSError *error))failureBlock
{
    // set up the query on the Follow table
    PFQuery *query = [PFQuery queryWithClassName:@"Follow"];
    [query whereKey:@"to" equalTo:[PFUser currentUser]];
    [query whereKey:@"removed" notEqualTo:[NSNumber numberWithBool:YES]];
    [query includeKey:@"from"];
    // execute the query
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            NSMutableArray *friends = [NSMutableArray new];
            for(PFObject *object in objects) {
                if ([object objectForKey:@"from"])
                    [friends addObject:[object objectForKey:@"from"]];
            }
            [User unpinAllObjectsInBackgroundWithName:kParseFollowersName block:^void(BOOL success, NSError *error) {
                // Cache the new results.
                [User pinAllInBackground:friends withName:kParseFollowersName];
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

+ (void)getFollowingAndExecuteSuccess:(void(^)(NSArray *friends))successBlock
                              failure:(void(^)(NSError *error))failureBlock
{
    // set up the query on the Follow table
    PFQuery *query = [PFQuery queryWithClassName:@"Follow"];
    [query whereKey:@"from" equalTo:[PFUser currentUser]];
    [query whereKey:@"removed" equalTo:[NSNumber numberWithBool:NO]];
    [query includeKey:@"to"];
    // execute the query
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            NSLog(@"Successfully retrieved %lu following.", (unsigned long)objects.count);
            NSMutableArray *friends = [NSMutableArray new];
            for(PFObject *object in objects) {
                [friends addObject:[object objectForKey:@"to"]];
            }
            [User unpinAllObjectsInBackgroundWithName:kParseFollowingName block:^void(BOOL success, NSError *error) {
                // Cache the new results.
                [User pinAllInBackground:friends withName:kParseFollowingName];
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
+ (void)fillFollowTableWithContacts:(NSArray *)contacts
                            success:(void(^)(NSArray *friends))successBlock
                            failure:(void(^)(NSError *error))failureBlock
{
    [PFCloud callFunctionInBackground:@"fillFollowTable"
                       withParameters:@{@"contacts": contacts}
                                block:^(NSArray *followings, NSError *error) {
                                    if (!error) {
                                        NSMutableArray *friendArray = [NSMutableArray new];
                                        // Get user from follow
                                        for(PFObject *follow in followings) {
                                            User *otherUser = [follow objectForKey:@"to"];
                                            if (otherUser)
                                                [friendArray addObject:otherUser];
                                        }
                                        
                                        // Pin
                                        [User unpinAllObjectsInBackgroundWithName:kParseFollowingName block:^void(BOOL success, NSError *error) {
                                            // Cache the new results.
                                            [User pinAllInBackground:friendArray withName:kParseFollowingName];
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

+ (void)updateRelationWithFollowing:(User *)followedUser
                              block:(BOOL)block
                            success:(void(^)())successBlock
                            failure:(void(^)(NSError *error))failureBlock
{
    PFQuery *query = [PFQuery queryWithClassName:@"Follow"];
    [query whereKey:@"from" equalTo:[User currentUser]];
    [query whereKey:@"to" equalTo:followedUser];
    [query findObjectsInBackgroundWithBlock:^(NSArray *follows, NSError *error) {
        if (!error) {
            PFObject * follow;
            if (follows.count > 0) {
                follow = follows.firstObject;
            } else {
                follow = [PFObject objectWithClassName:@"Follow"];
                follow[@"to"] = followedUser;
                follow[@"from"] = [User currentUser];
            }
            follow[@"removed"] = [NSNumber numberWithBool:block];
            [follow saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (succeeded) {
                    if (block) {
                        [followedUser unpinInBackgroundWithName:kParseFollowingName];
                        [PFObject unpinAllInBackground:[DatastoreUtils getMessagesLocallyFromUser:followedUser] withName:kParseMessagesName];
                        [TrackingUtils trackBlockFriend];
                    } else {
                        [followedUser pinInBackgroundWithName:kParseFollowingName];
                        [TrackingUtils trackAddFriend];
                    }
                    if (successBlock) {
                        successBlock();
                    }
                } else {
                    if (failureBlock) {
                        failureBlock(error);
                    }
                }
            }];
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
                    
                    // Track
                    [TrackingUtils trackVideoSendingFailure];
                }
            }];
        } else {
            // Track
            [TrackingUtils trackVideoSendingFailure];
            
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
            [TrackingUtils trackVideoDeleted];
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
            [TrackingUtils trackMessageSendingFailed];
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
    PFQuery *innerQuery = [PFQuery queryWithClassName:@"Follow"];
    [innerQuery whereKey:@"from" equalTo:[PFUser currentUser]];
    [innerQuery whereKey:@"removed" equalTo:[NSNumber numberWithBool:YES]];
    
    PFQuery *query = [PFQuery queryWithClassName:@"Message"];
    [query whereKey:@"receiver" equalTo:[User currentUser]];
    [query whereKey:@"read" equalTo:[NSNumber numberWithBool:false]];
    [query whereKey:@"sender" doesNotMatchKey:@"to" inQuery:innerQuery];
    [query orderByAscending:@"createdAt"];
    [query includeKey:@"sender"];
    [query setLimit:1000];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            // Pin
            [Message unpinAllObjectsWithName:kParseMessagesName];
            [Message pinAll:objects withName:kParseMessagesName];

            // Update last message date
            for (Message *message in objects) {
                [message.sender updateLastMessageDate:message.createdAt];
            }
            
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
        [TrackingUtils trackMessageRead];
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
#pragma mark - Installation
// --------------------------------------------

+ (void)updateBadge:(NSInteger)count {
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    currentInstallation.badge = count;
    [currentInstallation saveInBackground];
}


@end
