
//
//  FriendsViewController.m
//  FlashTape
//
//  Created by Baptiste Truchot on 5/13/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
#import "ApiManager.h"
#import "User.h"

#import "FriendsViewController.h"

#import "ColorUtils.h"
#import "ConstantUtils.h"
#import "GeneralUtils.h"
#import "TrackingUtils.h"

@interface FriendsViewController ()
@property (weak, nonatomic) IBOutlet UILabel *scoreLabel;
@property (strong, nonatomic) NSArray *friends;
@property (weak, nonatomic) IBOutlet UITableView *friendsTableView;
@property (strong, nonatomic) IBOutlet UIView *colorView;
@property (strong, nonatomic) IBOutlet UIButton *inviteButton;
@end

@implementation FriendsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self doBackgroundColorAnimation];
    self.colorView.alpha = 0.5;
    
    // Tableview
    self.friendsTableView.dataSource = self;
    self.friendsTableView.delegate = self;
    self.friendsTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    self.friends = [NSArray new];
    [ApiManager getListOfFriends:[self.contactDictionnary allKeys]
                         success:^(NSArray *friends) {
                             self.friends = friends;
                             [self.friendsTableView reloadData];
                         } failure:^(NSError *error) {
                             // todo bt handle error
                         }];
    
    // Labels
    [self.inviteButton setTitle:NSLocalizedString(@"friend_controller_title", nil) forState:UIControlStateNormal];
    self.scoreLabel.text = NSLocalizedString(@"friend_score_label", nil);
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(dismissFriendsController)
                                                 name: UIApplicationDidEnterBackgroundNotification
                                               object: nil];
}

- (void)dismissFriendsController {
    [self.delegate hideUIElementOnCamera:NO];
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (IBAction)closeButtonClicked:(id)sender {
    [self dismissFriendsController];
}

// --------------------------------------------
#pragma mark - Tableview
// --------------------------------------------
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.friends.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    cell = [tableView dequeueReusableCellWithIdentifier:@"FriendCell"];
    cell.backgroundColor = [UIColor clearColor];
    User *friend = (User *)self.friends[indexPath.row];
    cell.textLabel.text = self.contactDictionnary[friend.username];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"Score : %lu",(long)(friend.score ? friend.score : 0)];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu",(long)(friend.score ? friend.score : 0)];
    return cell;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

-(void)viewDidLayoutSubviews
{
    if ([self.friendsTableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.friendsTableView setSeparatorInset:UIEdgeInsetsZero];
    }
    
    if ([self.friendsTableView
         respondsToSelector:@selector(setLayoutMargins:)]) {
        [self.friendsTableView setLayoutMargins:UIEdgeInsetsZero];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
//    if (indexPath.row == 0) {
//        [tableView deselectRowAtIndexPath:indexPath animated:YES];
//    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
        return 80;
}

// ----------------------------------------------------------
#pragma mark SMS controller
// ----------------------------------------------------------
- (IBAction)inviteButtonClicked:(id)sender{
    [TrackingUtils trackInviteButtonClicked];
    
    // Redirect to sms
    if(![MFMessageComposeViewController canSendText]) {
        [GeneralUtils showMessage:NSLocalizedString(@"no_sms_error_message", nil) withTitle:nil];
        return;
    }
    MFMessageComposeViewController *messageController = [[MFMessageComposeViewController alloc] init];
    messageController.messageComposeDelegate = self;
    [messageController setBody:[NSString stringWithFormat:NSLocalizedString(@"sharing_wording", nil),kFlashTapeAppStoreLink]];
    [self presentViewController:messageController animated:YES completion:nil];
}
// Dismiss message after finish
- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult) result
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

// --------------------------------------------
#pragma mark - FB App invite (not used today)
// --------------------------------------------
- (void)showFBInviteDialog {
    FBSDKAppInviteContent *content =[[FBSDKAppInviteContent alloc] init];
    content.appLinkURL = [NSURL URLWithString:kFlashTapeAppLinkUrl];
    //optionally set previewImageURL
    content.previewImageURL = [NSURL URLWithString:@"https://www.mydomain.com/my_invite_image.jpg"];
    
    // present the dialog. Assumes self implements protocol `FBSDKAppInviteDialogDelegate`
    [FBSDKAppInviteDialog showWithContent:content
                                 delegate:self];
}

- (void)appInviteDialog:(FBSDKAppInviteDialog *)appInviteDialog didFailWithError:(NSError *)error {
}

- (void)appInviteDialog:(FBSDKAppInviteDialog *)appInviteDialog didCompleteWithResults:(NSDictionary *)results  {
}

// --------------------------------------------
#pragma mark - Details
// --------------------------------------------

- (BOOL)prefersStatusBarHidden {
    return YES;
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
        [self.inviteButton setTitleColor:[colors objectAtIndex:i] forState:UIControlStateNormal];
    } completion:^(BOOL finished) {
        ++i;
        [self doBackgroundColorAnimation];
    }];
    
}


@end
