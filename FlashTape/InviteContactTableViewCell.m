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
@end

@implementation InviteContactTableViewCell

- (void)initWithName:(NSString *)name
              number:(NSString *)number
{
    self.nameLabel.text = name;
    self.number = number;
}

- (IBAction)inviteButtonClicked:(id)sender {
    [self.delegate inviteButtonClicked:self.number];
}

@end
