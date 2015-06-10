//
//  FriendTableViewCell.m
//  FlashTape
//
//  Created by Baptiste Truchot on 5/26/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
#import "Message.h"
#import "User.h"

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
@property (weak, nonatomic) IBOutlet UILabel *messageSentLabel;

@end


@implementation FriendTableViewCell

- (void)initWithUser:(User *)user
       hasSeenVideos:(BOOL)hasSeenVideos
 unreadMessagesCount:(NSInteger)count
   messagesSentArray:(NSMutableArray *)messagesSent
{
    self.nameLabel.text = user.flashUsername;
    self.scoreLabel.text = [NSString stringWithFormat:@"%lu",(long)(user.score ? user.score : 0)];
    BOOL isCurrentUser = [User currentUser] == user;
    self.seemView.hidden = !hasSeenVideos || isCurrentUser;
    self.backgroundColor = [UIColor clearColor];
    self.accessoryType = isCurrentUser ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
    
    // Save
    self.saveButton.enabled = YES;
    self.saveButton.hidden = !isCurrentUser;
    
    // Unread Messages label
    if (count != 0) {
        self.messageCountLabel.hidden = NO;
        self.messageCountLabel.text = [NSString stringWithFormat:@"%lu",(long)count];
    } else {
        self.messageCountLabel.hidden = YES;
    }
    
    // Sent messages
    NSInteger failCount = 0, sendingCount = 0, sentCount = 0;
    if (messagesSent) {
        for (Message *message in messagesSent) {
            failCount += (message.status == kMessageTypeFailed);
            sendingCount += (message.status == kMessageTypeSending);
            sentCount += (message.status == kMessageTypeSent);
        }
    }
    
    // Label
    self.messageSentLabel.text = @"";
    self.messageSentLabel.alpha = 1;
    if (failCount != 0) {
        self.backgroundColor = [UIColor redColor];
        self.messageSentLabel.text = [NSString stringWithFormat:(failCount > 1 ? NSLocalizedString(@"messages_failed", nil) : NSLocalizedString(@"message_failed", nil)),failCount];
    } else if (sendingCount != 0) {
        self.messageSentLabel.text = [NSString stringWithFormat:NSLocalizedString(@"messages_sending", nil),sendingCount];
    } else if (sentCount != 0) {
        [self sentAnimation];
        [messagesSent removeAllObjects];
    }
}

- (void)sentAnimation {
    self.messageSentLabel.alpha = 0;
    self.messageSentLabel.text = NSLocalizedString(@"messages_sent", nil);
    [UIView animateWithDuration:1 animations:^{
        self.messageSentLabel.alpha = 1;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:1 delay:0.5 options:UIViewAnimationOptionCurveLinear animations:^{
            self.messageSentLabel.alpha = 0;
        } completion:nil];
    }];
}

- (IBAction)saveButtonClicked:(id)sender {
    self.saveButton.enabled = NO;
    [self.delegate saveCurrentUserStoryButtonClicked];
}

@end
