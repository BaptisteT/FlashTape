//
//  ABFlashersViewController.m
//  FlashTape
//
//  Created by Baptiste Truchot on 6/28/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
#import "Branch.h"

#import "ABContact.h"
#import "ApiManager.h"
#import "DatastoreUtils.h"
#import "User.h"
#import "ColorUtils.h"

#import "FirstTimeAddFriendsViewController.h"

#import "AddressbookUtils.h"
#import "MBProgressHUD.h"
#import "VideoViewController.h"

@interface FirstTimeAddFriendsViewController ()

@property (strong, nonatomic) NSDictionary *contactDictionnary;
@property (weak, nonatomic) IBOutlet UIButton *addFriendsButton;
@property (weak, nonatomic) IBOutlet UITableView *flashersTableView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) NSMutableArray *flashersToAddArray;
@property (strong, nonatomic) IBOutlet UIView *colorTopView;

@property (strong, nonatomic) NSMutableArray *abContactArray;


@end

@implementation FirstTimeAddFriendsViewController

// ----------------------------------------------------------
#pragma mark Life cycle
// ----------------------------------------------------------

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Array
    if (!self.flashersArray) {
        self.flashersArray = [NSArray new];
    }
    self.flashersToAddArray = [NSMutableArray arrayWithArray:self.flashersArray];
    
    // Get addressbook contacts
    self.contactDictionnary = [AddressbookUtils getContactDictionnary];
    
    // Fill Contacts
    [DatastoreUtils  getAllABContactsLocallySuccess:^(NSArray *contacts) {
        self.abContactArray = [NSMutableArray arrayWithArray:[ABContact sortABContacts:contacts contactDictionnary:self.contactDictionnary]];
        [self.flashersTableView reloadData];
    } failure:nil];
    
    // Tableview
    self.flashersTableView.dataSource = self;
    self.flashersTableView.delegate = self;
    self.flashersTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    // Title
    self.titleLabel.numberOfLines = 0;
    self.titleLabel.text = self.flashersArray.count > 0 ? [NSString stringWithFormat:NSLocalizedString(@"flashers_found_label", nil),self.flashersArray.count] : NSLocalizedString(@"no_flashers_found_label", nil);
    
    // Button
    [self.addFriendsButton setTitle:NSLocalizedString(@"add_friends_button",nil) forState:UIControlStateNormal];
    
    //Status Bar
    [self setNeedsStatusBarAppearanceUpdate];
    
    //Color background
    [self doBackgroundColorAnimation];
}

-(UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent; // Set status bar color to white
}

- (void)navigateToVideoController {
    if (self.initialViewController) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"retrieve_following"
                                                            object:nil
                                                          userInfo:nil];
        // dismiss modally
        [self.initialViewController dismissViewControllerAnimated:NO completion:nil];
    } else {
        [self performSegueWithIdentifier:@"Video From ABFlashers" sender:nil];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSString * segueName = segue.identifier;
    if ([segueName isEqualToString: @"Video From ABFlashers"]) {
        ((VideoViewController *) [segue destinationViewController]).isSignup = true;
    }
}

// ----------------------------------------------------------
#pragma mark Actions
// ----------------------------------------------------------

- (IBAction)addFriendsButtonClicked:(id)sender {
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [ApiManager createRelationWithFollowings:self.flashersToAddArray
                                     success:^{
                                         [MBProgressHUD hideAllHUDsForView:self.view animated:NO];
                                         [self navigateToVideoController];
                                     } failure:^(NSError *error) {
                                         [MBProgressHUD hideAllHUDsForView:self.view animated:NO];
                                         [self navigateToVideoController];
                                     }];
}

// ----------------------------------------------------------
#pragma mark Tableview
// ----------------------------------------------------------
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1 + (self.abContactArray.count > 0 ? 1 : 0);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return section == 0 ? self.flashersArray.count : self.abContactArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 58;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath  {
    if (indexPath.section == 0) {
        ABFlasherTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ABFlasherTableViewCell"];
        User *user = (User *)[self.flashersArray objectAtIndex:indexPath.row];
        [cell initWithUser:user name:self.contactDictionnary[user.username] state:[self.flashersToAddArray containsObject:user]];
        cell.delegate = self;
        return cell;
    } else {
        InviteContactTableViewCell *cell = (InviteContactTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"InviteContactTableViewCell"];
        if (!cell) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"InviteContactTableViewCell" owner:self options:nil];
            cell = [nib objectAtIndex:0];
            cell.delegate = self;
        }
        ABContact *contact = (ABContact *)self.abContactArray[indexPath.row];
        [cell initWithName:self.contactDictionnary[contact.number] contact:contact indexPath:indexPath];
        return cell;
    }
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return nil;
    } else {
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 80)];
        view.backgroundColor = [UIColor whiteColor];
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 40, tableView.frame.size.width, 40)];
        [label setFont:[UIFont fontWithName:@"NHaasGroteskDSPro-55Md" size:20]];
        label.textAlignment = NSTextAlignmentCenter;
        label.backgroundColor = [UIColor lightGrayColor];
        label.textColor = [UIColor whiteColor];
        label.text = self.flashersArray.count > 0 ? NSLocalizedString(@"flashers_invite_section_title", nil) : NSLocalizedString(@"no_flasher_invite_section_title", nil);
        [view addSubview:label];
        return view;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return 0;
    } else {
        return 80;
    }
}

// ----------------------------------------------------------
#pragma mark ABFlasherTableViewCell delegate
// ----------------------------------------------------------
- (void)addUserToFlasherToAdd:(User *)user {
    if (![self.flashersToAddArray containsObject:user]) {
        [self.flashersToAddArray addObject:user];
    }
}

- (void)removeUserFromFlasherToAdd:(User *)user {
    [self.flashersToAddArray removeObject:user];
}

// ----------------------------------------------------------
#pragma mark InviteContactTVC delegate
// ----------------------------------------------------------
- (void)inviteUser:(ABContact *)contact
{
    NSString *name = self.contactDictionnary[contact.number];
    NSString *number = contact.number;
    
    [[Branch getInstance] getShortURLWithParams:@{@"referredName": name, @"referredNumber": number, @"referringUsername":[User currentUser].flashUsername, @"referringUserId":[User currentUser].objectId} andChannel:@"sms" andFeature:BRANCH_FEATURE_TAG_SHARE andCallback:^(NSString *url, NSError *error) {
        
        [ApiManager sendInviteTo:number
                            name:name ? [name componentsSeparatedByString:@" "].firstObject : @""
                       inviteURL:url
                         success:nil
                         failure:nil];
    }];
    
    NSInteger row = [self.abContactArray indexOfObject:contact];
    
    if (row != NSNotFound) {
        [self.abContactArray removeObject:contact];
        
        NSIndexPath *index = [NSIndexPath indexPathForRow:row inSection:1];
        [self.flashersTableView beginUpdates];
        [self.flashersTableView deleteRowsAtIndexPaths:@[index] withRowAnimation:UITableViewRowAnimationFade];
        [self.flashersTableView endUpdates];
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
        self.colorTopView.backgroundColor = [colors objectAtIndex:i];
        [self.addFriendsButton setTitleColor:[colors objectAtIndex:i] forState:UIControlStateNormal];
    } completion:^(BOOL finished) {
        ++i;
        [self doBackgroundColorAnimation];
    }];
}

@end
