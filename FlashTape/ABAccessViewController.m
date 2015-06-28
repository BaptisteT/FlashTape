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

@interface ABAccessViewController ()

@property (nonatomic) ABAddressBookRef addressBook;
@property (weak, nonatomic) IBOutlet UIButton *allowABAccessButton;
@property (nonatomic, strong) CAShapeLayer *ABAccessButtonCircleShape;

@end

@implementation ABAccessViewController

// ----------------------------------------------------------
#pragma mark Life cycle
// ----------------------------------------------------------
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    
    // Contact button
    [self setAllowContactButtonUI];
    [self initLoadingCircleShape];
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
- (void)setAllowContactButtonUI {
    self.allowABAccessButton.layer.cornerRadius = self.allowABAccessButton.frame.size.height / 2;
    self.allowABAccessButton.layer.borderWidth = 1;
    self.allowABAccessButton.layer.borderColor = [ColorUtils blue].CGColor;
    self.allowABAccessButton.titleLabel.numberOfLines = 0;
    self.allowABAccessButton.clipsToBounds = NO;
    [self.allowABAccessButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
    [self.allowABAccessButton setTitle:NSLocalizedString(@"allow_contact_button", nil) forState:UIControlStateNormal];
}

- (void)startLoadingAnimation
{
    self.allowABAccessButton.enabled = NO;
    self.allowABAccessButton.layer.borderColor = [UIColor clearColor].CGColor;

    // Add to parent layer
    [self.allowABAccessButton.layer addSublayer:self.ABAccessButtonCircleShape];
    CABasicAnimation *rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.fromValue = [NSNumber numberWithFloat:0.0f];
    rotationAnimation.toValue = [NSNumber numberWithFloat:2*M_PI];
    rotationAnimation.duration = 0.7;
    rotationAnimation.repeatCount = INFINITY;
    [self.ABAccessButtonCircleShape addAnimation:rotationAnimation forKey:@"indeterminateAnimation"];
}

- (void)stopLoadingAnimation {
    [self.ABAccessButtonCircleShape removeAllAnimations];
    [self.ABAccessButtonCircleShape removeFromSuperlayer];
    self.allowABAccessButton.enabled = YES;
    self.allowABAccessButton.layer.borderColor = [ColorUtils blue].CGColor;
}

- (void)initLoadingCircleShape
{
    self.ABAccessButtonCircleShape = [ImageUtils createGradientCircleLayerWithFrame:CGRectMake(0,0,self.allowABAccessButton.frame.size.width,self.allowABAccessButton.frame.size.height) borderWidth:1 Color:[ColorUtils blue] subDivisions:100];
}


@end
