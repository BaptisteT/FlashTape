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

#import "ABContact.h"
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
#pragma mark - Api
// --------------------------------------------

// Check API version (retrieve potential message and redirection)
+ (void)checkAppVersionAndExecuteSucess:(void(^)(NSDictionary *))successBlock
{
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *build = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    
    [PFCloud callFunctionInBackground:@"checkAppVersion"
                       withParameters:@{ @"version" : version, @"build" : build }
                                block:^(id object, NSError *error) {
                                    if (error != nil) {
                                        NSLog(@"checkBuildVersion: We should not pass in this block!!!!");
                                    } else {
                                        if (successBlock) {
                                            successBlock((NSDictionary *)object);
                                        }
                                    }
                                }];
}

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

+ (void)saveAddressbookName:(NSString *)abName
{
    User *currentUser = [User currentUser];
    currentUser.addressbookName = abName;
    [currentUser saveInBackground];
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
    PFQuery *followerQuery = [PFQuery queryWithClassName:[Follow parseClassName]];
    [followerQuery whereKey:@"to" equalTo:[User currentUser]];
    [followerQuery whereKey:@"blocked" notEqualTo:[NSNumber numberWithBool:YES]];
    
    PFQuery *followingQuery = [PFQuery queryWithClassName:[Follow parseClassName]];
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
            [PFObject unpinAllObjectsInBackgroundWithName:kParseAddressbookFlashers block:^(BOOL succeeded, NSError *error) {
                [PFObject pinAllInBackground:objects withName:kParseAddressbookFlashers block:^(BOOL succeeded, NSError *error) {
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
            
            // Fill Contacts
            [ApiManager fillContactTableWithContacts:phoneNumbers aBFlasher:objects success:nil failure:nil];
        } else {
            if (failureBlock) {
                failureBlock(error);
            }
        }
    }];
}

// Fill contacts table
+ (void)fillContactTableWithContacts:(NSArray *)contacts
                           aBFlasher:(NSArray *)aBFlashers
                             success:(void(^)())successBlock
                             failure:(void(^)(NSError *error))failureBlock
{
    PFQuery *query = [PFQuery queryWithClassName:[ABContact parseClassName]];
    [query whereKey:@"number" containedIn:contacts];
    [query setLimit:1000];
    [query findObjectsInBackgroundWithBlock:^(NSArray *results, NSError *error) {
        if (!error) {
            NSMutableArray *contactObjectArray = [NSMutableArray new];
            if (contacts.count == results.count) {
                [contactObjectArray addObjectsFromArray:results];
            } else {
                for (NSString *contact in contacts) {
                    ABContact *contactObject = nil;
                    for (ABContact *resultContactObject in results) {
                        if ([resultContactObject.number isEqualToString:contact]) {
                            contactObject = resultContactObject;
                            break;
                        }
                    }
                    if (!contactObject) {
                        contactObject = [ABContact createRelationWithNumber:contact];
                    }
                    contactObject.isFlasher = [User contactNumber:contact belongsToUsers:aBFlashers];
                    [contactObject addUniqueObject:[User currentUser] forKey:@"users"];
                    [contactObjectArray addObject:contactObject];
                }
            }
            [PFObject saveAllInBackground:contactObjectArray block:^(BOOL completed, NSError *error) {
                if (completed) {
                    [PFObject unpinAllObjectsInBackgroundWithName:kParseABContacts block:^(BOOL succeeded, NSError *error) {
                        [PFObject pinAllInBackground:contactObjectArray withName:kParseABContacts block:^(BOOL succeeded, NSError *error) {
                            if (successBlock) {
                                successBlock(successBlock);
                            }
                        }];
                    }];
                } else if (failureBlock) {
                    failureBlock(error);
                }
            }];
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
            [TrackingUtils trackEvent:EVENT_FRIEND_ADD properties:nil];
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
            for (int i=0;i<followArray.count;i++) {
                [TrackingUtils trackEvent:EVENT_FRIEND_ADD properties:nil];
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
}

+ (void)deleteRelation:(Follow *)follow
               success:(void(^)())successBlock
               failure:(void(^)(NSError *error))failureBlock
{
    [follow deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            [follow unpinInBackgroundWithName:kParseRelationshipsName];
            [TrackingUtils trackEvent:EVENT_FRIEND_DELETE properties:nil];
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
              failure:(void(^)(NSError *error, BOOL addToFailArray))failureBlock
{
    NSURL *url = post.localUrl;
    if (!url || !post.user) {
        failureBlock(nil, NO);
        return;
    }
    // Upload data
    NSError *error;
    NSData *videoData = [NSData dataWithContentsOfURL:url options:0 error:&error];
    if (!videoData) {
        NSLog(@"%@",error);
        failureBlock(nil, NO);
        return;
    }
    PFFile *file = [PFFile fileWithName:@"video.mp4" data:videoData];
    [file saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            post.videoFile = file;
            [post saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (succeeded) {
                    // save the data to a permanent url
                    [post migrateDataFromTemporaryToPermanentURL];
                    
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
                        failureBlock(error, YES);
                    
                    // Track
                    [TrackingUtils trackEvent:EVENT_VIDEO_FAILED properties:nil];
                }
            }];
        } else {
            // Track
            [TrackingUtils trackEvent:EVENT_VIDEO_FAILED properties:nil];

            // Log details of the failure
            NSLog(@"Error: %@ %@", error, [error userInfo]);
            if (failureBlock)
                failureBlock(error, YES);
        }
    }];
}

// Get video
+ (void)getVideoFromFriends:(NSArray *)friends
                     success:(void(^)(NSArray *posts))successBlock
                     failure:(void(^)(NSError *error))failureBlock
{
    PFQuery *query = [PFQuery queryWithClassName:[VideoPost parseClassName]];
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
    // Remove Admin video
    NSMutableArray *videosArray = [NSMutableArray new];
    for (VideoPost *post in videoPosts) {
        if (![post.user.objectId isEqualToString:kAdminUserObjectId]) {
            [videosArray addObject:post];
        }
    }
    [VideoPost saveAllInBackground:videosArray];
}

// Delete Post
+ (void)deletePost:(VideoPost *)post
           success:(void(^)())successBlock
           failure:(void(^)(NSError *error))failureBlock
{
    [post deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            [TrackingUtils trackEvent:EVENT_VIDEO_DELETED properties:nil];
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
            [TrackingUtils trackEvent:EVENT_MESSAGE_FAILED properties:nil];
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
    PFQuery *innerQuery = [PFQuery queryWithClassName:[Follow parseClassName]];
    [innerQuery whereKey:@"to" equalTo:[User currentUser]];
    [innerQuery whereKey:@"blocked" equalTo:[NSNumber numberWithBool:YES]];
    
    PFQuery *query = [PFQuery queryWithClassName:[Message parseClassName]];
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
    // Save as read on parse
    [message saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        [TrackingUtils trackEvent:EVENT_MESSAGE_READ properties:nil];
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

+ (void)createAdminMessagesWithContent:(NSArray *)messageContents
                               success:(void(^)())successBlock
                          failureBlock:(void(^)(NSError *error))failureBlock
{
    User *sender = [User objectWithoutDataWithObjectId:kAdminUserObjectId];
    NSMutableArray *array = [NSMutableArray new];
    int i = 0;
    for (NSString *messageContent in messageContents) {
        Message *message = [Message createMessageWithContent:messageContent sender:sender];
        message.sentAt = [NSDate dateWithTimeInterval:i sinceDate:message.sentAt];
        [array addObject:message];
        [TrackingUtils trackEvent:EVENT_MESSAGE_SENT properties:@{@"type": @"tuto"}];
        i++;
    }
    [PFObject saveAllInBackground:array block:^(BOOL succeeded, NSError *error) {
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
    if (!currentInstallation.objectId || currentInstallation.badge != count) {
        currentInstallation.badge = count;
        [currentInstallation saveInBackground];
    }
}

// --------------------------------------------
#pragma mark - Invite
// --------------------------------------------

+ (void)sendInviteTo:(NSString *)phoneNumber
                name:(NSString *)name
             success:(void(^)())successBlock
             failure:(void(^)())failureBlock
{
    if (!phoneNumber || phoneNumber.length == 0) {
        return;
    }
    
    [PFCloud callFunctionInBackground:@"sendInvite"
                       withParameters:@{ @"phoneNumber" : phoneNumber, @"name" : name }
                                block:^(id object, NSError *error) {
                                    if (error != nil) {
                                        if (failureBlock)
                                            failureBlock();
                                    } else {
                                        [TrackingUtils trackEvent:EVENT_INVITE_SENT properties:@{@"type":@"twillio"}];
                                        if (successBlock) {
                                            successBlock([object integerValue]);
                                        }
                                    }
                                }];
}

+ (void)incrementInviteSeenCount:(ABContact *)contact
{

    [contact incrementKey:@"inviteSeenCount" byAmount:[NSNumber numberWithInt:1]];
    [contact saveInBackground];
}


// --------------------------------------------
#pragma mark - Report
// --------------------------------------------
+ (void)createReportWithUser:(User *)user
{
    PFObject *report = [PFObject objectWithClassName:@"Report"];
    report[@"reported"] = user;
    report[@"reporter"] = [User currentUser];
    [report saveInBackground];
}

@end
