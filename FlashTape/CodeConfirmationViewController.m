//
//  CodeConfirmationViewController.m
//  FlashTape
//
//  Created by Baptiste Truchot on 5/7/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
#import "ApiManager.h"

#import "CodeConfirmationViewController.h"
#import "GeneralUtils.h"
#import "MBProgressHUD.h"

@interface CodeConfirmationViewController ()

@property (weak, nonatomic) IBOutlet UITextField *codeTextField;

@end

@implementation CodeConfirmationViewController


// --------------------------------------------
#pragma mark - Life Cycle
// --------------------------------------------
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.codeTextField.delegate = self;
    
    // Button
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back_button"] style:UIBarButtonItemStylePlain target:self action:@selector(backButtonClicked)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"next_button"] style:UIBarButtonItemStylePlain target:self action:@selector(nextButtonClicked)];
    [self setNextButtonColor];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.codeTextField becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.codeTextField resignFirstResponder];
}

// --------------------------------------------
#pragma mark - Actions
// --------------------------------------------
- (void)backButtonClicked {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)nextButtonClicked {
    [self.codeTextField resignFirstResponder];
    if ([self.codeTextField.text isEqualToString:self.verificationCode]) {
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [ApiManager logInUser:self.phoneNumber
                      success:^{
                          [MBProgressHUD hideHUDForView:self.view animated:YES];
                          [self performSegueWithIdentifier:@"Video From Code" sender:nil];
                      } failure:^{
                          [MBProgressHUD hideHUDForView:self.view animated:YES];
                          [GeneralUtils showMessage:NSLocalizedString(@"authentification_error_message", nil) withTitle:NSLocalizedString(@"authentification_error_title", nil)];
                      }];
    } else {
        [GeneralUtils showMessage:NSLocalizedString(@"invalid_code_error_message", nil) withTitle:nil];
    }
}

// --------------------------------------------
#pragma mark - Textfield Delegate
// --------------------------------------------
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    textField.text = [textField.text stringByReplacingCharactersInRange:range withString:string];
    [self setNextButtonColor];
    return NO;
}

// --------------------------------------------
#pragma mark - UI
// --------------------------------------------
- (void)setNextButtonColor {
    BOOL activate = (self.codeTextField.text.length == self.verificationCode.length);
    self.navigationItem.rightBarButtonItem.tintColor = [[UIColor whiteColor] colorWithAlphaComponent:activate ? 1 : 0.6];
    self.navigationItem.rightBarButtonItem.enabled = activate;
}

@end
