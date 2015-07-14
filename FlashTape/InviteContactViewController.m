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
#import "GeneralUtils.h"
#import "InviteUtils.h"
#import "UICustomLineLabel.h"
#import "TrackingUtils.h"

#define INVITE_EMOJI_ARRAY @[@"😀", @"😊", @"😍", @"😎", @"😜"]

@interface InviteContactViewController ()
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UICustomLineLabel *tapToInviteLabel;
@property (weak, nonatomic) IBOutlet UIButton *notNowButton;
@property (weak, nonatomic) IBOutlet UILabel *emojiLabel;
@property (strong, nonatomic) NSDictionary *contactDictionnary;

@end

// --------------------------------------------
#pragma mark - Life Cycle
// --------------------------------------------
@implementation InviteContactViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Reset count
    [InviteUtils resetVideoSeenSinceLastInvitePresentedCount];
    
    if (self.contactArray.count == 0) {
        [self performSelector:@selector(nextOrDismiss) withObject:nil afterDelay:0.1];
        return;
    }
    
    self.contactDictionnary = [AddressbookUtils getContactDictionnary];
    
    UITapGestureRecognizer *tapGestureRecogniser = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap)];
    [self.view addGestureRecognizer:tapGestureRecogniser];
    
    // Labels
    self.tapToInviteLabel.text = NSLocalizedString(@"tap_to_invite", nil);
    self.tapToInviteLabel.lineType = LineTypeDown;
    self.tapToInviteLabel.lineHeight = 2.0f;
        
    // Name label
    [self setNameLabelWithContact:self.contactArray.firstObject];
    
    if ([GeneralUtils isiPhone4]) {
        self.emojiLabel.font = [UIFont systemFontOfSize:180];
    }
}


// --------------------------------------------
#pragma mark - Actions
// --------------------------------------------
- (void)handleTap {
    NSString *number = ((ABContact *)self.contactArray.firstObject).number;
    NSString *name = self.contactDictionnary[number];
    if (name) {
        name = [name componentsSeparatedByString:@" "].firstObject;
    } else {
        name = @"";
    }
    [ApiManager sendInviteTo:number
                        name:name
                     success:nil
                     failure:nil];
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
    self.view.backgroundColor = self.colorArray[arc4random_uniform((int)self.colorArray.count)];
    self.emojiLabel.text = INVITE_EMOJI_ARRAY[arc4random_uniform((int)INVITE_EMOJI_ARRAY.count)];
    
    self.nameLabel.numberOfLines = 0;
    NSString *name = self.contactDictionnary[contact.number] ? self.contactDictionnary[contact.number] : @"?" ;
    NSMutableAttributedString *nameAttributedString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:NSLocalizedString(@"mutual_friend_label", nil),name,MAX(2, contact.users.count)]];
    NSRange whiteRange = [[nameAttributedString string] rangeOfString:name];
    [nameAttributedString addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:whiteRange];
    self.nameLabel.attributedText = nameAttributedString;
    
    // Tracking invite presented
    [TrackingUtils trackEvent:EVENT_INVITE_PRESENTED properties:nil];
    [ApiManager incrementInviteSeenCount:contact];
}

@end
