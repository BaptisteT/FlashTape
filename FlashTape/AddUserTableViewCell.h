//
//  AddUserTableViewCell.h
//  FlashTape
//
//  Created by Baptiste Truchot on 6/7/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol AddUserTVCDelegate;
@class User;

@interface AddUserTableViewCell : UITableViewCell

@property (weak, nonatomic) id<AddUserTVCDelegate> delegate;

- (void)setSearchedUsernameTo:(NSString *)username;

@end

@protocol AddUserTVCDelegate <NSObject>

- (NSArray *)friends;
- (void)addFriendAndReloadVideo:(User *)user;
- (void)removeFriendAndReloadVideo:(User *)user;

@end
