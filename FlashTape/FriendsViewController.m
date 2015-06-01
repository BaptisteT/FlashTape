
//
//  FriendsViewController.m
//  FlashTape
//
//  Created by Baptiste Truchot on 5/13/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
#import "ApiManager.h"
#import "DatastoreUtils.h"
#import "User.h"
#import "VideoPost.h"

#import "FriendsViewController.h"
#import "FriendTableViewCell.h"
#import "VideoTableViewCell.h"

#import "ColorUtils.h"
#import "ConstantUtils.h"
#import "GeneralUtils.h"
#import "MBProgressHUD.h"
#import "TrackingUtils.h"
#import "VideoUtils.h"

@interface FriendsViewController ()
@property (weak, nonatomic) IBOutlet UILabel *scoreLabel;
@property (weak, nonatomic) IBOutlet UITableView *friendsTableView;
@property (strong, nonatomic) IBOutlet UIView *colorView;
@property (strong, nonatomic) IBOutlet UIButton *inviteButton;

@property (strong, nonatomic) NSMutableArray *currentUserPosts;

@end

@implementation FriendsViewController {
    BOOL _expandMyStory;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _expandMyStory = NO;
    [self doBackgroundColorAnimation];
    self.colorView.alpha = 0.5;
    
    // Refresh current User posts
    self.currentUserPosts = [NSMutableArray arrayWithArray:[DatastoreUtils getVideoLocallyFromUser:[User currentUser]]];
    [VideoPost fetchAllInBackground:self.currentUserPosts block:^(NSArray *objects, NSError *error) {
        [self.friendsTableView reloadData];
    }];
    
    // Tableview
    self.friendsTableView.dataSource = self;
    self.friendsTableView.delegate = self;
    self.friendsTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    if ([self.friendsTableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.friendsTableView setSeparatorInset:UIEdgeInsetsZero];
    }
    if ([self.friendsTableView respondsToSelector:@selector(setLayoutMargins:)]) {
        [self.friendsTableView setLayoutMargins:UIEdgeInsetsZero];
    }

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
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.friends.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ((User *)self.friends[section] == [User currentUser]) {
        return 1 + (_expandMyStory ? self.currentUserPosts.count : 0);
    } else {
        return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        FriendTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FriendCell"];
        User *friend = (User *)self.friends[indexPath.section];
        
        NSArray *viewerIdsArray = (self.currentUserPosts && self.currentUserPosts.count > 0) ? ((VideoPost *)self.currentUserPosts.lastObject).viewerIdsArray : nil;
        BOOL hasSeenVideo = (viewerIdsArray) ? ([viewerIdsArray indexOfObject:friend.objectId] != NSNotFound) : NO;
        
        [cell initWithName:self.contactDictionnary[friend.username]
                     score:[NSString stringWithFormat:@"%lu",(long)(friend.score ? friend.score : 0)]
             hasSeenVideos:hasSeenVideo
             isCurrentUser:([User currentUser] == friend)];
        cell.delegate = self;
        return cell;
    } else {
        VideoTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"VideoCell"];
        VideoPost *post = (VideoPost *)self.currentUserPosts[self.currentUserPosts.count - indexPath.row];
        [cell initWithPost:post];
        cell.delegate = self;
        return cell;
    }
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        return 80;
    } else {
        return 44;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        self.view.userInteractionEnabled = NO;
        NSArray *videos = [DatastoreUtils getVideoLocallyFromUser:(User *)self.friends[indexPath.section]];
        if (!videos || videos.count == 0) {
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            self.view.userInteractionEnabled = YES;
        } else {
            [self dismissFriendsController];
            [self.delegate playOneFriendVideos:videos];
        }
    }
}

- (void)reloadCurrentUserSection {
    NSInteger section = [self.friends indexOfObject:[User currentUser]];
    if (section != NSNotFound) {
        NSRange range = NSMakeRange(section, 1);
        NSIndexSet *sectionToReload = [NSIndexSet indexSetWithIndexesInRange:range];
        [self.friendsTableView reloadSections:sectionToReload withRowAnimation:UITableViewRowAnimationNone];
    }
}

// ----------------------------------------------------------
#pragma mark SMS controller
// ----------------------------------------------------------
- (IBAction)inviteButtonClicked:(id)sender{
    [TrackingUtils trackInviteButtonClicked];
    
    // Redirect to sms
    if(![MFMessageComposeViewController canSendText]) {
        [GeneralUtils showAlertMessage:NSLocalizedString(@"no_sms_error_message", nil) withTitle:nil];
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

// --------------------------------------------
#pragma mark - Friend TVC Delegate
// --------------------------------------------
- (void)expandCurrentUserStoryButtonClicked {
    _expandMyStory = !_expandMyStory;
    [self reloadCurrentUserSection];
}

- (void)saveCurrentUserStoryButtonClicked {
    AVMutableComposition *compo = [AVMutableComposition new];
    [VideoUtils fillComposition:compo withVideoPosts:self.currentUserPosts];
    [VideoUtils saveVideoCompositionToCameraRoll:compo success:^{
        [self.friendsTableView reloadData];
    } failure:^{
        [self.friendsTableView reloadData];
        [GeneralUtils showAlertMessage:NSLocalizedString(@"save_story_error_message", nil) withTitle:NSLocalizedString(@"save_story_error_title", nil)];
    }];
}

// --------------------------------------------
#pragma mark - Video TVC Delegate
// --------------------------------------------
- (void)deletePost:(VideoPost *)post {
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [ApiManager deletePost:post
                   success:^{
                       [self.currentUserPosts removeObject:post];
                       [self.delegate removeVideoFromVideosArray:post];
                       [MBProgressHUD hideAllHUDsForView:self.view animated:NO];
                       [self reloadCurrentUserSection];
                   } failure:^(NSError *error) {
                       [MBProgressHUD hideAllHUDsForView:self.view animated:NO];
                       [GeneralUtils showAlertMessage:NSLocalizedString(@"delete_flash_error_message", nil) withTitle:NSLocalizedString(@"delete_flash_error_title", nil)];
                   }];
}

@end
