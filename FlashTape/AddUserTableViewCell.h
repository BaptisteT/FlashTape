//
//  AddUserTableViewCell.h
//  FlashTape
//
//  Created by Baptiste Truchot on 6/7/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol AddUserTVCDelegate;
@class Follow;
@class User;

@interface AddUserTableViewCell : UITableViewCell

@property (weak, nonatomic) id<AddUserTVCDelegate> delegate;
@property (weak, nonatomic) IBOutlet UIView *separatorView;

- (void)setSearchedUsernameTo:(NSString *)username;
- (void)setCellUserTo:(User *)user;

@end

@protocol AddUserTVCDelegate <NSObject>

- (NSArray *)followingRelations;
- (void)addFollowingRelationAndReloadVideo:(Follow *)user;
- (void)removeFollowingRelationAndReloadVideo:(Follow *)user;

@end
