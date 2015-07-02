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
#import "ImageUtils.h"

@interface FriendTableViewCell()

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *scoreLabel;
@property (weak, nonatomic) IBOutlet UILabel *seemView;
@property (weak, nonatomic) IBOutlet UILabel *storyVideosCountLabel;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;
@property (nonatomic, strong) CAShapeLayer *savingCircleShape;
@property (weak, nonatomic) IBOutlet UILabel *messageCountLabel;

@property (weak, nonatomic) IBOutlet UILabel *messageSentLabel;
@property (strong, nonatomic) IBOutlet UIImageView *accessoryImage;

@end


@implementation FriendTableViewCell


// -------------------
// Life Cycle
// ------------------
- (void)InitWithCurrentUser:(NSInteger)currentUserPostsCount isSaving:(BOOL)isSaving
{
    [self initWithUser:[User currentUser]
         hasSeenVideos:NO
   unreadMessagesCount:0
     messagesSentArray:nil
                 muted:NO];
    
    // Save
    self.saveButton.enabled = YES;
    if (currentUserPostsCount != 0) {
        self.saveButton.hidden = NO;
        self.storyVideosCountLabel.hidden = NO;
        self.storyVideosCountLabel.text = [NSString stringWithFormat:@"%lu",(long)currentUserPostsCount];
        self.storyVideosCountLabel.backgroundColor = [ColorUtils pink];
        self.storyVideosCountLabel.clipsToBounds=YES;
        self.storyVideosCountLabel.layer.cornerRadius = self.storyVideosCountLabel.frame.size.height / 2;
    }
    
    if (self.savingCircleShape) {
        [self.savingCircleShape removeAllAnimations];
        [self.savingCircleShape removeFromSuperlayer];
        if (isSaving) {
            [self startSavingAnimation];
        }
    }
}

- (void)initWithUser:(User *)user
       hasSeenVideos:(BOOL)hasSeenVideos
 unreadMessagesCount:(NSInteger)count
   messagesSentArray:(NSMutableArray *)messagesSent
               muted:(BOOL)muted
{
    self.nameLabel.text = user.flashUsername;
    self.scoreLabel.text = [NSString stringWithFormat:@"%lu",(long)(user.score ? user.score : 0)];
    self.nameLabel.translatesAutoresizingMaskIntoConstraints = YES;
    self.scoreLabel.translatesAutoresizingMaskIntoConstraints = YES;
    
    BOOL isCurrentUser = [User currentUser] == user;
    
    self.seemView.hidden = !hasSeenVideos || isCurrentUser;
    if (muted) {
        self.backgroundColor = [UIColor lightGrayColor];
    } else {
        self.backgroundColor = [UIColor clearColor];
    }
    self.accessoryImage.hidden = !isCurrentUser;
    
    // Save
    self.saveButton.hidden = YES;
    self.storyVideosCountLabel.hidden = YES;
    
    // Unread Messages label
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

- (void)layoutSubviews {
    [super layoutSubviews];
    if (!self.savingCircleShape) {
        [self initLoadingCircleShape];
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
    [self.delegate saveCurrentUserStoryButtonClicked];
}


// -------------------
// Saving Anim
// ------------------

- (void)startSavingAnimation
{
    self.saveButton.enabled = NO;
    
    // Add to parent layer
    [self.saveButton.layer addSublayer:self.savingCircleShape];
    CABasicAnimation *rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.fromValue = [NSNumber numberWithFloat:0.0f];
    rotationAnimation.toValue = [NSNumber numberWithFloat:2*M_PI];
    rotationAnimation.duration = 0.7;
    rotationAnimation.repeatCount = INFINITY;
    [self.savingCircleShape addAnimation:rotationAnimation forKey:@"indeterminateAnimation"];
}

- (void)initLoadingCircleShape
{
    self.savingCircleShape = [ImageUtils createGradientCircleLayerWithFrame:CGRectMake(0,0,self.saveButton.frame.size.width,self.saveButton.frame.size.height) borderWidth:1 Color:[UIColor whiteColor] subDivisions:100];
}

- (void)savedAnimation {
    self.saveButton.hidden = YES;
    self.storyVideosCountLabel.hidden = YES;
    self.messageSentLabel.alpha = 0;
    self.messageSentLabel.text = NSLocalizedString(@"story_saved", nil);
    [UIView animateWithDuration:1 animations:^{
        self.messageSentLabel.alpha = 1;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:1 delay:0.5 options:UIViewAnimationOptionCurveLinear animations:^{
            self.messageSentLabel.alpha = 0;
        } completion:nil];
    }];
}

@end
