//
//  LogInViewController.m
//  FlashTape
//
//  Created by Baptiste Truchot on 5/6/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
#import "MBProgressHUD.h"
#import "NBPhoneNumberUtil.h"
#import "NBPhoneNumber.h"
#import "RMPhoneFormat.h"
#import "UICustomLineLabel.h"

#import "ApiManager.h"

#import "CodeConfirmationViewController.h"
#import "CountryCodeTableViewController.h"
#import "RequestPhoneViewController.h"

#import "AddressbookUtils.h"
#import "GeneralUtils.h"
#import "ColorUtils.h"

#define DEFAULT_COUNTRY @"USA"
#define DEFAULT_COUNTRY_CODE 1
#define DEFAULT_COUNTRY_LETTER_CODE @"us"

@interface RequestPhoneViewController ()

@property (weak, nonatomic) IBOutlet UILabel *countryCodeLabel;
@property (weak, nonatomic) IBOutlet UITextField *numberTextField;
@property (weak, nonatomic) IBOutlet UIButton *validationButton;
@property (nonatomic, strong) NSString *decimalPhoneNumber;
@property (nonatomic, strong) RMPhoneFormat *phoneFormat;
@property (weak, nonatomic) IBOutlet UIButton *countryNameButton;
@property (strong, nonatomic) IBOutlet UICustomLineLabel *titleLabel;
@property (strong, nonatomic) IBOutlet UIView *colorView;
@property (strong, nonatomic) IBOutlet UITextView *disclaimerTextView;
@property (strong, nonatomic) IBOutlet UIImageView *separatorImage;
@property (strong, nonatomic) IBOutlet UIButton *doneI4Button;

@end

@implementation RequestPhoneViewController

// --------------------------------------------
#pragma mark - Life Cycle
// --------------------------------------------

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.decimalPhoneNumber = @"";
    [self setInitialCountryInfo];
    
    //ColorView
    [self doBackgroundColorAnimation];

    //Label
    self.titleLabel.lineType = LineTypeDown;
    self.titleLabel.lineHeight = 4.0f;
    self.disclaimerTextView.text = NSLocalizedString(@"disclaimer_phone_number", nil);
    
    // Button
    self.validationButton.hidden = YES;
    self.doneI4Button.hidden = YES;
    
    // Textfield
    self.numberTextField.placeholder = NSLocalizedString(@"number_text_field_placeholder", nil);
    self.numberTextField.delegate = self;
    if ([self.numberTextField respondsToSelector:@selector(setAttributedPlaceholder:)]) {
        UIColor *color = [UIColor lightTextColor];
        self.numberTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:self.numberTextField.placeholder attributes:@{NSForegroundColorAttributeName: color}];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.numberTextField becomeFirstResponder];
    
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        self.separatorImage.hidden = YES;
        self.titleLabel.hidden = YES;
        self.doneI4Button.hidden = NO;
        CGRect frame = self.view.frame;
        frame.origin.y -= 120;
        self.view.frame = frame;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString * segueName = segue.identifier;
    
    if ([segueName isEqualToString: @"Code From Phone"]) {
        ((CodeConfirmationViewController *) [segue destinationViewController]).verificationCode = sender[1];
        ((CodeConfirmationViewController *) [segue destinationViewController]).phoneNumber = sender[0];
    }
    
    if ([segueName isEqualToString: @"Country From Phone"]) {
        ((CountryCodeTableViewController *) [segue destinationViewController]).delegate = self;
    }
}


// --------------------------------------------
#pragma mark - Action
// --------------------------------------------
- (IBAction)backButtonClicked:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)validateButtonClicked:(id)sender {
    NBPhoneNumberUtil *phoneUtil = [NBPhoneNumberUtil sharedInstance];
    NSError *aError = nil;
    NSString *internationalPhoneNumber = [NSString stringWithFormat:@"+%@%@", [self.countryCodeLabel.text substringFromIndex:1], self.decimalPhoneNumber];
    NBPhoneNumber *myNumber = [phoneUtil parse:internationalPhoneNumber
                                 defaultRegion:nil error:&aError];
    
    if (aError || ![phoneUtil isValidNumber:myNumber]) {
        [GeneralUtils showMessage:NSLocalizedString(@"phone_number_error_message",nil) withTitle:nil];
        return;
    } else {
        [self.numberTextField resignFirstResponder];
        NSString *formattedPhoneNumber = [phoneUtil format:myNumber
                                              numberFormat:NBEPhoneNumberFormatE164
                                                     error:&aError];
        
        [self sendCodeRequest:formattedPhoneNumber];
        
    }
}

- (IBAction)countryCodeButtonClicked:(id)sender {
    [self.numberTextField resignFirstResponder];
    [self performSegueWithIdentifier:@"Country From Phone" sender:nil];
}


- (void)sendCodeRequest:(NSString *)phoneNumber
{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [ApiManager requestSmsCode:phoneNumber retry:NO success:^(NSInteger code) {
        NSLog(@"%lu",(long)code);
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        [self performSegueWithIdentifier:@"Code From Phone" sender:@[phoneNumber,[[NSNumber numberWithLong:code] stringValue]]];
    } failure:^{
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        [GeneralUtils showMessage:NSLocalizedString(@"confirmation_code_error_message",nil) withTitle:nil];
    }];
}

// --------------------------------------------
#pragma mark - Country Code
// --------------------------------------------

- (void)setInitialCountryInfo
{
    NSDictionary *letterCodeToCountryNameAndCallingCode = [AddressbookUtils getCountriesAndCallingCodesForLetterCodes];
    
    //Warning: need to convert to lower case to work with our file PhoneCountries.txt
    NSString *localLetterCode = [[[NSLocale currentLocale] objectForKey: NSLocaleCountryCode] lowercaseString];
    
    NSString *localCountry = [letterCodeToCountryNameAndCallingCode objectForKey:localLetterCode][0];
    NSNumber *localCallingCode = [letterCodeToCountryNameAndCallingCode objectForKey:localLetterCode][1];
    
    if (localLetterCode && localCountry && localCallingCode) {
        [self updateCountryName:localCountry code:localCallingCode letterCode:localLetterCode];
    } else {
        [self updateCountryName:DEFAULT_COUNTRY code:[NSNumber numberWithInt:DEFAULT_COUNTRY_CODE] letterCode:DEFAULT_COUNTRY_LETTER_CODE];
    }
}

- (void)updateCountryName:(NSString *)countryName code:(NSNumber *)code letterCode:(NSString *)letterCode
{
    self.phoneFormat = [[RMPhoneFormat alloc] initWithDefaultCountry:letterCode];
    
    self.countryCodeLabel.text = [NSString stringWithFormat:@"+%@", code];
    self.numberTextField.text = [self.phoneFormat format:self.decimalPhoneNumber];
    self.countryNameButton.titleLabel.text = [NSString stringWithFormat:@"%@ ❯",countryName];
    [self.countryNameButton setTitle:[NSString stringWithFormat:@"%@ ❯",countryName] forState:UIControlStateNormal];
}


// --------------------------------------------
#pragma mark - Textfield delegate
// --------------------------------------------
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (string.length > 0) {
        self.decimalPhoneNumber = [self.decimalPhoneNumber stringByAppendingString:string];
    } else {
        NSString *newString = [[textField.text substringToIndex:range.location] stringByAppendingString:[textField.text substringFromIndex:range.location + range.length]];
        
        NSString *numberString = @"";
        
        for (int i=0; i<[newString length]; i++) {
            if (isdigit([newString characterAtIndex:i])) {
                numberString = [numberString stringByAppendingFormat:@"%c",[newString characterAtIndex:i]];
            }
        }
        
        self.decimalPhoneNumber = numberString;
    }
    
    textField.text = [self.phoneFormat format:self.decimalPhoneNumber];
    
    NBPhoneNumberUtil *phoneUtil = [NBPhoneNumberUtil sharedInstance];
    NSError *aError = nil;
    NSString *internationalPhoneNumber = [NSString stringWithFormat:@"+%@%@", [self.countryCodeLabel.text substringFromIndex:1], self.decimalPhoneNumber];
    NBPhoneNumber *myNumber = [phoneUtil parse:internationalPhoneNumber
                                 defaultRegion:nil error:&aError];
    
    if (aError || ![phoneUtil isValidNumber:myNumber]) {
        self.validationButton.hidden = YES;
    } else {
        self.validationButton.hidden = NO;
        
    }
    
    return NO;
}

- (void)keyboardWasShown:(NSNotification *)notification
{
    
    // Get the size of the keyboard.
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    //Given size may not account for screen rotation
    int height = MIN(keyboardSize.height,keyboardSize.width);
    int width = MAX(keyboardSize.height,keyboardSize.width);
    
    //Show the separator
    CGRect frame = self.separatorImage.frame;
    frame.origin.y -= height;
    self.separatorImage.frame = frame;
}

// --------------------------------------------
#pragma mark - Background Color Cycle
// --------------------------------------------
- (void) doBackgroundColorAnimation {
    static NSInteger i = 0;
    NSArray *colors = [NSArray arrayWithObjects:[ColorUtils pink],
                       [ColorUtils purple],
                       [ColorUtils blue],
                       [ColorUtils green],
                       [ColorUtils orange], nil];
    if(i >= [colors count]) {
        i = 0;
    }
    
    [UIView animateWithDuration:1.5f animations:^{
        self.colorView.backgroundColor = [colors objectAtIndex:i];
    } completion:^(BOOL finished) {
        ++i;
        [self doBackgroundColorAnimation];
    }];
    
}


@end
