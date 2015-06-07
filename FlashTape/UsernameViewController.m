//
//  UsernameViewController.m
//  FlashTape
//
//  Created by Baptiste Truchot on 6/2/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
#import "ApiManager.h"

#import "UsernameViewController.h"

#import "ConstantUtils.h"
#import "GeneralUtils.h"
#import "UICustomLineLabel.h"
#import "MBProgressHUD.h"
#import "ColorUtils.h"

@interface UsernameViewController ()

@property (weak, nonatomic) IBOutlet UICustomLineLabel *viewTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *viewExplanationLabel;
@property (weak, nonatomic) IBOutlet UIButton *doneButtonClicked;
@property (weak, nonatomic) IBOutlet UITextField *usernameTextfield;
@property (weak, nonatomic) IBOutlet UIView *textFieldBackgroundView;

@end

@implementation UsernameViewController

// ----------------------------------------------------------
#pragma mark Life cycle
// ----------------------------------------------------------

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.viewTitleLabel.text = NSLocalizedString(@"username_title", nil);
    self.viewExplanationLabel.text = NSLocalizedString(@"username_explanation", nil);
    self.usernameTextfield.delegate = self;
    [self doBackgroundColorAnimation];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:YES];
    [self.usernameTextfield becomeFirstResponder];
}


// ----------------------------------------------------------
#pragma mark Actions
// ----------------------------------------------------------
- (IBAction)doneButtonClicked:(id)sender {
    if (self.usernameTextfield.text.length < kUsernameMinLength) {
        [GeneralUtils showAlertMessage:NSLocalizedString(@"short_username_error_message", nil) withTitle:NSLocalizedString(@"short_username_error_message", nil)];
        return;
    }
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [ApiManager saveUsername:self.usernameTextfield.text
                     success:^{
                         [MBProgressHUD hideHUDForView:self.view animated:YES];
                         [self performSegueWithIdentifier:@"Videos From Username" sender:nil];
                     } failure:^(NSError *error) {
                         [MBProgressHUD hideHUDForView:self.view animated:YES];
                         if (error) {
                             [GeneralUtils showAlertMessage:NSLocalizedString(@"save_username_error_message", nil) withTitle:NSLocalizedString(@"save_username_error_title", nil)];
                         } else {
                             [GeneralUtils showAlertMessage:NSLocalizedString(@"already_taken_username_error_message", nil) withTitle:NSLocalizedString(@"already_taken_username_error_title", nil)];
                         }
                     }];
}

// ----------------------------------------------------------
#pragma mark TextView delegate
// ----------------------------------------------------------
// Can not jump first line
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if ([string isEqualToString:@"\n"]) {
        return NO;
    }
    return YES;
}

// --------------------------------------------
#pragma mark - Background Color Cycle
// --------------------------------------------
- (void)doBackgroundColorAnimation {
    static NSInteger i = 0;
    NSArray *colors = [NSArray arrayWithObjects:[ColorUtils pink],
                       [ColorUtils purple],
                       [ColorUtils blue],
                       [ColorUtils green],
                       [ColorUtils orange], nil];
    if(i >= [colors count]) {
        i = 0;
    }
    
    [UIView animateWithDuration:1.5f
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         self.textFieldBackgroundView.backgroundColor = [colors objectAtIndex:i];
                     } completion:^(BOOL finished) {
                         ++i;
                         [self doBackgroundColorAnimation];
                     }];
    
}


@end
