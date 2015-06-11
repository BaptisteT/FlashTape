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
@property (weak, nonatomic) IBOutlet UILabel *seemView;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;
@property (weak, nonatomic) IBOutlet UILabel *messageCountLabel;
@property (strong, nonatomic) IBOutlet UIImageView *accessoryImage;

@end


@implementation FriendTableViewCell

- (void)initWithName:(NSString *)name
               score:(NSString *)score
       hasSeenVideos:(BOOL)hasSeenVideos
       isCurrentUser:(BOOL)isCurrentUser
    newMessagesCount:(NSInteger)count
{
    self.nameLabel.translatesAutoresizingMaskIntoConstraints = YES;
    self.scoreLabel.translatesAutoresizingMaskIntoConstraints = YES;
    self.nameLabel.text = name;
    self.scoreLabel.text = score;
    self.seemView.hidden = !hasSeenVideos || isCurrentUser;
    self.backgroundColor = [UIColor clearColor];
    self.accessoryImage.hidden = !isCurrentUser;
    
    // Save
    self.saveButton.enabled = YES;
    self.saveButton.hidden = !isCurrentUser;
    
    // Message label
    if (count != 0) {
        self.messageCountLabel.hidden = NO;
        self.messageCountLabel.text = [NSString stringWithFormat:@"%lu",(long)count];
        CGRect frame = self.nameLabel.frame;
        frame.origin.x = 60;
        self.nameLabel.frame = frame;
        frame = self.scoreLabel.frame;
        frame.origin.x = 60;
        self.scoreLabel.frame = frame;
    } else {
        CGRect frame = self.nameLabel.frame;
        frame.origin.x = 20;
        self.nameLabel.frame = frame;
        frame = self.scoreLabel.frame;
        frame.origin.x = 20;
        self.scoreLabel.frame = frame;
        self.messageCountLabel.hidden = YES;
    }
}

- (IBAction)saveButtonClicked:(id)sender {
    self.saveButton.enabled = NO;
    [self.delegate saveCurrentUserStoryButtonClicked];
}

@end
