
//
//  FriendsViewController.m
//  FlashTape
//
//  Created by Baptiste Truchot on 5/13/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
#import <AddressBook/AddressBook.h>
#import "Branch.h"

#import "ApiManager.h"
#import "DatastoreUtils.h"
#import "Follow.h"
#import "Message.h"
#import "User.h"
#import "VideoPost.h"

#import "ABAccessViewController.h"
#import "AddFriendTableViewCell.h"
#import "FriendsViewController.h"
#import "FriendTableViewCell.h"
#import "ReadMessageViewController.h"
#import "VideoTableViewCell.h"

#import "ColorUtils.h"
#import "ConstantUtils.h"
#import "DesignUtils.h"
#import "GeneralUtils.h"
#import "KeyboardUtils.h"
#import "MBProgressHUD.h"
#import "NotifUtils.h"
#import "TrackingUtils.h"
#import "VideoUtils.h"

@interface FriendsViewController ()
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UITableView *friendsTableView;
@property (strong, nonatomic) IBOutlet UIView *colorView;
@property (strong, nonatomic) NSMutableArray *currentUserPosts;
@property (strong, nonatomic) VideoPost *postToDelete;
@property (strong, nonatomic) NSIndexPath *postToDetailIndexPath;
@property (strong, nonatomic) SendMessageViewController *sendMessageController;
@property (strong, nonatomic) NSMutableDictionary *messagesReceivedDictionnary;
@property (strong, nonatomic) NSMutableDictionary *messagesSentDictionnary;
@property (strong, nonatomic) NSMutableArray *followerRelations;
@property (strong, nonatomic) Follow *selectedRelation;
@property (strong, nonatomic) UIRefreshControl *refreshControl;

@end

@implementation FriendsViewController {
    BOOL _expandMyStory;
    BOOL _stopAnimation;
    BOOL _isSavingStory;
    BOOL _firstViewDidAppear;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Some init
    _firstViewDidAppear = YES;
    self.modalPresentationCapturesStatusBarAppearance = YES;
    _expandMyStory = NO;
    _isSavingStory = NO;
    self.colorView.alpha = 0.5;
    self.messagesReceivedDictionnary = [NSMutableDictionary new];
    self.messagesSentDictionnary = [NSMutableDictionary new];
    self.followerRelations = [NSMutableArray new];
    
    // Labels
    self.titleLabel.text = NSLocalizedString(@"friend_controller_title", nil);
    
    // Notif
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(retrieveUnreadMessagesLocally)
                                                 name:@"retrieve_message_locally"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(sortFriendsAndReload)
                                                 name:@"reload_friend_tableview"
                                               object:nil];
    
    // Get local videos & refresh
    [DatastoreUtils getVideoLocallyFromUsers:@[[User currentUser]]
                                     success:^(NSArray *videos) {
                                         self.currentUserPosts = [NSMutableArray arrayWithArray:videos];
                                         
                                         // todo bt put this in api manager
                                         [VideoPost fetchAllInBackground:self.currentUserPosts block:^(NSArray *objects, NSError *error) {
                                             [self.friendsTableView reloadData];
                                         }];
                                     } failure:nil];
    
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
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Open send message if coming from click on name label
    if (self.friendUsername) {
        for (Follow *follow in self.followingRelations) {
            if ([follow.to.flashUsername isEqualToString:self.friendUsername]) {
                [self presentSendViewController:follow.to];
                self.friendUsername = nil;
                return;
            }
        }
    }
    
    // Retrieve Messages Locally
    [self retrieveUnreadMessagesLocally];
    
    //
    [self setVideoControllerMessageCount];
    
    // background color animation
    _stopAnimation = NO;
    [self doBackgroundColorAnimation];
    
    // Sort and reload
    [self sortFriendsAndReload];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSString * segueName = segue.identifier;
    if ([segueName isEqualToString: @"Add Username From Friends"]) {
        ((FriendsViewController *) [segue destinationViewController]).followingRelations = self.followingRelations;
    } else if ([segueName isEqualToString: @"Read Message From Friends"]) {
        User *friend = (User *)sender;
        ((ReadMessageViewController *) [segue destinationViewController]).messageSender = friend;
        ((ReadMessageViewController *) [segue destinationViewController]).messagesArray = self.messagesReceivedDictionnary[friend.objectId];
        ((ReadMessageViewController *) [segue destinationViewController]).delegate = self;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (_firstViewDidAppear) {
        _firstViewDidAppear = NO;
    
        // if contact not auth, show ab access vc
        if (ABAddressBookGetAuthorizationStatus() != kABAuthorizationStatusAuthorized) {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
            ABAccessViewController *abAccessVC = [storyboard instantiateViewControllerWithIdentifier:@"ABAccessVC"];
            abAccessVC.initialViewController = self;
            [self presentViewController:abAccessVC animated:NO completion:nil];
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillAppear:animated];
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
    // Notif
    if (![NotifUtils isRegisteredForRemoteNotification]) {
        [NotifUtils registerForRemoteNotif];
    }
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
    [self.friendsTableView reloadData];
    [self scrollToTop];
    
    [ApiManager sendMessage:message
                    success:^{
                        message.status = kMessageTypeSent;
                        [self.friendsTableView reloadData];
                    } failure:^(NSError *error) {
                        message.status = kMessageTypeFailed;
                        [self.friendsTableView reloadData];
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
        // Admin message => add flashteam (make sur only once)
        if ([User isAdminUser:message.sender]) {
            BOOL addToArray = YES;
            for (Follow *follow in self.followingRelations) {
                if ([follow.to.objectId isEqualToString:message.sender.objectId]) {
                    addToArray = NO;
                    break;
                }
            }
            if (addToArray) {
                Follow *follow = [Follow createRelationWithFollowing:message.sender];
                [self.followingRelations addObject:follow];
            }
        }
        // Else add user to follower if not a friend
        else if (![self userBelongsToFollowing:message.sender]) {
            Follow *followerRelation = [DatastoreUtils getRelationWithFollower:message.sender following:[User currentUser]];
            if (followerRelation && ![self.followerRelations containsObject:followerRelation]) {
                if (followerRelation.blocked) {
                    [messagesDictionary removeObjectForKey:message.sender.objectId];
                } else {
                    [self.followerRelations addObject:followerRelation];
                }
            }
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
    [DatastoreUtils getUnreadMessagesLocallySuccess:^(NSArray *messages) {
        [self createMessagesDictionnaryAndReload:messages];
    } failure:nil];
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
    return 2 + self.followingRelations.count + self.followerRelations.count;
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
        AddFriendTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AddFriendCell"];
        [cell setNewUserToAddTo:[GeneralUtils getNewUnfollowedFollowerCount] + [GeneralUtils getNewAddressbookFlasherCount]];
        return cell;
    } else if ([self isCurrentUserUserCell:indexPath]) {
        FriendTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FriendCell"];
        [cell InitWithCurrentUser:self.currentUserPosts.count isSaving:_isSavingStory];
        cell.delegate = self;
        return cell;
    } else if ([self isFollowingUserSection:indexPath.section] || [self isFollowerUserSection:indexPath.section]) {
        FriendTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FriendCell"];
        Follow *follow = [self relationForSection:indexPath.section];
        
        BOOL isFollowing = [self isFollowingUserSection:indexPath.section];
        User *friend = isFollowing ? follow.to : follow.from;
        NSArray *viewerIdsArray = (self.currentUserPosts && self.currentUserPosts.count > 0) ? ((VideoPost *)self.currentUserPosts.lastObject).viewerIdsArray : nil;
        BOOL hasSeenVideo = (viewerIdsArray && isFollowing) ? ([viewerIdsArray indexOfObject:friend.objectId] != NSNotFound) : NO;
        NSInteger messageCount = self.messagesReceivedDictionnary[friend.objectId] ? ((NSArray *)self.messagesReceivedDictionnary[friend.objectId]).count : 0;
        
        // Create cell
        [cell initWithUser:friend
             hasSeenVideos:hasSeenVideo
       unreadMessagesCount:messageCount
         messagesSentArray:self.messagesSentDictionnary[friend.objectId]
                     muted:isFollowing && follow.mute == YES];
        cell.delegate = self;
        return cell;
    } else if ([self isCurrentUserPostCell:indexPath]) {
        VideoTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"VideoCell"];
        VideoPost *post = (VideoPost *)self.currentUserPosts[self.currentUserPosts.count - indexPath.row];
        BOOL showViewers = NO;
        NSMutableArray *names = [NSMutableArray new];
        showViewers = [indexPath isEqual:self.postToDetailIndexPath];
        [cell initWithPost:post detailedState:showViewers viewerNames:names];
        cell.delegate = self;
        return cell;
    } else {
        NSLog(@"should not happen");
        return [UITableViewCell new];
    }
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self isAddFriendSection:indexPath.section] || [self isCurrentUserUserCell:indexPath] || [self isFollowingUserSection:indexPath.section] || [self isFollowerUserSection:indexPath.section]) {
        return 80;
    } else if ([self isCurrentUserPostCell:indexPath]) {
        VideoPost *post = (VideoPost *)self.currentUserPosts[self.currentUserPosts.count - indexPath.row];
        return [indexPath isEqual:self.postToDetailIndexPath] ? kVideoCellHeight + [post viewerIdsArrayWithoutPoster].count * kVideoCellViewerAdditionalHeight : kVideoCellHeight;
    } else {
        // should not happen
        return 50;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self isAddFriendSection:indexPath.section]) {
        [self performSegueWithIdentifier:@"Add Username From Friends" sender:nil];
    } else if ([self isCurrentUserUserCell:indexPath]) {
        [TrackingUtils trackEvent:EVENT_ME_STORY_CLICKED properties:nil];
        _expandMyStory = !_expandMyStory;
        self.postToDetailIndexPath = nil;
        [self reloadSection:indexPath.section];
    } else if ([self isCurrentUserPostCell:indexPath]) {
        [TrackingUtils trackEvent:EVENT_ME_VIDEO_CLICKED properties:nil];
        NSArray *pathArray;
        NSIndexPath *previousIndexPath = self.postToDetailIndexPath;
        if (previousIndexPath) {
            if ([indexPath isEqual:previousIndexPath]) {
                self.postToDetailIndexPath = nil;
                pathArray = @[indexPath];
            } else {
                self.postToDetailIndexPath = indexPath;
                pathArray = indexPath.row > previousIndexPath.row ? @[previousIndexPath, indexPath] : @[indexPath, previousIndexPath];
            }
        } else {
            self.postToDetailIndexPath = indexPath;
            pathArray = @[indexPath];
        }
        [self.friendsTableView beginUpdates];
        [self.friendsTableView reloadRowsAtIndexPaths:pathArray withRowAnimation:UITableViewRowAnimationNone];
        [self.friendsTableView endUpdates];
    } else if ([self isFollowingUserSection:indexPath.section]) {
        _expandMyStory = NO;
        self.postToDetailIndexPath = nil;
        Follow *followingRelation = [self relationForSection:indexPath.section];
        User *friend = followingRelation.to;

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
        self.postToDetailIndexPath = nil;
        self.selectedRelation = [self relationForSection:indexPath.section];
        
        // Present alert view
        [[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"follow_or_block_alert_title", nil), self.selectedRelation.from.flashUsername]
                                    message:NSLocalizedString(@"follow_or_block_alert_message", nil)
                                   delegate:self
                          cancelButtonTitle:NSLocalizedString(@"block_button", nil)
                          otherButtonTitles:NSLocalizedString(@"follow_button", nil), nil] show];
    }
}

// Edit only friend cells
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return !IS_IOS_7 && [self isFollowingUserSection:indexPath.section];
}

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self isFollowingUserSection:indexPath.section]) {
        Follow *relation = (Follow *)[self relationForSection:indexPath.section];
        BOOL mute = !relation.mute;
        UITableViewRowAction *muteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal
                                                                              title:mute ? NSLocalizedString(@"mute_button",nil) : NSLocalizedString(@"unmute_button",nil)
            handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
                if (mute) {
                    if ([GeneralUtils explainBeforeMute]) {
                        self.selectedRelation = relation;
                        // Present alert view
                        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"mute_following_alert_title", nil)
                                                    message:[NSString stringWithFormat:NSLocalizedString(@"mute_following_alert_message", nil), relation.to.flashUsername]
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"cancel_button_title", nil)
                                          otherButtonTitles:NSLocalizedString(@"mute_and_stop_explaining_button", nil),NSLocalizedString(@"mute_button", nil), nil] show];
                    } else {
                        // mute
                        [self muteFollowing:relation];
                    }
                } else {
                    // unmute
                    [self unmuteFollowing:relation];
                }
            }];
        UITableViewRowAction *deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive
                                                                              title:NSLocalizedString(@"delete_action",nil)
            handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
                if ([GeneralUtils explainBeforeDelete]) {
                    self.selectedRelation = relation;
                    // Present alert view
                    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"delete_following_alert_title", nil)
                                                message:[NSString stringWithFormat:NSLocalizedString(@"delete_following_alert_message", nil), relation.to.flashUsername]
                                               delegate:self
                                      cancelButtonTitle:NSLocalizedString(@"cancel_button_title", nil)
                                      otherButtonTitles:NSLocalizedString(@"delete_and_stop_explaining_button", nil),NSLocalizedString(@"delete_action", nil), nil] show];
                } else {
                    // delete
                    [self deleteFollow:relation];
                }
            }];
        UITableViewRowAction *reportAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal
                                                                                title:NSLocalizedString(@"report_action",nil)
                                                                              handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
                                                                                  [ApiManager createReportWithUser:relation.to];
                                                                                  [self.friendsTableView reloadData];
                                                                              }];
        reportAction.backgroundColor = [ColorUtils blue];
        return @[deleteAction,muteAction,reportAction];
    } else {
        return nil;
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // bug apple : necessary for above to work
}

- (void)reloadSectionOfRelation:(Follow *)relation {
    NSInteger section = [self sectionForRelation:relation];
    if (section != NSNotFound) {
        [self reloadSection:section];
    }
}

- (void)reloadSection:(NSInteger)section {
    NSRange range = NSMakeRange(section, 1);
    NSIndexSet *sectionToReload = [NSIndexSet indexSetWithIndexesInRange:range];
    [self.friendsTableView reloadSections:sectionToReload withRowAnimation:UITableViewRowAnimationNone];
}

- (void)scrollToTop {
    [self.friendsTableView setContentOffset:CGPointZero animated:YES];
}

// --------------------------------------------
#pragma mark - Friends
// --------------------------------------------
- (BOOL)userBelongsToFollowing:(User *)user {
    for (Follow *follow in self.followingRelations) {
        if ([follow.to.objectId isEqualToString:user.objectId]) {
            return true;
        }
    }
    return false;
}

// Block user
- (void)blockUserFromFollow:(Follow *)follow
{
    follow.blocked = YES;
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [ApiManager saveRelation:follow
                     success:^{
                         [MBProgressHUD hideHUDForView:self.view animated:YES];
                         [self.followerRelations removeObject:follow];
                         [self.messagesReceivedDictionnary removeObjectForKey:follow.from.objectId];
                         [self sortFriendsAndReload];
                         [TrackingUtils trackEvent:EVENT_FRIEND_BLOCK properties:nil];
                     } failure:^(NSError *error) {
                         [MBProgressHUD hideHUDForView:self.view animated:YES];
                         [GeneralUtils showAlertMessage:NSLocalizedString(@"please_try_again", nil) withTitle:NSLocalizedString(@"unexpected_error", nil)];
                     }];
}

- (void)createRelationshipFromFollow:(Follow *)follow
{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [ApiManager createRelationWithFollowing:follow.from
                                    success:^(Follow *following){
                                        [MBProgressHUD hideHUDForView:self.view animated:YES];
                                        [self.followerRelations removeObject:follow];
                                         [self.followingRelations addObject:following];
                                        [self sortFriendsAndReload];
                                        [self reloadFeedVideo];
                                    } failure:^(NSError *error) {
                                        [MBProgressHUD hideHUDForView:self.view animated:YES];
                                        [GeneralUtils showAlertMessage:NSLocalizedString(@"please_try_again", nil) withTitle:NSLocalizedString(@"unexpected_error", nil)];
                                    }];
}

// Order friends
- (void)orderFriendsByLastMessageDateAndScore {
    [self.followingRelations sortUsingComparator:^NSComparisonResult(Follow *obj1, Follow *obj2) {
        User *user1 = obj1.to;
        User *user2 = obj2.to;
        if (user1 == [PFUser currentUser]) {
            return NSOrderedAscending;
        } else if (user2 == [PFUser currentUser]) {
            return NSOrderedDescending;
        } else {
            if (!user1.lastMessageDate) [user1 updateLastMessageDate:[NSDate dateWithTimeIntervalSince1970:0]];
            if (!user2.lastMessageDate) [user2 updateLastMessageDate:[NSDate dateWithTimeIntervalSince1970:0]];
            if ([user1.lastMessageDate isEqual:user2.lastMessageDate]) {
                return user1.score > user2.score ? NSOrderedAscending : NSOrderedDescending;
            } else {
                return [user2.lastMessageDate compare:user1.lastMessageDate];
            }
        }
    }];
}

- (void)muteFollowing:(Follow *)follow {
    follow.mute = YES;
    [self saveRelation:follow];
    [TrackingUtils trackEvent:EVENT_FRIEND_MUTE properties:nil];
}

- (void)unmuteFollowing:(Follow *)follow {
    follow.mute = NO;
    [self saveRelation:follow];
    [TrackingUtils trackEvent:EVENT_FRIEND_UNMUTE properties:nil];
}

- (void)saveRelation:(Follow *)follow {
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [ApiManager saveRelation:follow
                     success:^{
                         [MBProgressHUD hideHUDForView:self.view animated:YES];
                         [self.friendsTableView reloadData];
                         [self reloadFeedVideo];
                     } failure:^(NSError *error) {
                         [MBProgressHUD hideHUDForView:self.view animated:YES];
                         [GeneralUtils showAlertMessage:NSLocalizedString(@"please_try_again", nil)
                                              withTitle:NSLocalizedString(@"unexpected_error", nil)];
                     }];
}

- (void)deleteFollow:(Follow *)follow {
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [ApiManager deleteRelation:follow
                       success:^{
                           [MBProgressHUD hideHUDForView:self.view animated:YES];
                           [self.followingRelations removeObject:follow];
                           self.postToDetailIndexPath = nil;
                           [self.friendsTableView reloadData];
                           [self reloadFeedVideo];
                       } failure:^(NSError *error) {
                           [MBProgressHUD hideHUDForView:self.view animated:YES];
                           [GeneralUtils showAlertMessage:NSLocalizedString(@"please_try_again", nil)
                                                withTitle:NSLocalizedString(@"unexpected_error", nil)];
                       }];
}

- (void)reloadFeedVideo {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"retrieve_video"
                                                        object:nil
                                                      userInfo:nil];
}


// --------------------------------------------
#pragma mark - Cell Type & Logic
// --------------------------------------------
// 1st me, then followers, then friends
- (Follow *)relationForSection:(NSInteger)section {
    if (section == 0 || section == 1) {
        return nil;
    } else if (section < self.followerRelations.count + 2) {
        return (Follow *)self.followerRelations[section - 2];
    } else if (section < self.followingRelations.count + self.followerRelations.count + 2) {
        return (Follow *)self.followingRelations[section - self.followerRelations.count - 2];
    } else {
        return nil;
    }
}

- (NSInteger)sectionForRelation:(Follow *)relation {
    return [self.followingRelations indexOfObject:relation] + 1 + self.followerRelations.count;
}

- (BOOL)isAddFriendSection:(NSInteger)section {
    return section == 0;
}

- (BOOL)isCurrentUserSection:(NSInteger)section {
    return section == [self currentUserSection];
}

- (NSInteger)currentUserSection {
    return 1;
}

- (BOOL)isCurrentUserUserCell:(NSIndexPath *)indexPath {
    return [self isCurrentUserSection:indexPath.section] && indexPath.row == 0;
}

- (BOOL)isFollowerUserSection:(NSInteger)section {
    return ![self isAddFriendSection:section] && ![self isCurrentUserSection:section] && section < self.followerRelations.count + 2;
}

- (BOOL)isFollowingUserSection:(NSInteger)section {
    return ![self isAddFriendSection:section] && ![self isCurrentUserSection:section] && ![self isFollowerUserSection:section] && (section < self.followerRelations.count + self.followingRelations.count + 2);
}

- (BOOL)isCurrentUserPostCell:(NSIndexPath *)indexPath {
    return indexPath.row != 0 && [self isCurrentUserSection:indexPath.section];
}


// --------------------------------------------
#pragma mark - Friend TVC Delegate
// --------------------------------------------
- (void)saveCurrentUserStoryButtonClicked {
    if ([GeneralUtils explainBeforeSavingStory]) {
        // Present alert view
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"save_story_alert_title", nil)
                                    message:NSLocalizedString(@"save_story_alert_message", nil)
                                   delegate:self
                          cancelButtonTitle:NSLocalizedString(@"cancel_button_title", nil)
                          otherButtonTitles:NSLocalizedString(@"save_and_stop_explaining_button", nil),NSLocalizedString(@"save_button", nil), nil] show];
    } else {
        [self saveStory];
    }
}
    
- (void)saveStory {
    _isSavingStory = YES;
    [self reloadSection:[self currentUserSection]];
    AVPlayerItem *pi = [VideoUtils createAVPlayerItemWithVideoPosts:self.currentUserPosts
                                          andFillObservedTimesArray:nil];
    [VideoUtils saveVideoCompositionToCameraRoll:pi.asset success:^{
        _isSavingStory = NO;
        FriendTableViewCell *currentUserCell = (FriendTableViewCell *)[self.friendsTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:[self currentUserSection]]];
        [currentUserCell savedAnimation];
    } failure:^{
        _isSavingStory = NO;
        [self reloadSection:[self currentUserSection]];
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
                                   self.postToDetailIndexPath = nil;
                                   [self reloadSection:[self currentUserSection]];
                               } failure:^(NSError *error) {
                                   [MBProgressHUD hideAllHUDsForView:self.view animated:NO];
                                   [GeneralUtils showAlertMessage:NSLocalizedString(@"delete_flash_error_message", nil) withTitle:NSLocalizedString(@"delete_flash_error_title", nil)];
                               }];
            }
        }
    } else if([alertView.message isEqualToString:NSLocalizedString(@"follow_or_block_alert_message", nil)]) {
        BOOL block = [[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"block_button", nil)];
        // Block User
        if (block) {
            [self blockUserFromFollow:self.selectedRelation];
        } else {
            [self createRelationshipFromFollow:self.selectedRelation];
        }
        self.selectedRelation = nil;

    } else if ([alertView.title isEqualToString:NSLocalizedString(@"delete_following_alert_title", nil)]) {
        if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"cancel_button_title", nil)]) {
            return;
        } else {
            // delete
            [self deleteFollow:self.selectedRelation];
            self.selectedRelation = nil;
            if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"delete_and_stop_explaining_button", nil)]) {
                [GeneralUtils setDeleteExplanationHidden:YES];
            }
        }
    } else if ([alertView.title isEqualToString:NSLocalizedString(@"mute_following_alert_title", nil)]) {
        if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"cancel_button_title", nil)]) {
            return;
        } else {
            // mute
            [self muteFollowing:self.selectedRelation];
            self.selectedRelation = nil;
            if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"mute_and_stop_explaining_button", nil)]) {
                [GeneralUtils setMuteExplanationHidden:YES];
            }
        }
    } else if ([alertView.title isEqualToString:NSLocalizedString(@"save_story_alert_title", nil)]) {
        if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"cancel_button_title", nil)]) {
            return;
        } else {
            // save
            [self saveStory];
            if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"mute_and_stop_explaining_button", nil)]) {
                [GeneralUtils setSaveStoryExplanationHidden:YES];
            }
        }
    }
}


// --------------------------------------------
#pragma mark - UI
// --------------------------------------------
// Background Color Cycle
- (void)doBackgroundColorAnimation {
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
        self.titleLabel.textColor = [colors objectAtIndex:i];
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
