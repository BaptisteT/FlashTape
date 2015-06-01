
//
//  FriendsViewController.m
//  FlashTape
//
//  Created by Baptiste Truchot on 5/13/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
#import "ApiManager.h"
#import "DatastoreUtils.h"
#import "Message.h"
#import "User.h"
#import "VideoPost.h"

#import "FriendsViewController.h"
#import "FriendTableViewCell.h"
#import "VideoTableViewCell.h"

#import "ColorUtils.h"
#import "ConstantUtils.h"
#import "GeneralUtils.h"
#import "KeyboardUtils.h"
#import "MBProgressHUD.h"
#import "TrackingUtils.h"
#import "VideoUtils.h"

@interface FriendsViewController ()
@property (weak, nonatomic) IBOutlet UILabel *scoreLabel;
@property (weak, nonatomic) IBOutlet UITableView *friendsTableView;
@property (strong, nonatomic) IBOutlet UIView *colorView;
@property (strong, nonatomic) IBOutlet UIButton *inviteButton;
@property (strong, nonatomic) NSMutableArray *currentUserPosts;
@property (weak, nonatomic) VideoPost *postToDelete;
@property (weak, nonatomic) VideoPost *postToDetail;

// Message
@property (weak, nonatomic) IBOutlet UIView *messageContainerView;
@property (weak, nonatomic) IBOutlet UITextView *messageTextView;
@property (weak, nonatomic) IBOutlet UIButton *sendButton;
@property (weak, nonatomic) User *messageReceiver;


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

    // Text View
    self.messageTextView.delegate = self;
    
    // Labels
    [self.inviteButton setTitle:NSLocalizedString(@"friend_controller_title", nil) forState:UIControlStateNormal];
    self.scoreLabel.text = NSLocalizedString(@"friend_score_label", nil);
    [self.sendButton setTitle:NSLocalizedString(@"send_button", nil) forState:UIControlStateNormal];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(dismissFriendsController)
                                                 name: UIApplicationDidEnterBackgroundNotification
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

// To avoid layout bug
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.messageContainerView.translatesAutoresizingMaskIntoConstraints = YES;
}

// --------------------------------------------
#pragma mark - Actions
// --------------------------------------------

- (void)dismissFriendsController {
    [self.delegate hideUIElementOnCamera:NO];
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (IBAction)closeButtonClicked:(id)sender {
    [self dismissFriendsController];
}

// Send message
- (IBAction)sendMessageButtonClicked:(id)sender {
    if (self.messageTextView.text.length == 0) {
        return;
    }
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    Message *message = [Message createMessageWithContent:self.messageTextView.text receiver:self.messageReceiver];
    [ApiManager sendMessage:message
                    success:^{
                        // todo BT
                    } failure:^(NSError *error) {
                        // todo BT handle error
                    }];
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
        cell.accessoryType = ([User currentUser] == friend && !_expandMyStory) ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
        return cell;
    } else {
        VideoTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"VideoCell"];
        VideoPost *post = (VideoPost *)self.currentUserPosts[self.currentUserPosts.count - indexPath.row];
        BOOL showViewers = NO;
        NSMutableArray *names = [NSMutableArray new];
        NSArray *viewIdsArray = [post viewerIdsArrayWithoutPoster];
        if (post == self.postToDetail) {
            showViewers = YES;
            for (User *friend in self.friends) {
                if ([viewIdsArray indexOfObject:friend.objectId] != NSNotFound) {
                    [names addObject:self.contactDictionnary[friend.username]];
                }
            }
        }
        [cell initWithPost:post detailedState:showViewers viewerNames:names];
        cell.delegate = self;
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
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
        VideoPost *post = (VideoPost *)self.currentUserPosts[self.currentUserPosts.count - indexPath.row];
        return (post == self.postToDetail) ? 44 + [post viewerIdsArrayWithoutPoster].count * 20 : 44;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.messageTextView isFirstResponder]) {
        // If opened, we close keyboard
        [self.messageTextView resignFirstResponder];
    } else {
        if (indexPath.row == 0) {
            // Current user : show / hide story
            if (indexPath.section == 0) {
                _expandMyStory = !_expandMyStory;
                [self reloadCurrentUserSection];
            } else {
                // todo BT
                // prepare message / or read
                self.messageReceiver = (User *)self.friends[indexPath.section];
                [self.messageTextView becomeFirstResponder];
            }
        } else {
            VideoPost *post = (VideoPost *)self.currentUserPosts[self.currentUserPosts.count - indexPath.row];
            self.postToDetail = (post == self.postToDetail) ? nil : post;
            [self reloadCurrentUserSection];
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
#pragma mark - Friend TVC Delegate
// --------------------------------------------
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

// See my story
//        self.view.userInteractionEnabled = NO;
//        NSArray *videos = [DatastoreUtils getVideoLocallyFromUser:(User *)self.friends[indexPath.section]];
//        if (!videos || videos.count == 0) {
//            [tableView deselectRowAtIndexPath:indexPath animated:YES];
//            self.view.userInteractionEnabled = YES;
//        } else {
//            [self dismissFriendsController];
//            [self.delegate playOneFriendVideos:videos];
//        }

// --------------------------------------------
#pragma mark - Video TVC Delegate
// --------------------------------------------
- (void)deleteButtonClicked:(VideoPost *)post {
    self.postToDelete = post;
    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"delete_flash_confirm_title", nil)
                               message:NSLocalizedString(@"delete_flash_confirm_message", nil)
                               delegate:self
                      cancelButtonTitle:NSLocalizedString(@"cancel_button_title", nil)
                      otherButtonTitles:NSLocalizedString(@"delete_flash_ok_button", nil), nil] show];
}

// --------------------------------------------
#pragma mark - UIAlertView Delegate
// --------------------------------------------
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"delete_flash_ok_button", nil)]) {
        if (self.postToDelete) {
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            [ApiManager deletePost:self.postToDelete
                           success:^{
                               [self.currentUserPosts removeObject:self.postToDelete];
                               [self.delegate removeVideoFromVideosArray:self.postToDelete];
                               [MBProgressHUD hideAllHUDsForView:self.view animated:NO];
                               self.postToDelete = nil;
                               [self reloadCurrentUserSection];
                           } failure:^(NSError *error) {
                               [MBProgressHUD hideAllHUDsForView:self.view animated:NO];
                               [GeneralUtils showAlertMessage:NSLocalizedString(@"delete_flash_error_message", nil) withTitle:NSLocalizedString(@"delete_flash_error_title", nil)];
                           }];
        }
    }
}

// ----------------------------------------------------------
#pragma mark TextView delegate
// ----------------------------------------------------------
// Can not jump first line
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        return NO;
    }
    if ([textView.text stringByReplacingCharactersInRange:range withString:text].length > kMaxMessageLength) {
        return NO;
    }
    return YES;
}

// Modify size of text view and container dynamically
- (void)textViewDidChange:(UITextView *)textView
{
    // Change color of post button
    [self setPostButtonTitleColor];
}


// --------------------------------------------
#pragma mark - UI
// --------------------------------------------
// Set post button title (white if any text, pink otherwise)
- (void)setPostButtonTitleColor {
    UIColor *postButtonColor;
    if ([self.messageTextView.text isEqualToString:@""]) {
        postButtonColor = [UIColor lightGrayColor];
    } else {
        postButtonColor = [UIColor blackColor];
    }
    [self.sendButton setTitleColor:postButtonColor forState:UIControlStateNormal];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

// Background Color Cycle
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

// ----------------------------------------------------------
#pragma mark Keyboard
// ----------------------------------------------------------
// Move up create comment view on keyboard will show
- (void)keyboardWillShow:(NSNotification *)notification {
    [KeyboardUtils pushUpTopView:self.messageContainerView whenKeyboardWillShowNotification:notification];
}

// Move down create comment view on keyboard will hide
- (void)keyboardWillHide:(NSNotification *)notification {
    [KeyboardUtils pushDownTopView:self.messageContainerView whenKeyboardWillhideNotification:notification];
}
@end
