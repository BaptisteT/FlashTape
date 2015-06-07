//
//  SendMessageViewController.m
//  FlashTape
//
//  Created by Baptiste Truchot on 6/7/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
#import "User.h"

#import "SendMessageViewController.h"

#import "KeyboardUtils.h"

@interface SendMessageViewController ()
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIView *emojiView;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UILabel *textViewPlaceholder;
@property (weak, nonatomic) IBOutlet UIView *messageTypeContainerView;
@property (weak, nonatomic) IBOutlet UIButton *emojiButton;
@property (weak, nonatomic) IBOutlet UIButton *textButton;

@end

@implementation SendMessageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // State
    [self setEmojiState:YES];
    
    // Labels
    NSString *title = [NSString stringWithFormat:NSLocalizedString(@"send_title", nil),self.messageRecipient.flashUsername];
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:title];
    [attributedText setAttributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:self.titleLabel.font.pointSize]}
                            range:[title rangeOfString:self.messageRecipient.flashUsername]];
    self.titleLabel.attributedText = attributedText;
    self.textView.text = @"";
    self.textView.tintColor = [UIColor blackColor];
    self.textViewPlaceholder.text = NSLocalizedString(@"create_message_placeholder", nil);
    self.textView.delegate = self;
    [self.backButton setTitle:NSLocalizedString(@"back_button", nil) forState:UIControlStateNormal];
    
    // Observer
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.messageTypeContainerView.translatesAutoresizingMaskIntoConstraints = YES;
}

// ----------------------------------------------------------
#pragma mark Actions
// ----------------------------------------------------------
- (IBAction)emojiButtonClicked:(id)sender {
    [self setEmojiState:YES];
}
- (IBAction)textButtonClicked:(id)sender {
    [self setEmojiState:NO];
}

- (IBAction)backButtonClicked:(id)sender {
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (void)setEmojiState:(BOOL)emojiFlag
{
    if (emojiFlag) {
        self.textView.hidden = YES;
        self.textViewPlaceholder.hidden = YES;
        self.emojiView.hidden = NO;
        [self.textView resignFirstResponder];
    } else {
        self.emojiView.hidden = YES;
        self.textView.hidden = NO;
        if (self.textView.text.length == 0) {
            self.textViewPlaceholder.hidden = NO;
        }
        [self.textView becomeFirstResponder];
    }
}

// ----------------------------------------------------------
#pragma mark Textview delegate
// ----------------------------------------------------------
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        // todo BT
        // send
        return NO;
    }
    self.textViewPlaceholder.hidden = [textView.text stringByReplacingCharactersInRange:range withString:text].length > 0;
    return YES;
}


// ----------------------------------------------------------
#pragma mark Keyboard
// ----------------------------------------------------------
// Move up create comment view on keyboard will show
- (void)keyboardWillShow:(NSNotification *)notification {
    [KeyboardUtils pushUpTopView:self.messageTypeContainerView whenKeyboardWillShowNotification:notification];
}

// Move down create comment view on keyboard will hide
- (void)keyboardWillHide:(NSNotification *)notification {
    [KeyboardUtils pushDownTopView:self.messageTypeContainerView whenKeyboardWillhideNotification:notification];
}


@end
