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
#import "Follow.h"
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

// Get All relationships (follower + following relations)
+ (void)getRelationshipsRemotelyAndExecuteSuccess:(void(^)())successBlock
                                          failure:(void(^)(NSError *error))failureBlock
{
    // set up the query on the Follow table
    PFQuery *followerQuery = [PFQuery queryWithClassName:@"Follow"];
    [followerQuery whereKey:@"to" equalTo:[User currentUser]];
    [followerQuery whereKey:@"blocked" notEqualTo:[NSNumber numberWithBool:YES]];
    
    PFQuery *followingQuery = [PFQuery queryWithClassName:@"Follow"];
    [followingQuery whereKey:@"from" equalTo:[User currentUser]];
    
    PFQuery *relationshipQuery = [PFQuery orQueryWithSubqueries:@[followerQuery,followingQuery]];
    [relationshipQuery setLimit:1000];
    [relationshipQuery includeKey:@"from"];
    [relationshipQuery includeKey:@"to"];
    
    // execute the query
    [relationshipQuery findObjectsInBackgroundWithBlock:^(NSArray *relations, NSError *error) {
        if (!error) {
            [Follow unpinAllObjectsInBackgroundWithName:kParseRelationshipsName block:^void(BOOL success, NSError *error) {
                // Cache the new results.
                [Follow pinAllInBackground:relations withName:kParseRelationshipsName block:^void(BOOL success, NSError *error) {
                    if (successBlock) {
                        successBlock();
                    }
                }];
            }];
            
            // Delete follow with no to or from
            for (Follow *follow in relations) {
                if (![follow.from isKindOfClass:[User class]] || ![follow.to isKindOfClass:[User class]]) {
                    [follow deleteInBackground];
                }
            }
            
            // Check if new unfollowed follower
            NSDate *previousDate = [GeneralUtils getLastUnfollowedFollowerRetrieveDate];
            int count = 0;
            for (Follow *follow in relations) {
                if (follow.to == [User currentUser] && follow.from != [User currentUser] && [follow.createdAt compare:previousDate] == NSOrderedDescending) {
                    count ++;
                }
            }
            [GeneralUtils setNewUnfollowedFollowerCount:count];
            [GeneralUtils setLastUnfollowedFollowerRetrieveDate:[NSDate date]];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reset_notif_count"
                                                                object:nil
                                                              userInfo:nil];
            // If friend controller, reload tableview
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reload_friend_tableview"
                                                                object:nil
                                                              userInfo:nil];
        } else {
            // Log details of the failure
            NSLog(@"Error: %@ %@", error, [error userInfo]);
            if (failureBlock)
                failureBlock(error);
        }
    }];
}

+ (void)findFlashUsersContainedInAddressBook:(NSArray *)phoneNumbers
                                     success:(void(^)(NSArray *userArray))successBlock
                                     failure:(void(^)(NSError *error))failureBlock
{
    PFQuery *query = [User query];
    [query whereKey:@"username" containedIn:phoneNumbers];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            // Pin and return
            [PFObject unpinAllObjectsInBackgroundWithName:kParseAddressbookContacts block:^(BOOL succeeded, NSError *error) {
                [PFObject pinAllInBackground:objects withName:kParseAddressbookContacts block:^(BOOL succeeded, NSError *error) {
                    if (successBlock) {
                        successBlock(objects);
                    }
                }];
            }];
            
            // Check if new user in our addressbok
            [DatastoreUtils getUnrelatedUserInAddressBook:phoneNumbers success:^(NSArray *unrelatedUser) {
                NSDate *previousDate = [GeneralUtils getLastAddressBookFlasherRetrieveDate];
                int count = 0;
                for (PFObject *object in unrelatedUser) {
                    if ([object.createdAt compare:previousDate] == NSOrderedDescending) {
                        count ++;
                    }
                }
                [GeneralUtils setNewNewAddressbookFlasherCount:count];
                [GeneralUtils setLastAddressBookFlasherRetrieveDate:[NSDate date]];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"reset_notif_count"
                                                                    object:nil
                                                                  userInfo:nil];
            } failure:nil];
        } else {
            if (failureBlock) {
                failureBlock(error);
            }
        }
    }];
}

+ (void)saveRelation:(Follow *)follow
             success:(void(^)())successBlock
             failure:(void(^)(NSError *error))failureBlock
{
    [follow saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
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

+ (void)createRelationWithFollowing:(User *)following
                            success:(void(^)(Follow *follow))successBlock
                            failure:(void(^)(NSError *error))failureBlock
{
    Follow *follow = [Follow createRelationWithFollowing:following];
    [follow saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            [follow pinInBackgroundWithName:kParseRelationshipsName];
            [TrackingUtils trackAddFriend];
            if (successBlock) {
                successBlock(follow);
            }
        } else {
            if (failureBlock) {
                failureBlock(error);
            }
        }
    }];
}

+ (void)createRelationWithFollowings:(NSArray *)followings
                             success:(void(^)())successBlock
                             failure:(void(^)(NSError *error))failureBlock
{
    if (!followings || followings.count == 0) {
        if (successBlock) successBlock();
        return;
    }
    
    NSMutableArray *followArray = [NSMutableArray new];
    for (User *user in followings) {
        [followArray addObject:[Follow createRelationWithFollowing:user]];
    }
    [PFObject saveAllInBackground:followArray block:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            [PFObject pinAllInBackground:followArray withName:kParseRelationshipsName];
            [TrackingUtils trackAddFriend];
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

+ (void)deleteRelation:(Follow *)follow
               success:(void(^)())successBlock
               failure:(void(^)(NSError *error))failureBlock
{
    [follow deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            [follow unpinInBackgroundWithName:kParseRelationshipsName];
            [TrackingUtils trackBlockFriend];
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
    [query whereKey:@"recordedAt" greaterThan:[[NSDate date] dateByAddingTimeInterval:-3600*kFeedHistoryInHours]];
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
    [innerQuery whereKey:@"to" equalTo:[User currentUser]];
    [innerQuery whereKey:@"blocked" equalTo:[NSNumber numberWithBool:YES]];
    
    PFQuery *query = [PFQuery queryWithClassName:@"Message"];
    [query whereKey:@"receiver" equalTo:[User currentUser]];
    [query whereKey:@"read" equalTo:[NSNumber numberWithBool:false]];
    [query whereKey:@"sender" doesNotMatchKey:@"from" inQuery:innerQuery];
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

// --------------------------------------------
#pragma mark - Invite
// --------------------------------------------

+ (void)sendInviteTo:(NSString *)phoneNumber
             success:(void(^)())successBlock
             failure:(void(^)())failureBlock
{
    [PFCloud callFunctionInBackground:@"sendInvite"
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


@end
