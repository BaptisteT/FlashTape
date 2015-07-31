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
    BOOL _selected;
}

- (void)initWithName:(NSString *)name
             contact:(ABContact *)contact
           indexPath:(NSIndexPath *)indexPath
            selected:(BOOL)selected
{
    [self setInviteFriendState:selected];
    self.inviteButton.userInteractionEnabled = YES;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.nameLabel.text = name ? name : @"?";
    self.contact = contact;
    self.friendCountLabel.hidden = contact.users.count <= 1;
    self.friendCountLabel.text = [NSString stringWithFormat:(indexPath.row == 0) ? NSLocalizedString(@"friends_count_long_description", nil) :  NSLocalizedString(@"friends_count_short_description", nil),(unsigned long)contact.users.count];
}

- (IBAction)inviteButtonClicked:(id)sender {
    self.inviteButton.enabled = NO;
    [self setInviteFriendState:!_selected];
    if (_selected) {
        [self.delegate inviteContact:self.contact];
    } else {
        [self.delegate removeContact:self.contact];
    }
    self.inviteButton.enabled = YES;
}

- (void)setInviteFriendState:(BOOL)flag
{
    _selected = flag;
    UIImage *image = flag ? [UIImage imageNamed:@"check_icon"] : nil;
    [self.inviteButton setImage:image forState:UIControlStateNormal];
}

//- (void)setSelected:(BOOL)selected {
//    if (selected) {
//        [self inviteButtonClicked:nil];
//    }
//}


@end
