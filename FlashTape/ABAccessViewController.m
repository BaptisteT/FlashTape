//
//  ContactAccessViewController.m
//  FlashTape
//
//  Created by Baptiste Truchot on 6/28/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
#import <AddressBook/AddressBook.h>

#import "ABContact.h"
#import "ApiManager.h"

#import "ABAccessViewController.h"
#import "FirstTimeAddFriendsViewController.h"
#import "VideoViewController.h"

#import "AddressbookUtils.h"
#import "ColorUtils.h"
#import "GeneralUtils.h"
#import "ImageUtils.h"
#import "UICustomLineLabel.h"
#import "MBProgressHUD.h"
#import "TrackingUtils.h"

@interface ABAccessViewController ()

@property (nonatomic) ABAddressBookRef addressBook;
@property (strong, nonatomic) IBOutlet UIButton *allowButton;
@property (strong, nonatomic) IBOutlet UICustomLineLabel *ABAccessContactLabel;
@property (strong, nonatomic) IBOutlet UILabel *ABExplanationLabel;
@property (weak, nonatomic) IBOutlet UIButton *skipButton;

@end

@implementation ABAccessViewController

// ----------------------------------------------------------
#pragma mark Life cycle
// ----------------------------------------------------------
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    
    // Hide skip button if pref
    if (!self.initialViewController && [GeneralUtils getSkipContactPref]) {
        self.skipButton.hidden = YES;
    }
    
    // Label
    self.ABExplanationLabel.numberOfLines = 0;
    self.ABExplanationLabel.minimumScaleFactor = 0.1;
    self.ABExplanationLabel.adjustsFontSizeToFitWidth = YES;
    self.ABExplanationLabel.lineBreakMode = NSLineBreakByClipping;
    self.ABAccessContactLabel.lineHeight = 4.0f;
    self.ABAccessContactLabel.lineType = LineTypeDown;
    self.ABAccessContactLabel.text = NSLocalizedString(@"allow_contact_label", nil);
    self.ABExplanationLabel.text = NSLocalizedString(@"adressbook_explanation", nil);
    
    // Button
    [self.allowButton setTitle:NSLocalizedString(@"allow_contact_button", nil) forState:UIControlStateNormal];
    [self.skipButton setTitle:NSLocalizedString(@"skip_button", nil) forState:UIControlStateNormal];
    
    // Contact button
    [self doBackgroundColorAnimation];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSString * segueName = segue.identifier;
    if ([segueName isEqualToString: @"ABFlashers From ABAccess"]) {
        ((FirstTimeAddFriendsViewController *) [segue destinationViewController]).flashersArray = (NSArray *)sender;
    } else if ([segueName isEqualToString: @"Video From ABAccess"]) {
        ((VideoViewController *) [segue destinationViewController]).isSignup = true;
    }
}

// ----------------------------------------------------------
#pragma mark Actions
// ----------------------------------------------------------
- (IBAction)allowABAccessButtonClicked:(id)sender {
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusDenied) {
        // redirect to settings
        if (&UIApplicationOpenSettingsURLString != NULL) {
            [GeneralUtils openSettings];
        } else {
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"contact_access_error_title", nil)
                                       message:NSLocalizedString(@"contact_access_error_message", nil)
                                      delegate:nil
                             cancelButtonTitle:@"Ok"
                             otherButtonTitles:nil] show];
        }
    } else {
        // Ask access and parse contacts
        [TrackingUtils trackEvent:EVENT_ALLOW_CONTACT_CLICKED properties:nil];
        
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        ABAddressBookRequestAccessWithCompletion(self.addressBook, ^(bool granted, CFErrorRef error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (granted) {
                    [TrackingUtils trackEvent:EVENT_CONTACT_ALLOWED properties:nil];
                    
                    // Parse contacts
                    NSMutableDictionary *contactDictionnary = [AddressbookUtils getFormattedPhoneNumbersFromAddressBook:self.addressBook];
                    
                    // Current user real name
                    NSString *abName = contactDictionnary[[User currentUser].username];
                    if (abName && abName.length > 0) {
                        [ApiManager saveAddressbookName:contactDictionnary[[User currentUser].username]];
                    }
                    
                    // Get flashers in my Addressbook
                    [ApiManager findFlashUsersContainedInAddressBook:[contactDictionnary allKeys]
                     success:^(NSArray *flashersArray) {
                         // Fill AB contacts
                         [ApiManager fillContactTableWithContacts:[contactDictionnary allKeys] aBFlasher:flashersArray success:^(NSArray *abContacts) {
                             // send x ghost invite
                             [ApiManager sendGhostInviteAmongContacts:abContacts abDictionnary:contactDictionnary];
                             
                             [self navigateToABFlashersController:flashersArray];
                         } failure:^(NSError *error) {
                             [self navigateToABFlashersController:flashersArray];
                         }];
                     } failure:^(NSError *error) {
                         [self navigateToVideoController];
                     }];
                    [AddressbookUtils saveContactDictionnary:contactDictionnary];
                } else {
                    [TrackingUtils trackEvent:EVENT_CONTACT_DENIED properties:nil];
                    [self navigateToVideoController];
                }
                [TrackingUtils setPeopleProperties:@{PROPERTY_ALLOW_CONTACT: [NSNumber numberWithBool:granted]}];
            });
        });
    }
}

- (IBAction)laterButtonClicked:(id)sender {
    [TrackingUtils trackEvent:EVENT_ALLOW_CONTACT_SKIPPED properties:nil];
    [self navigateToVideoController];
}

- (void)navigateToVideoController {
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    if (self.initialViewController) {
        // dismiss modally
        [self.initialViewController dismissViewControllerAnimated:NO completion:nil];
    } else {
        [self performSegueWithIdentifier:@"Video From ABAccess" sender:nil];
    }
}

- (void)navigateToABFlashersController:(NSArray *)flashers {
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    if (self.initialViewController) {
        // present modally
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
        FirstTimeAddFriendsViewController *abFlashersVC = [storyboard instantiateViewControllerWithIdentifier:@"ABFlashersVC"];
        abFlashersVC.initialViewController = self.initialViewController;
        abFlashersVC.flashersArray = flashers;
        [self presentViewController:abFlashersVC animated:NO completion:nil];
    } else {
        [self performSegueWithIdentifier:@"ABFlashers From ABAccess" sender:flashers];
    }
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
