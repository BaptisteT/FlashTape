//
//  FriendTableViewCell.m
//  FlashTape
//
//  Created by Baptiste Truchot on 5/26/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
#import "FriendTableViewCell.h"

// Degrees to radians
#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)

@interface FriendTableViewCell()

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *scoreLabel;
@property (weak, nonatomic) IBOutlet UIImageView *seenImageView;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;

@end


@implementation FriendTableViewCell

- (void)initWithName:(NSString *)name
               score:(NSString *)score
       hasSeenVideos:(BOOL)hasSeenVideos
       isCurrentUser:(BOOL)isCurrentUser {
    
    self.nameLabel.text = isCurrentUser ? NSLocalizedString(@"current_user_TVC_name", nil) : name;
    self.scoreLabel.text = score;
    self.seenImageView.hidden = !hasSeenVideos || isCurrentUser;
    self.backgroundColor = [UIColor clearColor];
    
    self.saveButton.enabled = YES;
    self.saveButton.hidden = !isCurrentUser;
}

- (IBAction)saveButtonClicked:(id)sender {
    self.saveButton.enabled = NO;
    [self.delegate saveCurrentUserStoryButtonClicked];
}

@end
