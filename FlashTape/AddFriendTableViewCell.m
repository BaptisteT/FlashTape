//
//  AddFriendTableViewCell.m
//  FlashTape
//
//  Created by Baptiste Truchot on 6/24/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//

#import "AddFriendTableViewCell.h"

@interface AddFriendTableViewCell()
@property (weak, nonatomic) IBOutlet UILabel *addFriendLabel;
@property (weak, nonatomic) IBOutlet UILabel *userCountLabel;

@end

@implementation AddFriendTableViewCell

- (void)setNewUserToAddTo:(NSInteger)count
{
    self.addFriendLabel.translatesAutoresizingMaskIntoConstraints = YES;
    // Unread Messages label
    if (count != 0) {
        self.userCountLabel.hidden = NO;
        self.userCountLabel.text = [NSString stringWithFormat:@"%lu",(long)count];
        CGRect frame = self.addFriendLabel.frame;
        frame.origin.x = 60;
        self.addFriendLabel.frame = frame;
    } else {
        CGRect frame = self.addFriendLabel.frame;
        frame.origin.x = 20;
        self.addFriendLabel.frame = frame;
        self.userCountLabel.hidden = YES;
    }
}

@end
