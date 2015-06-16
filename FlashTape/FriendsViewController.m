
//
//  FriendsViewController.m
//  FlashTape
//
//  Created by Baptiste Truchot on 5/13/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
#import <AddressBook/AddressBook.h>

#import "ApiManager.h"
#import "DatastoreUtils.h"
#import "Message.h"
#import "User.h"
#import "VideoPost.h"

#import "FriendsViewController.h"
#import "FriendTableViewCell.h"
#import "ReadMessageViewController.h"
#import "VideoTableViewCell.h"

#import "ColorUtils.h"
#import "ConstantUtils.h"
#import "GeneralUtils.h"
#import "KeyboardUtils.h"
#import "MBProgressHUD.h"
#import "NotifUtils.h"
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
@property (strong, nonatomic) SendMessageViewController *sendMessageController;
@property (strong, nonatomic) NSMutableDictionary *messagesReceivedDictionnary;
@property (strong, nonatomic) NSMutableDictionary *messagesSentDictionnary;
@property (strong, nonatomic) NSMutableArray *followerArray;
@property (strong, nonatomic) User *userToFollowOrBlock;
@property (strong, nonatomic) UIRefreshControl *refreshControl;

@end

@implementation FriendsViewController {
    BOOL _expandMyStory;
    BOOL _stopAnimation;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Some init
    _expandMyStory = NO;
    self.colorView.alpha = 0.5;
    self.messagesReceivedDictionnary = [NSMutableDictionary new];
    self.messagesSentDictionnary = [NSMutableDictionary new];
    self.followerArray = [NSMutableArray new];
    
    // Retrieve Messages Locally
    [self retrieveUnreadMessagesLocally];
    
    // Refresh current User posts
    self.currentUserPosts = [NSMutableArray arrayWithArray:[DatastoreUtils getVideoLocallyFromUsers:@[[User currentUser]]]];
    [VideoPost fetchAllInBackground:self.currentUserPosts block:^(NSArray *objects, NSError *error) {
        [self.friendsTableView reloadData];
    }];
    
    // Tableview
    self.friendsTableView.allowsMultipleSelectionDuringEditing = NO;
    [self.friendsTableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    self.friendsTableView.separatorInset = UIEdgeInsetsZero;
    self.friendsTableView.dataSource = self;
    self.friendsTableView.delegate = self;
    self.friendsTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    if ([self.friendsTableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.friendsTableView setSeparatorInset:UIEdgeInsetsZero];
    }
    if ([self.friendsTableView respondsToSelector:@selector(setLayoutMargins:)]) {
        [self.friendsTableView setLayoutMargins:UIEdgeInsetsZero];
    }
    
    // Refresh control
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.backgroundColor = [UIColor clearColor];
    self.refreshControl.tintColor = [UIColor whiteColor];
    [self.refreshControl addTarget:self
                            action:@selector(retrieveUnreadMessages)
                  forControlEvents:UIControlEventValueChanged];
    [self.friendsTableView addSubview:self.refreshControl];
    
    // Instantiate send message controller
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    self.sendMessageController = [storyboard instantiateViewControllerWithIdentifier:@"SendMessageController"];
    self.sendMessageController.delegate = self;
    
    // Labels
    [self.inviteButton setTitle:NSLocalizedString(@"friend_controller_title", nil) forState:UIControlStateNormal];
    self.scoreLabel.text = NSLocalizedString(@"friend_score_label", nil);
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(retrieveUnreadMessagesLocally)
                                                 name:@"retrieve_message_locally"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reload)
                                                 name:@"reload_friend_tableview"
                                               object:nil];
    
    // If first time, ask access to contact
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {
        [self.delegate parseContactsAndFindFriendsIfAuthNotDetermined];
    }
    // If contact access denied, propose to redirect to settings
    else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusDenied) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"contact_access_error_title",nil)
                                    message:NSLocalizedString(@"contact_access_error_message",nil)
                                   delegate:self
                          cancelButtonTitle:NSLocalizedString(@"later_button",nil)
                          otherButtonTitles:NSLocalizedString(@"ok_button",nil), nil] show];
    }
    // Notif
    else if (![NotifUtils isRegisteredForRemoteNotification]) {
        [NotifUtils registerForRemoteNotif];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Open send message if coming from click on name label
    if (self.friendUsername) {
        for (User *friend in self.friends) {
            if ([friend.flashUsername isEqualToString:self.friendUsername]) {
                [self presentSendViewController:friend];
                self.friendUsername = nil;
                return;
            }
        }
    }
    
    [self setVideoControllerMessageCount];
    [self sortFriendsAndReload];
    
    // background color animation
    _stopAnimation = NO;
    [self doBackgroundColorAnimation];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSString * segueName = segue.identifier;
    if ([segueName isEqualToString: @"Add Username From Friends"]) {
        ((FriendsViewController *) [segue destinationViewController]).friends = self.friends;
    } else if ([segueName isEqualToString: @"Read Message From Friends"]) {
        User *friend = (User *)sender;
        ((ReadMessageViewController *) [segue destinationViewController]).messageSender = friend;
        ((ReadMessageViewController *) [segue destinationViewController]).messagesArray = self.messagesReceivedDictionnary[friend.objectId];
        ((ReadMessageViewController *) [segue destinationViewController]).delegate = self;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    _stopAnimation = YES;
}

// --------------------------------------------
#pragma mark - Actions
// --------------------------------------------

- (void)dismissFriendsController {
    [self.delegate hideUIElementOnCamera:NO];
    
    [self setVideoControllerMessageCount];
    [self.delegate dismissViewControllerAnimated:NO completion:nil];
}

- (IBAction)closeButtonClicked:(id)sender {
    [self dismissFriendsController];
}

- (void)closeReadAndMessageViews {
    if (self.presentedViewController != self) {
        [self dismissViewControllerAnimated:NO completion:nil];
    }
}

- (void)presentSendViewController:(User *)friend {
    self.sendMessageController.messageRecipient = friend;
    [self presentViewController:self.sendMessageController animated:NO completion:nil];
}

// --------------------------------------------
#pragma mark - Message
// --------------------------------------------

// Send message
- (void)sendMessage:(Message *)message {
    // Update last message date
    [message.receiver updateLastMessageDate:[NSDate date]];
    
    // reload this section
    [self reloadSectionOfUser:message.receiver];
    
    [ApiManager sendMessage:message
                    success:^{
                        message.status = kMessageTypeSent;
                        [self reloadSectionOfUser:message.receiver];
                    } failure:^(NSError *error) {
                        message.status = kMessageTypeFailed;
                        [self reloadSectionOfUser:message.receiver];
                    }];
}
// Send message
- (void)sendMessage:(NSString *)text toUser:(User *)user {
    // Create message
    Message *message = [Message createMessageWithContent:text receiver:user];
    message.status = kMessageTypeSending;
    
    // Add message to message sent dic
    NSMutableArray *messageSentArray = [self.messagesSentDictionnary objectForKey:message.receiver.objectId];
    if (messageSentArray) {
        [messageSentArray addObject:message];
    } else {
        [self.messagesSentDictionnary setObject:[NSMutableArray arrayWithObject:message] forKey:message.receiver.objectId];
    }
    [self sendMessage:message];
    [self sortFriendsAndReload];
}

- (void)createMessagesDictionnaryAndReload:(NSArray *)unreadMessages {
    NSMutableDictionary *messagesDictionary = [NSMutableDictionary new];
    for (Message *message in unreadMessages) {
        // Add message to dictionnary
        NSMutableArray *messageArray = [messagesDictionary objectForKey:message.sender.objectId];
        if (messageArray) {
            [messageArray addObject:message];
        } else {
            [messagesDictionary setObject:[NSMutableArray arrayWithObject:message] forKey:message.sender.objectId];
        }
        // Add user to follower if not a friend
        if (![self.friends containsObject:message.sender]) {
            [self.followerArray addObject:message.sender];
        }
    }
    self.messagesReceivedDictionnary = messagesDictionary;
    [self sortFriendsAndReload];
}

- (void)retrieveUnreadMessages {
    [ApiManager retrieveUnreadMessagesAndExecuteSuccess:^(NSArray *messages) {
        [self.refreshControl endRefreshing];
        [self createMessagesDictionnaryAndReload:messages];
    } failure:^(NSError *error) {
        [self.refreshControl endRefreshing];
    }];
}

- (void)retrieveUnreadMessagesLocally {
    [self createMessagesDictionnaryAndReload:[DatastoreUtils getUnreadMessagesLocally]];
}

- (void)setVideoControllerMessageCount {
    NSInteger count = 0;
    for (NSString *key in self.messagesReceivedDictionnary) {
        count += ((NSMutableArray *)self.messagesReceivedDictionnary[key]).count;
    }
    [self.delegate setMessageCount:count];
}

// --------------------------------------------
#pragma mark - Tableview
// --------------------------------------------
- (void)sortFriendsAndReload {
    [self orderFriendsByLastMessageDateAndScore];
    [self.friendsTableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1 + self.friends.count + self.followerArray.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([self isCurrentUserSection:section]) {
        return 1 + (_expandMyStory ? self.currentUserPosts.count : 0);
    } else {
        return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self isAddFriendSection:indexPath.section]) {
        return [tableView dequeueReusableCellWithIdentifier:@"AddFriendCell"];
    } else if ([self isCurrentUserUserCell:indexPath] || [self isFriendUserSection:indexPath.section] || [self isFollowerUserSection:indexPath.section]) {
        // Data
        FriendTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FriendCell"];
        User *friend = [self friendOrFollowerForSection:indexPath.section];
        NSArray *viewerIdsArray = (self.currentUserPosts && self.currentUserPosts.count > 0) ? ((VideoPost *)self.currentUserPosts.lastObject).viewerIdsArray : nil;
        BOOL hasSeenVideo = (viewerIdsArray) ? ([viewerIdsArray indexOfObject:friend.objectId] != NSNotFound) : NO;
        NSInteger messageCount = self.messagesReceivedDictionnary[friend.objectId] ? ((NSArray *)self.messagesReceivedDictionnary[friend.objectId]).count : 0;
        
        // Create cell
        [cell initWithUser:friend
             hasSeenVideos:hasSeenVideo
       unreadMessagesCount:messageCount
         messagesSentArray:self.messagesSentDictionnary[friend.objectId]];
        cell.delegate = self;
        return cell;
    } else if ([self isCurrentUserPostCell:indexPath]) {
        VideoTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"VideoCell"];
        VideoPost *post = (VideoPost *)self.currentUserPosts[self.currentUserPosts.count - indexPath.row];
        BOOL showViewers = NO;
        NSMutableArray *names = [NSMutableArray new];
        showViewers = (post == self.postToDetail);
        [cell initWithPost:post detailedState:showViewers viewerNames:names];
        cell.delegate = self;
        return cell;
    } else {
        NSLog(@"should not happen");
        return [UITableViewCell new];
    }
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self isAddFriendSection:indexPath.section] || [self isCurrentUserUserCell:indexPath] || [self isFriendUserSection:indexPath.section] || [self isFollowerUserSection:indexPath.section]) {
        return 80;
    } else if ([self isCurrentUserPostCell:indexPath]) {
        VideoPost *post = (VideoPost *)self.currentUserPosts[self.currentUserPosts.count - indexPath.row];
        return (post == self.postToDetail) ? kVideoCellHeight + [post viewerIdsArrayWithoutPoster].count * kVideoCellViewerAdditionalHeight : kVideoCellHeight;
    } else {
        // should not happen
        return 50;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self isAddFriendSection:indexPath.section]) {
        [self performSegueWithIdentifier:@"Add Username From Friends" sender:nil];
    } else if ([self isCurrentUserUserCell:indexPath]) {
        [TrackingUtils trackMyStoryClicked];
        _expandMyStory = !_expandMyStory;
        self.postToDetail = nil;
        [self reloadSectionOfUser:[User currentUser]];
    } else if ([self isCurrentUserPostCell:indexPath]) {
        [TrackingUtils trackMyVideoClicked];
        VideoPost *post = (VideoPost *)self.currentUserPosts[self.currentUserPosts.count - indexPath.row];
        self.postToDetail = (post == self.postToDetail) ? nil : post;
        [self reloadSectionOfUser:[User currentUser]];
    } else if ([self isFriendUserSection:indexPath.section]) {
        _expandMyStory = NO;
        self.postToDetail = nil;
        User *friend = [self friendOrFollowerForSection:indexPath.section];

        // Check if we have failure
        NSMutableArray *failedMessageArray = [NSMutableArray new];
        if (self.messagesSentDictionnary[friend.objectId]) {
            for (Message *message in self.messagesSentDictionnary[friend.objectId]) {
                if (message.status == kMessageTypeFailed) {
                    [failedMessageArray addObject:message];
                }
            }
        }
        
        // Resend
        if (failedMessageArray.count > 0) {
            for (Message *message in failedMessageArray) {
                [self sendMessage:message];
            }
        // read
        } else if (self.messagesReceivedDictionnary[friend.objectId] && ((NSArray *)self.messagesReceivedDictionnary[friend.objectId]).count > 0) {
            [self performSegueWithIdentifier:@"Read Message From Friends" sender:friend];
            
        // Send
        } else {
            [self presentSendViewController:friend];
        }
    }
    else if ([self isFollowerUserSection:indexPath.section]) {
        _expandMyStory = NO;
        self.postToDetail = nil;
        self.userToFollowOrBlock = [self friendOrFollowerForSection:indexPath.section];
        // Present alert view
        [[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"follow_or_block_alert_title", nil), self.userToFollowOrBlock.flashUsername]
                                    message:NSLocalizedString(@"follow_or_block_alert_message", nil)
                                   delegate:self
                          cancelButtonTitle:NSLocalizedString(@"block_button", nil)
                          otherButtonTitles:NSLocalizedString(@"follow_button", nil), nil] show];
    }
}

// Edit only friend cells
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self isFriendUserSection:indexPath.section];
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete && [self isFriendUserSection:indexPath.section]) {
        User *friend = [self friendOrFollowerForSection:indexPath.section];
        [self updateRelationshipWithUser:friend block:YES];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return NSLocalizedString(@"block_button", nil);
}

- (void)reloadSectionOfUser:(User *)user {
    NSInteger section = [self sectionForFriend:user];
    if (section != NSNotFound) {
        NSRange range = NSMakeRange(section, 1);
        NSIndexSet *sectionToReload = [NSIndexSet indexSetWithIndexesInRange:range];
        [self.friendsTableView reloadSections:sectionToReload withRowAnimation:UITableViewRowAnimationNone];
    }
}

// --------------------------------------------
#pragma mark - Friends
// --------------------------------------------
// Follow or block user
- (void)updateRelationshipWithUser:(User *)user
                             block:(BOOL)block
{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [ApiManager updateRelationWithFollowing:user
                                      block:block
                                    success:^{
                                        [MBProgressHUD hideHUDForView:self.view animated:YES];
                                        [self.followerArray removeObject:user];
                                        if (block) {
                                            [self.friends removeObject:user];
                                            // remove messages
                                            [self.messagesReceivedDictionnary removeObjectForKey:user.objectId];
                                        } else {
                                            // add to friends
                                            [self.friends addObject:user];
                                        }
                                        [self sortFriendsAndReload];
                                    } failure:^(NSError *error) {
                                        [MBProgressHUD hideHUDForView:self.view animated:YES];
                                        [GeneralUtils showAlertMessage:NSLocalizedString(@"please_try_again", nil) withTitle:NSLocalizedString(@"unexpected_error", nil)];
                                    }];
}

// Order friends
- (void)orderFriendsByLastMessageDateAndScore {
    [self.friends sortUsingComparator:^NSComparisonResult(User *obj1, User *obj2) {
        if (obj1 == [PFUser currentUser]) {
            return NSOrderedAscending;
        } else if (obj2 == [PFUser currentUser]) {
            return NSOrderedDescending;
        } else {
            if (!obj1.lastMessageDate) [obj1 updateLastMessageDate:[NSDate dateWithTimeIntervalSince1970:0]];
            if (!obj2.lastMessageDate) [obj2 updateLastMessageDate:[NSDate dateWithTimeIntervalSince1970:0]];
            if ([obj1.lastMessageDate isEqual:obj2.lastMessageDate]) {
                return obj1.score > obj2.score ? NSOrderedAscending : NSOrderedDescending;
            } else {
                return [obj2.lastMessageDate compare:obj1.lastMessageDate];
            }
        }
    }];
}


// --------------------------------------------
#pragma mark - Cell Type & Logic
// --------------------------------------------
// 1st follower, then friends
- (User *)friendOrFollowerForSection:(NSInteger)section {
    if (section == 0) {
        return nil;
    }
    if (section < self.followerArray.count + 1) {
        return (User *)self.followerArray[section - 1];
    } else if (section < self.followerArray.count + self.friends.count + 1 ) {
        return (User *)self.friends[section - self.followerArray.count - 1];
    } else {
        return nil;
    }
}

- (NSInteger)sectionForFriend:(User *)user {
    return [self.friends indexOfObject:user] + 1 + self.followerArray.count;
}

- (BOOL)isAddFriendSection:(NSInteger)section {
    return section == 0;
}

- (BOOL)isCurrentUserSection:(NSInteger)section {
    return [self friendOrFollowerForSection:section] == [User currentUser];
}

- (BOOL)isCurrentUserUserCell:(NSIndexPath *)indexPath {
    return [self isCurrentUserSection:indexPath.section] && indexPath.row == 0;
}

- (BOOL)isFollowerUserSection:(NSInteger)section {
    return ![self isAddFriendSection:section] && section < self.followerArray.count + 1;
}

- (BOOL)isFriendUserSection:(NSInteger)section {
    return ![self isAddFriendSection:section] && ![self isCurrentUserSection:section] && ![self isFollowerUserSection:section] && (section < self.followerArray.count + self.friends.count + 1);
}

- (BOOL)isCurrentUserPostCell:(NSIndexPath *)indexPath {
    return indexPath.row != 0 && [self isCurrentUserSection:indexPath.section];
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
- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    if (result == MessageComposeResultSent) {
        [TrackingUtils trackInviteSent];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

// --------------------------------------------
#pragma mark - Friend TVC Delegate
// --------------------------------------------
- (void)saveCurrentUserStoryButtonClicked {
    // todo BT
    // anim
    AVPlayerItem *pi = [VideoUtils createAVPlayerItemWithVideoPosts:self.currentUserPosts
                                          andFillObservedTimesArray:nil];
    [VideoUtils saveVideoCompositionToCameraRoll:pi.asset success:^{
        [self.friendsTableView reloadData];
    } failure:^{
        [self.friendsTableView reloadData];
        [GeneralUtils showAlertMessage:NSLocalizedString(@"save_story_error_message", nil) withTitle:NSLocalizedString(@"save_story_error_title", nil)];
    }];
}

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
    if ([alertView.title isEqualToString:NSLocalizedString(@"delete_flash_confirm_title", nil)]) {
        if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"delete_flash_ok_button", nil)]) {
            if (self.postToDelete) {
                [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                [ApiManager deletePost:self.postToDelete
                               success:^{
                                   [self.currentUserPosts removeObject:self.postToDelete];
                                   [self.delegate removeVideoFromVideosArray:self.postToDelete];
                                   [MBProgressHUD hideAllHUDsForView:self.view animated:NO];
                                   self.postToDelete = nil;
                                   [self reloadSectionOfUser:[User currentUser]];
                               } failure:^(NSError *error) {
                                   [MBProgressHUD hideAllHUDsForView:self.view animated:NO];
                                   [GeneralUtils showAlertMessage:NSLocalizedString(@"delete_flash_error_message", nil) withTitle:NSLocalizedString(@"delete_flash_error_title", nil)];
                               }];
            }
        }
    } else if([alertView.message isEqualToString:NSLocalizedString(@"follow_or_block_alert_message", nil)]) {
        // Follow or block user
        BOOL block = [[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"block_button", nil)];
        [self updateRelationshipWithUser:self.userToFollowOrBlock block:block];
        self.userToFollowOrBlock = nil;

    } else if ([alertView.title isEqualToString:NSLocalizedString(@"contact_access_error_title", nil)]) {
        if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"ok_button", nil)]) {
            [GeneralUtils openSettings];
        }
    }
}


// --------------------------------------------
#pragma mark - UI
// --------------------------------------------
// Background Color Cycle
- (void) doBackgroundColorAnimation {
    if (_stopAnimation) {
        return;
    }
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


@end
