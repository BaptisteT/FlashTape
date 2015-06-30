//
//  FriendTableViewCell.h
//  FlashTape
//
//  Created by Baptiste Truchot on 5/26/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FriendTVCDelegate;
@class User;

@interface FriendTableViewCell : UITableViewCell

@property (weak, nonatomic) id<FriendTVCDelegate> delegate;

- (void)InitWithCurrentUser:(NSInteger)currentUserPostsCount isSaving:(BOOL)isSaving;

- (void)initWithUser:(User *)user
       hasSeenVideos:(BOOL)hasSeenVideos
 unreadMessagesCount:(NSInteger)count
   messagesSentArray:(NSMutableArray *)messagesSent
               muted:(BOOL)muted;

- (void)savedAnimation;

@end

@protocol FriendTVCDelegate

- (void)saveCurrentUserStoryButtonClicked;

@end