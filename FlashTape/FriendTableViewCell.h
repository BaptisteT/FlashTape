//
//  FriendTableViewCell.h
//  FlashTape
//
//  Created by Baptiste Truchot on 5/26/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FriendTVCDelegate;

@interface FriendTableViewCell : UITableViewCell

@property (weak, nonatomic) id<FriendTVCDelegate> delegate;

- (void)initWithName:(NSString *)name
               score:(NSString *)score
       hasSeenVideos:(BOOL)hasSeenVideos
       isCurrentUser:(BOOL)isCurrentUser
    newMessagesCount:(NSInteger)count;

@end

@protocol FriendTVCDelegate

- (void)saveCurrentUserStoryButtonClicked;

@end