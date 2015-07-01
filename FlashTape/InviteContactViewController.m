//
//  InviteContactViewController.m
//  FlashTape
//
//  Created by Baptiste Truchot on 6/29/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
#import "ABContact.h"
#import "ApiManager.h"

#import "InviteContactViewController.h"

#import "AddressbookUtils.h"
#import "ColorUtils.h"
#import "InviteUtils.h"
#import "UICustomLineLabel.h"
#import "TrackingUtils.h"

@interface InviteContactViewController ()
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UICustomLineLabel *tapToInviteLabel;
@property (weak, nonatomic) IBOutlet UIButton *notNowButton;

@end

// --------------------------------------------
#pragma mark - Life Cycle
// --------------------------------------------
@implementation InviteContactViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.contactArray.count == 0) {
        [self dismissViewControllerAnimated:NO completion:nil];
        return;
    }
    
    self.view.backgroundColor = self.backgroundColor ? self.backgroundColor : [ColorUtils blue];
    
    UITapGestureRecognizer *tapGestureRecogniser = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap)];
    [self.view addGestureRecognizer:tapGestureRecogniser];
    
    // Labels
    self.tapToInviteLabel.text = NSLocalizedString(@"tap_to_invite", nil);
    self.tapToInviteLabel.lineType = LineTypeDown;
    self.tapToInviteLabel.lineHeight = 2.0f;
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:NSLocalizedString(@"not_now", nil)];
    [attributedString addAttributes:@{NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle), NSUnderlineColorAttributeName: [UIColor whiteColor]} range:NSMakeRange(0,attributedString.length)];
    [self.notNowButton setAttributedTitle:attributedString forState:UIControlStateNormal];
    
    // Name label
    [self setNameLabelWithContact:self.contactArray.firstObject];
}


// --------------------------------------------
#pragma mark - Actions
// --------------------------------------------
- (void)handleTap {
    [ApiManager sendInviteTo:((ABContact *)self.contactArray.firstObject).number success:nil failure:nil];
    [self nextOrDismiss];
}

- (IBAction)notNowButtonClicked:(id)sender {
    [self nextOrDismiss];
}

- (void)nextOrDismiss {
    if (self.contactArray.count < 2) {
        [self dismissViewControllerAnimated:NO completion:nil];
    } else {
        [self.contactArray removeObjectAtIndex:0];
        [self setNameLabelWithContact:self.contactArray.firstObject];
    }
}

// --------------------------------------------
#pragma mark - UI
// --------------------------------------------
- (void)setNameLabelWithContact:(ABContact *)contact {
    self.nameLabel.numberOfLines = 0;
    NSDictionary *contactDictionnary = [AddressbookUtils getContactDictionnary];
    NSString *name = contactDictionnary[contact.number] ? contactDictionnary[contact.number] : @"" ;
    NSMutableAttributedString *nameAttributedString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:NSLocalizedString(@"mutual_friend_label", nil),name,MAX(2, contact.users.count)]];
    NSRange whiteRange = [[nameAttributedString string] rangeOfString:name];
    [nameAttributedString addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:whiteRange];
    self.nameLabel.attributedText = nameAttributedString;
    
    // Tracking invite presented
    [TrackingUtils trackEvent:EVENT_INVITE_PRESENTED properties:nil];
    [ApiManager incrementInviteSeenCount:contact];
}

@end
