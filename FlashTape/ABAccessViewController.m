//
//  ContactAccessViewController.m
//  FlashTape
//
//  Created by Baptiste Truchot on 6/28/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
#import <AddressBook/AddressBook.h>

#import "ApiManager.h"

#import "ABAccessViewController.h"
#import "ABFlashersViewController.h"

#import "AddressbookUtils.h"
#import "ColorUtils.h"
#import "ImageUtils.h"
#import "UICustomLineLabel.h"

@interface ABAccessViewController ()

@property (nonatomic) ABAddressBookRef addressBook;
@property (strong, nonatomic) IBOutlet UIButton *allowButton;
@property (strong, nonatomic) IBOutlet UICustomLineLabel *ABAccessContactLabel;
@property (strong, nonatomic) IBOutlet UILabel *ABExplanationLabel;

@end

@implementation ABAccessViewController

// ----------------------------------------------------------
#pragma mark Life cycle
// ----------------------------------------------------------
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    
    // Label
    self.ABAccessContactLabel.lineHeight = 4.0f;
    self.ABAccessContactLabel.lineType = LineTypeDown;
    self.ABAccessContactLabel.text = NSLocalizedString(@"allow_contact_label", nil);
    self.ABExplanationLabel.text = NSLocalizedString(@"adressbook_explanation", nil);
    
    // Button
    [self.allowButton setTitle:NSLocalizedString(@"allow_contact_button", nil) forState:UIControlStateNormal];
    
    // Contact button
    [self doBackgroundColorAnimation];

}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSString * segueName = segue.identifier;
    if ([segueName isEqualToString: @"ABFlashers From ABAccess"]) {
        ((ABFlashersViewController *) [segue destinationViewController]).flashersArray = (NSArray *)sender;
    }
}

// ----------------------------------------------------------
#pragma mark Actions
// ----------------------------------------------------------
- (IBAction)allowABAccessButtonClicked:(id)sender {
    // UI
    [self startLoadingAnimation];
    
    // Ask access and parse contacts
    ABAddressBookRequestAccessWithCompletion(self.addressBook, ^(bool granted, CFErrorRef error) {
        dispatch_async(dispatch_get_main_queue(), ^{
                if (granted) {
                NSMutableDictionary *contactDictionnary = [AddressbookUtils getFormattedPhoneNumbersFromAddressBook:self.addressBook];
                [ApiManager findFlashUsersContainedInAddressBook:[contactDictionnary allKeys]
                                                         success:^(NSArray *flashersArray) {
                                                             if (flashersArray && flashersArray.count > 0) {
                                                                 [self navigateToABFlashersController:flashersArray];
                                                             } else {
                                                                 [self navigateToVideoController];
                                                             }
                                                         } failure:^(NSError *error) {
                                                             [self navigateToVideoController];
                                                         }];
                [AddressbookUtils saveContactDictionnary:contactDictionnary];
            } else {
                [self navigateToVideoController];
            }
        });
    });
    
}

- (void)navigateToVideoController {
    [self stopLoadingAnimation];
    [self performSegueWithIdentifier:@"Video From ABAccess" sender:nil];
}

- (void)navigateToABFlashersController:(NSArray *)flashers {
    [self stopLoadingAnimation];
    [self performSegueWithIdentifier:@"ABFlashers From ABAccess" sender:flashers];
}

// ----------------------------------------------------------
#pragma mark UI
// ----------------------------------------------------------
- (void)startLoadingAnimation
{
}

- (void)stopLoadingAnimation {
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
    
    [UIView animateWithDuration:1.5f delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        self.allowButton.backgroundColor = [colors objectAtIndex:i];
    } completion:^(BOOL finished) {
        ++i;
        [self doBackgroundColorAnimation];
    }];
    
}



@end
