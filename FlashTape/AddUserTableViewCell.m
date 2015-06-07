//
//  AddUserTableViewCell.m
//  FlashTape
//
//  Created by Baptiste Truchot on 6/7/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
#import "ApiManager.h"
#import "User.h"

#import "AddUserTableViewCell.h"

#import "ConstantUtils.h"
#import "GeneralUtils.h"

@interface AddUserTableViewCell()

@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet UIButton *addOrDeleteFriendButton;
@property (strong, nonatomic) User *user;

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
                                   if (!user) {
                                       self.addOrDeleteFriendButton.hidden = YES;
                                   } else {
                                       if ([transformedUsername isEqualToString:user.transformedUsername]) { // ensure this is the same state
                                           self.user = user;
                                           if ([[self.delegate friends] containsObject:user]) {
                                               [self setAddOrDeleteButtonState:2];
                                           } else {
                                               [self setAddOrDeleteButtonState:1];
                                           }
                                       }
                                   }
                               }
                               failure:^(NSError *error) {
                                   // todo BT
                               }];
    } else {
        self.addOrDeleteFriendButton.hidden = YES;
    }
}

- (IBAction)addOrDeleteButtonClicked:(id)sender {
    if (!self.user) {
        return;
    }
    [self setAddOrDeleteButtonState:0];
    BOOL isFriend = [[self.delegate friends] containsObject:self.user];
    if (!isFriend) {
        [ApiManager createRelationWithFollowing:self.user
                                        success:^{
                                            [self.delegate addFriendAndReloadVideo:self.user];
                                            [self setAddOrDeleteButtonState:2];
                                        } failure:^(NSError *error) {
                                            [self setAddOrDeleteButtonState:1];
                                        }];
    } else {
        [ApiManager deleteRelationWithFollowing:self.user
                                        success:^{
                                            [self.delegate removeFriendAndReloadVideo:self.user];
                                            [self setAddOrDeleteButtonState:1];
                                        } failure:^(NSError *error) {
                                            [self setAddOrDeleteButtonState:2];
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
            [self.addOrDeleteFriendButton setTitle:@"Add" forState:UIControlStateNormal];
        } else {
            [self.addOrDeleteFriendButton setTitle:@"Remove" forState:UIControlStateNormal];
        }
    }
}

@end
