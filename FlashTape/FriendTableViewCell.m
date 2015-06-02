//
//  FriendTableViewCell.m
//  FlashTape
//
//  Created by Baptiste Truchot on 5/26/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
#import "FriendTableViewCell.h"

#import "ColorUtils.h"

// Degrees to radians
#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)

@interface FriendTableViewCell()

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *scoreLabel;
@property (weak, nonatomic) IBOutlet UIImageView *seenImageView;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;
@property (weak, nonatomic) IBOutlet UILabel *messageCountLabel;

@end


@implementation FriendTableViewCell

- (void)initWithName:(NSString *)name
               score:(NSString *)score
       hasSeenVideos:(BOOL)hasSeenVideos
       isCurrentUser:(BOOL)isCurrentUser
    newMessagesCount:(NSInteger)count
{
    self.nameLabel.text = isCurrentUser ? NSLocalizedString(@"current_user_TVC_name", nil) : name;
    self.scoreLabel.text = score;
    self.seenImageView.hidden = !hasSeenVideos || isCurrentUser;
    self.backgroundColor = [UIColor clearColor];
    self.accessoryType = isCurrentUser ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
    
    // Save
    self.saveButton.enabled = YES;
    self.saveButton.hidden = !isCurrentUser;
    
    // Message label
    if (count != 0) {
        self.messageCountLabel.hidden = NO;
        self.messageCountLabel.text = [NSString stringWithFormat:@"%lu",(long)count];
        self.messageCountLabel.layer.cornerRadius = self.messageCountLabel.frame.size.height / 2;
        self.messageCountLabel.layer.borderWidth = 1;
        self.messageCountLabel.layer.borderColor = [ColorUtils orange].CGColor;
        self.messageCountLabel.textColor = [ColorUtils orange];
    } else {
        self.messageCountLabel.hidden = YES;
    }
}

- (IBAction)saveButtonClicked:(id)sender {
    self.saveButton.enabled = NO;
    [self.delegate saveCurrentUserStoryButtonClicked];
}

@end
