//
//  InviteContactTableViewCell.m
//  FlashTape
//
//  Created by Baptiste Truchot on 6/23/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//

#import "ABContact.h"

#import "InviteContactTableViewCell.h"

@interface InviteContactTableViewCell()
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIButton *inviteButton;
@property (strong,nonatomic) ABContact *contact;
@property (weak, nonatomic) IBOutlet UILabel *friendCountLabel;
@end

@implementation InviteContactTableViewCell {
    BOOL _idented;
}

- (void)initWithName:(NSString *)name
             contact:(ABContact *)contact
            indexPath:(NSIndexPath *)indexPath
{
    _idented = NO;
    self.inviteButton.userInteractionEnabled = YES;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.nameLabel.text = name ? name : @"?";
    self.contact = contact;
    self.friendCountLabel.hidden = contact.users.count <= 1;
    self.friendCountLabel.text = [NSString stringWithFormat:(indexPath.row == 0) ? NSLocalizedString(@"friends_count_long_description", nil) :  NSLocalizedString(@"friends_count_short_description", nil),(unsigned long)contact.users.count];
}

- (IBAction)inviteButtonClicked:(id)sender {
    self.inviteButton.enabled = NO;
    [self.delegate inviteUser:self.contact];
}

@end
