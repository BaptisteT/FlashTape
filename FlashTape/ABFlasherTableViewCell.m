//
//  ABFlasherTableViewCell.m
//  FlashTape
//
//  Created by Baptiste Truchot on 6/28/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
#import "User.h"

#import "ABFlasherTableViewCell.h"

@interface ABFlasherTableViewCell()

@property (strong, nonatomic) User *flasher;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIButton *addFriendButton;

@end

@implementation ABFlasherTableViewCell {
    BOOL _addFriend;
}

- (void)initWithUser:(User *)flasher name:(NSString *)name state:(BOOL)toAdd
{
    self.flasher = flasher;
    self.nameLabel.text = name;
    [self setAddFriendState:toAdd];
}

- (IBAction)addFriendButtonClicked:(id)sender {
    BOOL addFriendState = !_addFriend;
    [self setAddFriendState:addFriendState];
    if (addFriendState) {
        [self.delegate addUserToFlasherToAdd:self.flasher];
    } else {
        [self.delegate removeUserFromFlasherToAdd:self.flasher];
    }
}

- (void)setAddFriendState:(BOOL)toAdd
{
    _addFriend = toAdd;
    UIImage *image = _addFriend ? [UIImage imageNamed:@"check_icon"] : nil;
    [self.addFriendButton setImage:image forState:UIControlStateNormal];
}

@end
