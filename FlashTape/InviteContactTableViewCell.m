//
//  InviteContactTableViewCell.m
//  FlashTape
//
//  Created by Baptiste Truchot on 6/23/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//

#import "InviteContactTableViewCell.h"

@interface InviteContactTableViewCell()
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIButton *inviteButton;
@property (strong,nonatomic) NSString *number;
@property (weak, nonatomic) IBOutlet UILabel *friendCountLabel;
@end

@implementation InviteContactTableViewCell

- (void)initWithName:(NSString *)name
              number:(NSString *)number
         friendCount:(NSInteger)friendCount
{
    self.nameLabel.text = name ? name : @"?";
    self.number = number;
    self.friendCountLabel.hidden = friendCount <= 1;
    self.friendCountLabel.text = [NSString stringWithFormat:@"(%lu friends)",friendCount];
}

- (IBAction)inviteButtonClicked:(id)sender {
    [self.delegate inviteUser:self.nameLabel.text number:self.number];
}

@end
