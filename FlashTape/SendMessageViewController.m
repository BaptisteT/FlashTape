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

#define EMOJI_ARRAY @[@"❤️", @"😂", @"😔", @"😍", @"☺️", @"😎", @"😉", @"💋", @"😊", @"👍", @"😘", @"😡", @"😀", @"👌", @"😬", @"🙈", @"👅", @"🍻", @"😱", @"🙏", @"🐶", @"😜", @"💩", @"💪"]

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

@implementation SendMessageViewController {
    BOOL _emojiViewInitialized;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _emojiViewInitialized = NO;
    
    // Labels
    self.textView.tintColor = [UIColor blackColor];
    self.textViewPlaceholder.text = NSLocalizedString(@"create_message_placeholder", nil);
    self.textView.delegate = self;
    [self.backButton setTitle:NSLocalizedString(@"back_button", nil) forState:UIControlStateNormal];
    
    // State
    [self setEmojiState:YES];
    
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
    NSString *title = [NSString stringWithFormat:NSLocalizedString(@"send_title", nil),self.messageRecipient.flashUsername];
    NSRange usernameRange = [title rangeOfString:self.messageRecipient.flashUsername];
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:title];
    [attributedText setAttributes:@{NSFontAttributeName: [UIFont fontWithName:@"NHaasGroteskDSPro-65Md" size:self.titleLabel.font.pointSize]}
                            range:NSMakeRange(0, title.length)];
    [attributedText addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:usernameRange];
    [attributedText addAttribute:NSForegroundColorAttributeName value:[UIColor lightGrayColor] range:NSMakeRange(0,usernameRange.location)];
    self.titleLabel.attributedText = attributedText;
    self.textView.text = @"";
    self.textViewPlaceholder.hidden = self.textView.hidden;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!self.textView.hidden && ![self.textView isFirstResponder]) {
        [self.textView becomeFirstResponder];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self initEmojiView];
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
    [self.delegate closeReadAndMessageViews];
}

- (void)emojiClicked:(UIButton *)sender {
    [self sendMessage:sender.titleLabel.text];
}

- (void)sendMessage:(NSString *)message {
    [self.delegate sendMessage:message toUser:self.messageRecipient];
    [self.delegate closeReadAndMessageViews];
}

// ----------------------------------------------------------
#pragma mark Textview delegate
// ----------------------------------------------------------
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    NSString *newString = [textView.text stringByReplacingCharactersInRange:range withString:text];
    if ([text isEqualToString:@"\n"]) {
        if (newString.length > 0) {
            [self sendMessage:textView.text];
        }
        return NO;
    } else  {
        if (newString.length > kMaxMessageLength) {
            return NO;
        }
        self.textViewPlaceholder.hidden = newString.length > 0;
        return YES;
    }
}

// ----------------------------------------------------------
#pragma mark UI
// ----------------------------------------------------------
- (void)initEmojiView {
    if (!_emojiViewInitialized) {
        CGFloat width = self.emojiView.frame.size.width;
        CGFloat height = self.emojiView.frame.size.height;
        
        // assumption : horizontal margin = 1/3 of side
        NSInteger numberOfColumns = 4;
        CGFloat buttonSize = 3. / (4. * numberOfColumns + 1.) * width;
        CGFloat horizontalMargin = 1. / 3. * buttonSize;

        NSInteger numberOfRows = floor((height - buttonSize/3.) / (buttonSize * 4. / 3.));
        CGFloat verticalMargin = (height - numberOfRows * buttonSize) / (numberOfRows + 1.);
        
        // Get gray image for background
        UIGraphicsBeginImageContext(CGSizeMake(buttonSize, buttonSize));
        CGContextSetFillColorWithColor(UIGraphicsGetCurrentContext(), [UIColor lightGrayColor].CGColor);
        CGContextFillRect(UIGraphicsGetCurrentContext(), CGRectMake(0,0,buttonSize,buttonSize));
        UIImage *colorImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        for (int row = 0; row < numberOfRows; row ++) {
            for (int column = 0; column < numberOfColumns; column ++) {
                CGRect frame = CGRectMake(horizontalMargin + column * (buttonSize + horizontalMargin), verticalMargin + row * (verticalMargin + buttonSize), buttonSize, buttonSize);
                UIButton *button = [[UIButton alloc] initWithFrame:frame];
                [button setTitle:(NSString *)EMOJI_ARRAY[row + column * numberOfRows] forState:UIControlStateNormal];
                button.titleLabel.numberOfLines = 1;
                button.titleLabel.font = [UIFont systemFontOfSize:100];
                button.titleLabel.adjustsFontSizeToFitWidth = YES;
                [button.titleLabel setTextAlignment: NSTextAlignmentCenter];
                button.contentEdgeInsets = UIEdgeInsetsMake(-buttonSize/2.75, 0.0, 0.0, 0.0);
                [button setBackgroundImage:colorImage forState:UIControlStateHighlighted];
                [button addTarget:self action:@selector(emojiClicked:) forControlEvents:UIControlEventTouchUpInside];
                [self.emojiView addSubview:button];
            }
        }
        _emojiViewInitialized = YES;
    }
}

- (void)setEmojiState:(BOOL)emojiFlag
{
    if (emojiFlag) {
        self.emojiButton.backgroundColor = [UIColor whiteColor];
        self.textButton.backgroundColor = [UIColor clearColor];
        self.textButton.titleLabel.textColor = [UIColor whiteColor];
        self.textView.hidden = YES;
        self.textViewPlaceholder.hidden = YES;
        self.emojiView.hidden = NO;
        [self.textView resignFirstResponder];
    } else {
        self.emojiButton.backgroundColor = [UIColor clearColor];
        self.textButton.backgroundColor = [UIColor whiteColor];
        [self.textButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
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
