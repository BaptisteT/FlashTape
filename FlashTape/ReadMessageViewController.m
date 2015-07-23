//
//  ReadMessageViewController.m
//  FlashTape
//
//  Created by Baptiste Truchot on 6/7/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
#import <CoreText/CoreText.h>
#import "ApiManager.h"
#import "Message.h"
#import "User.h"

#import "ReadMessageViewController.h"
#import "SendMessageViewController.h"

#import "ConstantUtils.h"

@interface ReadMessageViewController ()
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UIButton *replyButton;
@property (weak, nonatomic) IBOutlet UILabel *titleSubLabel;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;

@property (strong, nonatomic) UITapGestureRecognizer *tapGestureRecogniser;

@end

@implementation ReadMessageViewController

// --------------------------------------------
#pragma mark - Life Cycle
// --------------------------------------------

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Title
    NSString *username = self.messageSender.flashUsername ? self.messageSender.flashUsername : @"";
    NSString *title = [NSString stringWithFormat:NSLocalizedString(@"read_title", nil),username];
    NSRange usernameRange = [title rangeOfString:username];
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:title];
    [attributedText setAttributes:@{NSFontAttributeName: [UIFont fontWithName:@"NHaasGroteskDSPro-65Md" size:self.titleLabel.font.pointSize]}
                            range:NSMakeRange(0, title.length)];
    [attributedText addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:usernameRange];
    [attributedText addAttribute:NSForegroundColorAttributeName value:[UIColor lightGrayColor] range:NSMakeRange(0,usernameRange.location)];
    self.titleLabel.attributedText = attributedText;
    self.titleSubLabel.text = NSLocalizedString(@"read_subtitle", nil);
    
    // Reply
    [self.replyButton setTitle:NSLocalizedString(@"reply_button", nil) forState:UIControlStateNormal];
    [self.replyButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    
    self.messageLabel.numberOfLines = 0;
    self.messageLabel.adjustsFontSizeToFitWidth = YES;
    self.tapGestureRecogniser = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap)];
    [self.view addGestureRecognizer:self.tapGestureRecogniser];
    [self setFirstMessage];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    // Reply button underline
    CGRect frame = self.replyButton.titleLabel.frame;
    UIView *underline = [[UIView alloc] initWithFrame:CGRectMake(frame.origin.x,frame.origin.y + frame.size.height, frame.size.width, 4)];
    underline.backgroundColor = [UIColor blackColor];
    [self.replyButton addSubview:underline];
    
    // Message Label
    self.messageLabel.textAlignment = [self messageLabelLineCount] <= 1 ? NSTextAlignmentCenter : NSTextAlignmentLeft;
}

// --------------------------------------------
#pragma mark - Actions
// --------------------------------------------
- (void)handleTap {
    if (self.messagesArray.count == 0) {
        [self dismissViewControllerAnimated:NO completion:nil];
    } else {
        [self setFirstMessage];
    }
}

- (IBAction)backButtonClicked:(id)sender {
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (IBAction)replyButtonClicked:(id)sender {
    SendMessageViewController *controller = [self.delegate sendMessageController];
    controller.messageRecipient = self.messageSender;
    [self presentViewController:controller animated:NO completion:^{
        self.view.alpha = 0;
    }];
}

// --------------------------------------------
#pragma mark - Messages
// --------------------------------------------
- (void)setFirstMessage {
    if (self.messagesArray.count > 0) {
        // Message
        Message *message = self.messagesArray.firstObject;
        self.messageLabel.text = message.messageContent;
        NSInteger fontSize = belongsToEmojiArray(message.messageContent) ? kEmojiMaxFontSize : kMessageReceivedMaxFontSize;
        self.messageLabel.font = [UIFont fontWithName:@"NHaasGroteskDSPro-65Md" size:fontSize];
        
        // Date
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"HH:mm"];
        NSString *stringDate = [dateFormatter stringFromDate:message.createdAt];
        self.dateLabel.text = stringDate;
        
        // unpin / delete / unread
        [ApiManager markMessageAsRead:message
                              success:nil
                              failure:nil];
        [self.messagesArray removeObject:message];
        
        self.titleSubLabel.hidden = self.messagesArray.count == 0;
    } else {
        [self dismissViewControllerAnimated:NO completion:nil];
    }
}

- (NSUInteger)messageLabelLineCount
{
    CGSize size = [self.messageLabel sizeThatFits:CGSizeMake(self.messageLabel.frame.size.width, CGFLOAT_MAX)];
    return MAX((int)(size.height / self.messageLabel.font.lineHeight), 0);
}

@end
