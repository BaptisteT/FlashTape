//
//  CodeConfirmationViewController.m
//  FlashTape
//
//  Created by Baptiste Truchot on 5/7/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
#import "ApiManager.h"
#import "User.h"

#import "UICustomLineLabel.h"
#import "CodeConfirmationViewController.h"
#import "GeneralUtils.h"
#import "MBProgressHUD.h"
#import "ColorUtils.h"
#import "NotifUtils.h"

@interface CodeConfirmationViewController ()

@property (strong, nonatomic) IBOutlet UILabel *disclaimerLabel;
@property (strong, nonatomic) IBOutlet UICustomLineLabel *titleLabel;
@property (strong, nonatomic) IBOutlet UITextField *codeTextField1;
@property (strong, nonatomic) IBOutlet UITextField *codeTextField2;
@property (strong, nonatomic) IBOutlet UITextField *codeTextField3;
@property (strong, nonatomic) IBOutlet UITextField *codeTextField4;
@property (strong, nonatomic) IBOutlet UIView *colorView1;
@property (strong, nonatomic) IBOutlet UIView *colorView2;
@property (strong, nonatomic) IBOutlet UIView *colorView3;
@property (strong, nonatomic) IBOutlet UIView *colorView4;
@property (strong,nonatomic) NSString *code;

@end

@implementation CodeConfirmationViewController


// --------------------------------------------
#pragma mark - Life Cycle
// --------------------------------------------
- (void)viewDidLoad {
    [super viewDidLoad];
    
    //Color View
    [self doBackgroundColorAnimation];
    
    //TextField
    self.codeTextField1.delegate = self;
    self.codeTextField2.delegate = self;
    self.codeTextField3.delegate = self;
    self.codeTextField4.delegate = self;
    [[UITextField appearance] setTintColor:[UIColor whiteColor]];
    
    //Label
    self.titleLabel.lineType = LineTypeDown;
    self.titleLabel.lineHeight = 4.0f;
    self.disclaimerLabel.numberOfLines = 0;
    self.disclaimerLabel.text = NSLocalizedString(@"disclaimer_verification_code", nil);
}

- (void)viewWillAppear:(BOOL)animated {
    [self.codeTextField1 becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.codeTextField1 resignFirstResponder];
    [self.codeTextField2 resignFirstResponder];
    [self.codeTextField3 resignFirstResponder];
    [self.codeTextField4 resignFirstResponder];
}

// --------------------------------------------
#pragma mark - Actions
// --------------------------------------------
- (IBAction)backButtonClicked:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)nextButtonClicked:(id)sender {
    [self.codeTextField1 resignFirstResponder];
    [self.codeTextField2 resignFirstResponder];
    [self.codeTextField3 resignFirstResponder];
    [self.codeTextField4 resignFirstResponder];
    self.code = [NSString stringWithFormat:@"%@%@%@%@",self.codeTextField1.text, self.codeTextField2.text, self.codeTextField3.text, self.codeTextField4.text];
    if ([self.code isEqualToString:self.verificationCode]) {
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [ApiManager logInUser:self.phoneNumber
                      success:^{
                          [NotifUtils registerForRemoteNotif];
                          [MBProgressHUD hideHUDForView:self.view animated:YES];
                          User *currentUser = [User currentUser];
                          if (currentUser.flashUsername && currentUser.flashUsername.length > 0) {
                              [self performSegueWithIdentifier:@"Videos From Code" sender:nil];
                          } else {
                              [self performSegueWithIdentifier:@"Username From Code" sender:nil];
                          }
                      } failure:^{
                          [MBProgressHUD hideHUDForView:self.view animated:YES];
                          [GeneralUtils showAlertMessage:NSLocalizedString(@"authentification_error_message", nil) withTitle:NSLocalizedString(@"authentification_error_title", nil)];
                      }];
    } else {
        [GeneralUtils showAlertMessage:NSLocalizedString(@"invalid_code_error_message", nil) withTitle:nil];
    }
}

// --------------------------------------------
#pragma mark - Textfield Delegate
// --------------------------------------------
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    NSString *finalString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    if ( [finalString length] > 0 ) {
        textField.text = string;
        
        if (self.codeTextField1.isFirstResponder) {
            [self.codeTextField2 becomeFirstResponder];
        } else if (self.codeTextField2.isFirstResponder) {
            [self.codeTextField3 becomeFirstResponder];
        } else if (self.codeTextField3.isFirstResponder) {
            [self.codeTextField4 becomeFirstResponder];
        } else {
        }
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
        self.colorView1.backgroundColor = [colors objectAtIndex:i];
        self.colorView2.backgroundColor = [colors objectAtIndex:i];
        self.colorView3.backgroundColor = [colors objectAtIndex:i];
        self.colorView4.backgroundColor = [colors objectAtIndex:i];
    } completion:^(BOOL finished) {
        ++i;
        [self doBackgroundColorAnimation];
    }];
    
}

@end
