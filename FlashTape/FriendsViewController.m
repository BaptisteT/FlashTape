
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

@interface FriendsViewController ()
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) NSArray *friends;
@property (weak, nonatomic) IBOutlet UITableView *friendsTableView;
@end

@implementation FriendsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
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
    self.titleLabel.text = NSLocalizedString(@"friend_controller_title", nil);
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(dismissFriendsController)
                                                 name: UIApplicationDidEnterBackgroundNotification
                                               object: nil];
}

- (void)dismissFriendsController {
    [self dismissViewControllerAnimated:NO completion:nil];
    [self.delegate hideUIElementOnCamera:NO];
}

- (IBAction)closeButtonClicked:(id)sender {
    [self dismissFriendsController];
}

// --------------------------------------------
#pragma mark - Tableview
// --------------------------------------------
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.friends.count + 1;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    if (indexPath.row == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"InviteFriendsCell"];
        cell.textLabel.text = NSLocalizedString(@"invite_friends_cell_title", nil);
        cell.textLabel.textColor = [ColorUtils orange];
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"FriendCell"];
        cell.backgroundColor = [UIColor clearColor];
        User *friend = (User *)self.friends[indexPath.row -1];
        cell.textLabel.text = self.contactDictionnary[friend.username];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"Score : %lu",friend.score ? friend.score : 0];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
//        [self showFBInviteDialog];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

// --------------------------------------------
#pragma mark - FB App invite
// --------------------------------------------
- (void)showFBInviteDialog {
    FBSDKAppInviteContent *content =[[FBSDKAppInviteContent alloc] init];
    content.appLinkURL = [NSURL URLWithString:kFlashTapeAppLinkUrl];
    //optionally set previewImageURL
//    content.previewImageURL = [NSURL URLWithString:@"https://www.mydomain.com/my_invite_image.jpg"];
    
    // present the dialog. Assumes self implements protocol `FBSDKAppInviteDialogDelegate`
    [FBSDKAppInviteDialog showWithContent:content
                                 delegate:self];
}

- (void)appInviteDialog:(FBSDKAppInviteDialog *)appInviteDialog didFailWithError:(NSError *)error {
    // todo bt
}

- (void)appInviteDialog:(FBSDKAppInviteDialog *)appInviteDialog didCompleteWithResults:(NSDictionary *)results  {
    // todo bt
}

// --------------------------------------------
#pragma mark - Details
// --------------------------------------------

- (BOOL)prefersStatusBarHidden {
    return YES;
}

@end
