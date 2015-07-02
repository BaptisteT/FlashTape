//
//  AddUserTableViewCell.m
//  FlashTape
//
//  Created by Baptiste Truchot on 6/7/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
#import "ApiManager.h"
#import "Follow.h"
#import "User.h"

#import "AddUserTableViewCell.h"

#import "ConstantUtils.h"
#import "GeneralUtils.h"
#import "MBProgressHUD.h"
#import "ColorUtils.h"

@interface AddUserTableViewCell()

@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet UIButton *addOrDeleteFriendButton;
@property (strong, nonatomic) User *user;
@property (strong, nonatomic) IBOutlet UIButton *separatorView;

@end


@implementation AddUserTableViewCell

- (void)setSearchedUsernameTo:(NSString *)username
{
    self.user = nil;
    self.usernameLabel.text = username;
    
    if (username.length >= kUsernameMinLength) {
        [self setAddOrDeleteButtonState:0];
        
        NSString *transformedUsername = [GeneralUtils transformedUsernameFromOriginal:username];
        [ApiManager findUserByUsername:transformedUsername
                               success:^(User *user) {
                                   if ([transformedUsername isEqualToString:user.transformedUsername]) { // avoid asynchro issue
                                       if (!user) {
                                           self.addOrDeleteFriendButton.hidden = YES;
                                       } else {
                                           [self setCellUserTo:user];
                                       }
                                   }
                               }
                               failure:nil];
    } else {
        self.addOrDeleteFriendButton.hidden = YES;
    }
}

- (void)setCellUserTo:(User *)user {
    self.user = user;
    self.usernameLabel.text = user.flashUsername;
    if (user == [User currentUser]) {
        self.addOrDeleteFriendButton.hidden = YES;
    } else if ([self followingRelationWithUser:user]) {
        [self setAddOrDeleteButtonState:2];
    } else {
        [self setAddOrDeleteButtonState:1];
    }
}

- (IBAction)addOrDeleteButtonClicked:(id)sender {
    if (!self.user || self.user == [User currentUser]) {
        return;
    }
    [self setAddOrDeleteButtonState:0];
    
    Follow *follow = [self followingRelationWithUser:self.user];
    
    [MBProgressHUD showHUDAddedTo:self.superview animated:YES];
    if (follow) {
        // delete
        [ApiManager deleteRelation:follow
                           success:^{
                               [MBProgressHUD hideHUDForView:self.superview animated:YES];
                               [self.delegate removeFollowingRelationAndReloadVideo:follow];
                               [self setAddOrDeleteButtonState:1];
                           } failure:^(NSError *error) {
                               [MBProgressHUD hideHUDForView:self.superview animated:YES];
                               [self setAddOrDeleteButtonState:2];
                           }];
    } else {
        [ApiManager createRelationWithFollowing:self.user
                                        success:^(Follow *following) {
                                            [MBProgressHUD hideHUDForView:self.superview animated:YES];
                                            [self.delegate addFollowingRelationAndReloadVideo:following];
                                            [self setAddOrDeleteButtonState:2];
                                        } failure:^(NSError *error) {
                                            [MBProgressHUD hideHUDForView:self.superview animated:YES];
                                            [self setAddOrDeleteButtonState:1];
                                        }];
    }
}

- (void)setAddOrDeleteButtonState:(NSInteger)state
{
    self.addOrDeleteFriendButton.hidden = NO;
    if (state == 0) {
        self.addOrDeleteFriendButton.enabled = NO;
        [self.addOrDeleteFriendButton setTitle:@"..." forState:UIControlStateNormal];
    } else {
        self.addOrDeleteFriendButton.enabled = YES;
        if (state == 1) {
            [self.addOrDeleteFriendButton setTitle:NSLocalizedString(@"add_button",nil) forState:UIControlStateNormal];
            [self.addOrDeleteFriendButton setBackgroundColor:[ColorUtils blue]];

        } else {
            [self.addOrDeleteFriendButton setTitle:NSLocalizedString(@"delete_button",nil) forState:UIControlStateNormal];
            [self.addOrDeleteFriendButton setBackgroundColor:[ColorUtils pink]];
        }
    }
}

- (Follow *)followingRelationWithUser:(User *)user {
    for (Follow *follow in [self.delegate followingRelations]) {
        if ([follow.to.objectId isEqualToString:user.objectId]) {
            return follow;
        }
    }
    return nil;
}
@end
