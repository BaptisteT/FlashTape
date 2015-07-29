//
//  SendMessageViewController.m
//  FlashTape
//
//  Created by Baptiste Truchot on 6/7/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
#import "User.h"

#import "SendMessageViewController.h"

#import "ConstantUtils.h"
#import "KeyboardUtils.h"
#import "TrackingUtils.h"

@interface SendMessageViewController ()
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIView *emojiView;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UILabel *textViewPlaceholder;
@property (weak, nonatomic) IBOutlet UIView *messageTypeContainerView;
@property (weak, nonatomic) IBOutlet UIButton *emojiButton;
@property (weak, nonatomic) IBOutlet UIButton *textButton;
@property (strong, nonatomic) EmojiViewController *emojiController;

@end

@implementation SendMessageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Labels
    self.textView.tintColor = [UIColor blackColor];
    self.textViewPlaceholder.text = NSLocalizedString(@"create_message_placeholder", nil);
    self.textView.delegate = self;
    
    // State
    [self setEmojiState:YES];
    
    [self.textView addObserver:self forKeyPath:@"contentSize" options:(NSKeyValueObservingOptionNew) context:NULL];

    
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

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Label
    NSString *username = self.messageRecipient.flashUsername ? self.messageRecipient.flashUsername : @"";
    NSString *title = [NSString stringWithFormat:NSLocalizedString(@"send_title", nil),username];
    NSRange usernameRange = [title rangeOfString:username];
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:title];
    [attributedText setAttributes:@{NSFontAttributeName: [UIFont fontWithName:@"NHaasGroteskDSPro-65Md" size:self.titleLabel.font.pointSize]}
                            range:NSMakeRange(0, title.length)];
    [attributedText addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:usernameRange];
    [attributedText addAttribute:NSForegroundColorAttributeName value:[UIColor lightGrayColor] range:NSMakeRange(0,usernameRange.location-1)];
    self.titleLabel.attributedText = attributedText;
    self.textView.text = @"";
    self.textViewPlaceholder.hidden = self.textView.hidden;
    
    if (!self.textView.hidden && ![self.textView isFirstResponder]) {
        [self.textView becomeFirstResponder];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.messageTypeContainerView.translatesAutoresizingMaskIntoConstraints = YES;
    [self adjustTextViewOffset];
    
    [self.emojiController reloadEmojis];
}

- (void)adjustTextViewOffset {
    CGFloat topoffset = ([self.textView bounds].size.height - [self.textView contentSize].height * [self.textView zoomScale])/2.0;
    topoffset = ( topoffset < 0.0 ? 0.0 : topoffset );
    self.textView.contentOffset = (CGPoint){.x = 0, .y = -topoffset};
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSString * segueName = segue.identifier;
    if ([segueName isEqualToString: @"Emoji From Send"]) {
        self.emojiController = (EmojiViewController *) [segue destinationViewController];
        self.emojiController.delegate = self;
    }
}


// ----------------------------------------------------------
#pragma mark Actions
// ----------------------------------------------------------
- (IBAction)emojiButtonClicked:(id)sender {
    [self.emojiController reloadEmojis];
    [self setEmojiState:YES];
}

- (IBAction)textButtonClicked:(id)sender {
    [self setEmojiState:NO];
}

- (IBAction)backButtonClicked:(id)sender {
    [self.delegate closeReadAndMessageViews];
}

- (void)emojiClicked:(NSString *)emoji {
    [TrackingUtils trackEvent:EVENT_MESSAGE_SENT properties:@{@"type": @"emoji"}];
    [self sendMessage:emoji];
}

- (void)sendMessage:(NSString *)message {
    [self.delegate sendMessage:message toUser:self.messageRecipient];
    [self.delegate closeReadAndMessageViews];
}   

// ----------------------------------------------------------
#pragma mark Textview delegate
// ----------------------------------------------------------
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        NSCharacterSet *set = [NSCharacterSet whitespaceCharacterSet];
        if ([textView.text stringByTrimmingCharactersInSet:set].length > 0) {
            [TrackingUtils trackEvent:EVENT_MESSAGE_SENT properties:@{@"type": @"text"}];
            [self sendMessage:textView.text];
        }
        return NO;
    } else  {
        NSString *newString = [textView.text stringByReplacingCharactersInRange:range withString:text];
        if (newString.length > kMaxMessageLength) {
            return NO;
        }
        self.textViewPlaceholder.hidden = newString.length > 0;
        return YES;
    }
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == self.textView) {
        [self adjustTextViewOffset];
    }
}

// ----------------------------------------------------------
#pragma mark UI
// ----------------------------------------------------------
- (void)setEmojiState:(BOOL)emojiFlag
{
    if (emojiFlag) {
        [self.textView resignFirstResponder];
        self.emojiButton.backgroundColor = [UIColor whiteColor];
        self.textButton.backgroundColor = [UIColor clearColor];
        self.textButton.titleLabel.textColor = [UIColor whiteColor];
        self.textView.hidden = YES;
        self.textViewPlaceholder.hidden = YES;
        self.emojiView.hidden = NO;
    } else {
        self.emojiButton.backgroundColor = [UIColor clearColor];
        self.textButton.backgroundColor = [UIColor whiteColor];
        [self.textButton setTitleColor:[UIColor colorWithRed:204./255. green:204./255. blue:204./255. alpha:1] forState:UIControlStateNormal];
        self.emojiView.hidden = YES;
        self.textView.hidden = NO;
        if (self.textView.text.length == 0) {
            self.textViewPlaceholder.hidden = NO;
        }
        [self.textView becomeFirstResponder];
    }
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

- (BOOL)prefersStatusBarHidden {
    return NO;
}


@end
