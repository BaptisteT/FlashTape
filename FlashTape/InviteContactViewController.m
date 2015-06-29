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
    
    self.view.backgroundColor = [ColorUtils blue];
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
    self.nameLabel.numberOfLines = 0;
    NSDictionary *contactDictionnary = [AddressbookUtils getContactDictionnary];
    NSString *name = contactDictionnary[self.contact.number] ? contactDictionnary[self.contact.number] : @"" ;
    NSMutableAttributedString *nameAttributedString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:NSLocalizedString(@"mutual_friend_label", nil),MAX(1, self.contact.users.count - 1),name]];
    
    NSRange whiteRange = [[nameAttributedString string] rangeOfString:name];
    [nameAttributedString addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:whiteRange];
    self.nameLabel.attributedText = nameAttributedString;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // Update invite markers
    [InviteUtils setLastInvitePresentedDate:[NSDate date]];
    [InviteUtils incrementInvitePresentedCount];
    
    // Tracking
    [TrackingUtils trackInviteControllerPresented];
}

// --------------------------------------------
#pragma mark - Actions
// --------------------------------------------
- (void)handleTap {
    [ApiManager sendInviteTo:self.contact.number success:nil failure:nil];
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (IBAction)notNowButtonClicked:(id)sender {
    [self dismissViewControllerAnimated:NO completion:nil];
}


@end
