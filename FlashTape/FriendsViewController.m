
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

#import "CreateMessageTableViewCell.h"
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
@property (strong, nonatomic) User *friendToDetail;
@property (strong, nonatomic) NSDictionary *messagesDictionnary;

@end

@implementation FriendsViewController {
    BOOL _expandMyStory;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Some init
    _expandMyStory = NO;
    [self doBackgroundColorAnimation];
    self.colorView.alpha = 0.5;
    self.messagesDictionnary = [NSDictionary new];
    
    // Retrieve Messages Locally
    [self createMessagesDictionnaryAndReload:[DatastoreUtils getUnreadMessagesLocally]];
    
    // Refresh current User posts
    self.currentUserPosts = [NSMutableArray arrayWithArray:[DatastoreUtils getVideoLocallyFromUsers:@[[User currentUser]]]];
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
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(retrieveUnreadMessages)
                                                 name:@"new_message"
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.friendsTableView reloadData];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSString * segueName = segue.identifier;
    if ([segueName isEqualToString: @"Find By Username From Friends"]) {
        ((FriendsViewController *) [segue destinationViewController]).friends = self.friends;
    }
}

// --------------------------------------------
#pragma mark - Actions
// --------------------------------------------

- (void)dismissFriendsController {
    [self.delegate hideUIElementOnCamera:NO];
    
    NSInteger count = 0;
    for (NSString *key in self.messagesDictionnary) {
        count += ((NSMutableArray *)self.messagesDictionnary[key]).count;
    }
    [self.delegate setMessagesLabel:count];
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (IBAction)closeButtonClicked:(id)sender {
    [self dismissFriendsController];
}

// Send message
- (void)sendMessage:(NSString *)text {
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    Message *message = [Message createMessageWithContent:text receiver:self.friendToDetail];
    [ApiManager sendMessage:message
                    success:^{
                        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
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
    if ([self isCurrentUserSection:section]) {
        return 1 + (_expandMyStory ? self.currentUserPosts.count : 0);
    } else {
        NSArray *messages;
        User *friend = (User *)self.friends[section];
        BOOL isSelected = self.friendToDetail && self.friendToDetail == friend;
        if (isSelected) {
            messages = self.messagesDictionnary[friend.objectId];
        }
        return 1 + (messages ? messages.count : 0) + (isSelected ? 1 : 0);
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self isCurrentUserUserCell:indexPath] || [self isFriendUserCell:indexPath]) {
        // Data
        FriendTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FriendCell"];
        User *friend = (User *)self.friends[indexPath.section];
        NSArray *viewerIdsArray = (self.currentUserPosts && self.currentUserPosts.count > 0) ? ((VideoPost *)self.currentUserPosts.lastObject).viewerIdsArray : nil;
        BOOL hasSeenVideo = (viewerIdsArray) ? ([viewerIdsArray indexOfObject:friend.objectId] != NSNotFound) : NO;
        NSInteger messageCount = self.messagesDictionnary[friend.objectId] ? ((NSArray *)self.messagesDictionnary[friend.objectId]).count : 0;
        
        // Create cell
        [cell initWithName:friend.flashUsername
                     score:[NSString stringWithFormat:@"%lu",(long)(friend.score ? friend.score : 0)]
             hasSeenVideos:hasSeenVideo
             isCurrentUser:[self isCurrentUserUserCell:indexPath]
          newMessagesCount:messageCount];
        cell.delegate = self;
        return cell;
    } else if ([self isCurrentUserPostCell:indexPath]) {
        VideoTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"VideoCell"];
        VideoPost *post = (VideoPost *)self.currentUserPosts[self.currentUserPosts.count - indexPath.row];
        BOOL showViewers = NO;
        NSMutableArray *names = [NSMutableArray new];
        NSArray *viewIdsArray = [post viewerIdsArrayWithoutPoster];
        if (post == self.postToDetail) {
            showViewers = YES;
            for (User *friend in self.friends) {
                if ([viewIdsArray indexOfObject:friend.objectId] != NSNotFound) {
                    [names addObject:friend.flashUsername ? friend.flashUsername : @"?"];
                }
            }
        }
        [cell initWithPost:post detailedState:showViewers viewerNames:names];
        cell.delegate = self;
        return cell;
    } else if ([self isFriendMessageCell:indexPath]) {
        User *friend = (User *)self.friends[indexPath.section];
        NSMutableArray *messages = self.messagesDictionnary[friend.objectId];
        Message *message = (messages && messages.count > 0) ? (Message *)messages[0] : nil;
        if (message) {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MessageReceivedCell"];
            cell.textLabel.text = message.messageContent;

            // unpin / delete / unread
            [ApiManager markMessageAsRead:message
                                  success:nil
                                  failure:nil];
            [messages removeObject:message];
            return cell;
        } else { // todo BT make robust
            CreateMessageTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CreateMessageCell"];
            [cell initWithDelegate:self];
            return cell;
        }
    } else {
        return [UITableViewCell new];
    }
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self isCurrentUserUserCell:indexPath] || [self isFriendUserCell:indexPath]) {
        return 80;
    } else if ([self isCurrentUserPostCell:indexPath]) {
        VideoPost *post = (VideoPost *)self.currentUserPosts[self.currentUserPosts.count - indexPath.row];
        return (post == self.postToDetail) ? 44 + [post viewerIdsArrayWithoutPoster].count * 20 : 44;
    } else if ([self isFriendMessageCell:indexPath]) {
        return 40;
    } else {
        // should not happen
        return 44;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self isCurrentUserUserCell:indexPath]) {
        _expandMyStory = !_expandMyStory;
        self.postToDetail = nil;
        self.friendToDetail = nil;
        [self.friendsTableView reloadData];
    } else if ([self isCurrentUserPostCell:indexPath]) {
        VideoPost *post = (VideoPost *)self.currentUserPosts[self.currentUserPosts.count - indexPath.row];
        self.postToDetail = (post == self.postToDetail) ? nil : post;
        [self reloadCurrentUserSection];
    } else if ([self isFriendUserCell:indexPath]) {
        _expandMyStory = NO;
        self.postToDetail = nil;
        User *friend = (User *)self.friends[indexPath.section];
        if (self.friendToDetail && self.friendToDetail == friend) {
            self.friendToDetail = nil;
        } else {
            self.friendToDetail = friend;
        }
        [self.friendsTableView reloadData];
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

// --------------------------------------------
#pragma mark - Messages
// --------------------------------------------
- (void)createMessagesDictionnaryAndReload:(NSArray *)unreadMessages {
    NSMutableDictionary *messagesDictionary = [NSMutableDictionary new];
    for (Message *message in unreadMessages) {
        NSMutableArray *messageArray = [messagesDictionary objectForKey:message.sender.objectId];
        if (messageArray) {
            [messageArray addObject:message];
        } else {
            [messagesDictionary setObject:[NSMutableArray arrayWithObject:message] forKey:message.sender.objectId];
        }
    }
    self.messagesDictionnary = messagesDictionary;
    [self.friendsTableView reloadData];
}

- (void)retrieveUnreadMessages {
    [ApiManager retrieveUnreadMessagesAndExecuteSuccess:^(NSArray *messages) {
        [self createMessagesDictionnaryAndReload:messages];
    } failure:nil];
}

// --------------------------------------------
#pragma mark - Cell Type
// --------------------------------------------
- (BOOL)isCurrentUserSection:(NSInteger)section {
    return (User *)self.friends[section] == [User currentUser];
}

- (BOOL)isCurrentUserUserCell:(NSIndexPath *)indexPath {
    return [self isCurrentUserSection:indexPath.section] && indexPath.row == 0;
}

- (BOOL)isFriendUserCell:(NSIndexPath *)indexPath {
    return indexPath.row == 0 && ![self isCurrentUserSection:indexPath.section];
}

- (BOOL)isCurrentUserPostCell:(NSIndexPath *)indexPath {
    return indexPath.row != 0 && [self isCurrentUserSection:indexPath.section];
}

- (BOOL)isFriendMessageCell:(NSIndexPath *)indexPath {
    return indexPath.row != 0 && ![self isCurrentUserSection:indexPath.section];
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
    AVPlayerItem *pi = [VideoUtils createAVPlayerItemWithVideoPosts:self.currentUserPosts
                                          andFillObservedTimesArray:nil];
    [VideoUtils saveVideoCompositionToCameraRoll:pi.asset success:^{
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


// --------------------------------------------
#pragma mark - UI
// --------------------------------------------
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

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

// ----------------------------------------------------------
#pragma mark Keyboard
// ----------------------------------------------------------
// Move up create comment view on keyboard will show
- (void)keyboardWillShow:(NSNotification *)notification {
    // todo BT
    // ensure create message cell is visible
    [KeyboardUtils changeFrameOfView:self.friendsTableView whenKeyboardMoveNotification:notification];
}

// Move down create comment view on keyboard will hide
- (void)keyboardWillHide:(NSNotification *)notification {
    [KeyboardUtils changeFrameOfView:self.friendsTableView whenKeyboardMoveNotification:notification];
}
@end
