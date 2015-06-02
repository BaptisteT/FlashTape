//
//  CreateMessageTableViewCell.m
//  FlashTape
//
//  Created by Baptiste Truchot on 6/2/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//

#import "CreateMessageTableViewCell.h"

#import "ConstantUtils.h"

@interface CreateMessageTableViewCell()
@property (weak, nonatomic) IBOutlet UIButton *postButton;
@property (weak, nonatomic) IBOutlet UITextField *messageTextField;

@end

@implementation CreateMessageTableViewCell

- (void)initWithDelegate:(id<CreateMessageTVCDelegate>)delegate {
    self.messageTextField.text = @"";
    [self setPostButtonTitleColor];
    self.messageTextField.placeholder = NSLocalizedString(@"create_message_placeholder", nil);
    self.delegate = delegate;
    self.messageTextField.delegate = self;
    [self.postButton setTitle:NSLocalizedString(@"send_button", nil) forState:UIControlStateNormal];
    [self.messageTextField performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.01];
}

// Set post button title (white if any text, pink otherwise)
- (void)setPostButtonTitleColor {
    UIColor *postButtonColor;
    if ([self.messageTextField.text isEqualToString:@""]) {
        postButtonColor = [UIColor lightGrayColor];
    } else {
        postButtonColor = [UIColor blackColor];
    }
    [self.postButton setTitleColor:postButtonColor forState:UIControlStateNormal];
}

- (IBAction)postButtonClicked:(id)sender {
    if (self.messageTextField.text.length == 0) {
        return;
    }
    [self.delegate sendMessage:self.messageTextField.text];
    self.messageTextField.text = @"";
    [self setPostButtonTitleColor];
}

// ----------------------------------------------------------
#pragma mark TextView delegate
// ----------------------------------------------------------
// Can not jump first line
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if ([string isEqualToString:@"\n"]) {
        [self postButtonClicked:nil];
        return NO;
    } else  if ([textField.text stringByReplacingCharactersInRange:range withString:string].length > kMaxMessageLength) {
        return NO;
    } else {
        textField.text = [textField.text stringByReplacingCharactersInRange:range withString:string];
        [self setPostButtonTitleColor];
        return NO;
    }
}


@end
