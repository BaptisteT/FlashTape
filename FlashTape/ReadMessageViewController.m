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

#define EMOJI_ARRAY @[@"❤️", @"😂", @"😔", @"😍", @"☺️", @"😎", @"😉", @"💋", @"😊", @"👍", @"😘", @"😡", @"😀", @"👌", @"😬", @"🙈", @"👅", @"🍻", @"😱", @"🙏", @"🐶", @"😜", @"💩", @"💪"]

@interface ReadMessageViewController ()
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UIButton *replyButton;
@property (weak, nonatomic) IBOutlet UILabel *titleSubLabel;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIButton *backButton;

@property (strong, nonatomic) UITapGestureRecognizer *tapGestureRecogniser;

@end

@implementation ReadMessageViewController

// --------------------------------------------
#pragma mark - Life Cycle
// --------------------------------------------

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Title
    NSString *title = [NSString stringWithFormat:NSLocalizedString(@"read_title", nil),self.messageSender.flashUsername];
    NSRange usernameRange = [title rangeOfString:self.messageSender.flashUsername];
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:title];
    [attributedText setAttributes:@{NSFontAttributeName: [UIFont fontWithName:@"NHaasGroteskDSPro-65Md" size:self.titleLabel.font.pointSize]}
                            range:NSMakeRange(0, title.length)];
    [attributedText addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:usernameRange];
    [attributedText addAttribute:NSForegroundColorAttributeName value:[UIColor lightGrayColor] range:NSMakeRange(0,usernameRange.location)];
    self.titleLabel.attributedText = attributedText;
    self.titleSubLabel.text = NSLocalizedString(@"read_subtitle", nil);
    if (self.messagesArray.count < 2) {
        self.titleSubLabel.hidden = YES;
    }
    
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
    
    CGRect frame = self.replyButton.titleLabel.frame;
    UIView *underline = [[UIView alloc] initWithFrame:CGRectMake(frame.origin.x,frame.origin.y + frame.size.height, frame.size.width, 4)];
    underline.backgroundColor = [UIColor blackColor];
    [self.replyButton addSubview:underline];
    
    [self adjustFontSizeToFit:self.messageLabel];
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
        Message *message = self.messagesArray.firstObject;
        self.messageLabel.text = message.messageContent;
        if([EMOJI_ARRAY containsObject:message.messageContent]) {
            NSLog(@"Emoji message");
            self.messageLabel.font = [UIFont fontWithName:@"NHaasGroteskDSPro-65Md" size:250];
            self.messageLabel.textAlignment = NSTextAlignmentCenter;
        } else {
            NSMutableAttributedString* attrString = [[NSMutableAttributedString alloc] initWithString:message.messageContent];
            
            // todo BT
            // clean
            NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
            CGFloat minMaxLineHeight = (self.messageLabel.font.pointSize - self.messageLabel.font.ascender + self.messageLabel.font.capHeight);
            NSNumber *offset = @(self.messageLabel.font.capHeight - self.messageLabel.font.ascender);
            NSRange range = NSMakeRange(0, message.messageContent.length);
            [style setMinimumLineHeight:minMaxLineHeight];
            [style setMaximumLineHeight:minMaxLineHeight + 8.0f];
            [attrString addAttribute:NSParagraphStyleAttributeName
                               value:style
                               range:range];
            [attrString addAttribute:NSBaselineOffsetAttributeName
                               value:offset
                               range:range];
            self.messageLabel.attributedText = attrString;
            if (message.messageContent.length <= 10) {
                self.messageLabel.textAlignment = NSTextAlignmentCenter;
            }
        }
        
        // unpin / delete / unread
        [ApiManager markMessageAsRead:message
                              success:nil
                              failure:nil];
        [self.messagesArray removeObject:message];
    } else {
        [self dismissViewControllerAnimated:NO completion:nil];
    }
}

- (void)adjustFontSizeToFit:(UILabel *)label
{
    UIFont *font = label.font;
    CGSize size = label.frame.size;
    
    for (CGFloat maxSize = label.font.pointSize; maxSize >= 1; maxSize -= 1.f)
    {
        font = [font fontWithSize:maxSize];
        CGSize constraintSize = CGSizeMake(size.width, size.height);
        
        // todo BT clean
        NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
        CGFloat minMaxLineHeight = (self.messageLabel.font.pointSize - self.messageLabel.font.ascender + self.messageLabel.font.capHeight);
        NSNumber *offset = @(self.messageLabel.font.capHeight - self.messageLabel.font.ascender);
        [style setMinimumLineHeight:minMaxLineHeight];
        [style setMaximumLineHeight:minMaxLineHeight + 8.0f];
        
        CGRect textRect = [label.text boundingRectWithSize:constraintSize
                                                  options:NSStringDrawingUsesLineFragmentOrigin
                                                attributes:@{NSFontAttributeName:font, NSParagraphStyleAttributeName:style, NSBaselineOffsetAttributeName: offset}
                                                  context:nil];
        CGSize labelSize = textRect.size;
        if(labelSize.height <= size.height)
        {
            label.font = font;
            [label setNeedsLayout];
            break;
        }
    }
    // set the font to the minimum size anyway
    label.font = font;
    [label setNeedsLayout];
}

@end
