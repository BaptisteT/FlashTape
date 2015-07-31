//
//  UnlockEmojisViewController.m
//  FlashTape
//
//  Created by Baptiste Truchot on 7/28/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
#import "Branch.h"

#import "ABContact.h"
#import "ApiManager.h"
#import "DatastoreUtils.h"

#import "InviteContactTableViewCell.h"
#import "UnlockEmojisViewController.h"

#import "AddressbookUtils.h"
#import "ColorUtils.h"
#import "ConstantUtils.h"
#import "GeneralUtils.h"
#import "MBProgressHUD.h"
#import "TrackingUtils.h"

@interface UnlockEmojisViewController ()
@property (strong, nonatomic) NSDictionary *contactDictionnary;
@property (strong, nonatomic) NSMutableArray *contactsToInviteArray;
@property (weak, nonatomic) IBOutlet UIButton *inviteButton;
@property (weak, nonatomic) IBOutlet UITableView *contactTableView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIView *titleBackgroundView;

@property (strong, nonatomic) NSMutableArray *abContactArray;

@end

@implementation UnlockEmojisViewController

// --------------------------------------------
#pragma mark - Life cycle
// --------------------------------------------
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Get addressbook contacts
    self.contactDictionnary = [AddressbookUtils getContactDictionnary];
    self.contactsToInviteArray = [NSMutableArray new];
    
    // Fill Contacts
    [DatastoreUtils  getAllABContactsLocallySuccess:^(NSArray *contacts) {
        self.abContactArray = [NSMutableArray arrayWithArray:[ABContact sortABContacts:contacts contactDictionnary:self.contactDictionnary]];
        [self.contactTableView reloadData];
    } failure:nil];
    
    // Tableview
    self.contactTableView.dataSource = self;
    self.contactTableView.delegate = self;
    self.contactTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    // Button
    self.titleLabel.numberOfLines = 0;
    self.titleLabel.text = NSLocalizedString(@"unlock_emojis_title", nil);
    [self setInviteButtonTitle];
    
    //Status Bar
    [self setNeedsStatusBarAppearanceUpdate];
    
    //Color background
    [self doBackgroundColorAnimation];
}

// --------------------------------------------
#pragma mark - Actions
// --------------------------------------------

- (IBAction)inviteButtonClicked:(id)sender {
    if (self.contactsToInviteArray.count >= kNumberOfInviteToUnlockEmojis) {
        if(![MFMessageComposeViewController canSendText]) {
            [GeneralUtils showAlertMessage:NSLocalizedString(@"no_sms_error_message", nil) withTitle:nil];
            return;
        }
        
        
        [[Branch getInstance] getShortURLWithParams:@{@"referringUsername":[User currentUser].flashUsername, @"referringUserId":[User currentUser].objectId}
                                         andChannel:@"SMS.unlock_emojis"
                                         andFeature:BRANCH_FEATURE_TAG_SHARE
                                           andStage:nil
                                           andAlias:@"Flashtape"
                                        andCallback:^(NSString *url, NSError *error)
         {
            MFMessageComposeViewController *messageController = [[MFMessageComposeViewController alloc] init];
            messageController.messageComposeDelegate = self;
            [messageController setBody:[NSString stringWithFormat:NSLocalizedString(@"sharing_wording", nil),url]];
            
            NSMutableArray *numbers = [NSMutableArray new];
            for (ABContact *contact in self.contactsToInviteArray) {
                [numbers addObject:contact.number];
            }
            [messageController setRecipients:numbers];
            [self presentViewController:messageController animated:YES completion:nil];
        }];
    }
}

- (IBAction)backButtonClicked:(id)sender {
    [self dismissViewControllerAnimated:NO completion:nil];
}

// --------------------------------------------
#pragma mark - Tableview
// --------------------------------------------
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.abContactArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 58;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath  {
    InviteContactTableViewCell *cell = (InviteContactTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"InviteContactTableViewCell"];
    if (!cell) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"InviteContactTableViewCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
        cell.delegate = self;
    }
    ABContact *contact = (ABContact *)self.abContactArray[indexPath.row];
    [cell initWithName:self.contactDictionnary[contact.number] contact:contact indexPath:indexPath selected:[self.contactsToInviteArray containsObject:contact]];
    return cell;
}


// ----------------------------------------------------------
#pragma mark ABFlasherTableViewCell delegate
// ----------------------------------------------------------
- (void)inviteContact:(ABContact *)contact {
    if (![self.contactsToInviteArray containsObject:contact]) {
        [self.contactsToInviteArray addObject:contact];
    }
    [self setInviteButtonTitle];
}

- (void)removeContact:(ABContact *)contact {
    [self.contactsToInviteArray removeObject:contact];
    [self setInviteButtonTitle];
}

// --------------------------------------------
#pragma mark - UI
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
        self.titleBackgroundView.backgroundColor = [colors objectAtIndex:i];
        [self.inviteButton setTitleColor:[colors objectAtIndex:i] forState:UIControlStateNormal];
    } completion:^(BOOL finished) {
        ++i;
        [self doBackgroundColorAnimation];
    }];
}

- (void)setInviteButtonTitle {
    NSString *title = self.contactsToInviteArray.count >= kNumberOfInviteToUnlockEmojis ? NSLocalizedString(@"invite_friends_button", nil) : [NSString stringWithFormat:NSLocalizedString(@"invite_missing_button", nil),(kNumberOfInviteToUnlockEmojis - self.contactsToInviteArray.count)];
    [self.inviteButton setTitle:title forState:UIControlStateNormal];
}

-(UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent; // Set status bar color to white
}

// ----------------------------------------------------------
#pragma mark SMS controller
// ----------------------------------------------------------

// Dismiss message after finish
- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    [self dismissViewControllerAnimated:YES completion:nil];
    if (result == MessageComposeResultSent) {
        [TrackingUtils trackEvent:EVENT_EMOJI_INVITE_SENT properties:nil];
        [ApiManager unlockEmoji];
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        [TrackingUtils trackEvent:EVENT_EMOJI_INVITE_CANCELED properties:nil];
    }
}

@end
