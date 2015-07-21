//
//  AddFriendsViewController.m
//  FlashTape
//
//  Created by Baptiste Truchot on 6/6/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
#import "ABContact.h"
#import "ApiManager.h"
#import "DatastoreUtils.h"
#import "User.h"

#import "AddFriendsViewController.h"

#import "AddressbookUtils.h"
#import "ConstantUtils.h"
#import "GeneralUtils.h"
#import "MBProgressHUD.h"
#import "ColorUtils.h"

@interface AddFriendsViewController ()
@property (weak, nonatomic) IBOutlet UISearchBar *usernameSearchBar;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UITableView *resultTableView;

@property (strong, nonatomic) NSMutableDictionary *addressBookDictionnary;

@property (strong, nonatomic) NSArray *abContactArray;
@property (strong, nonatomic) NSArray *unfollowedArray;
@property (strong, nonatomic) NSArray *unrelatedArray;

@property (strong, nonatomic) NSMutableArray *autocompleteAbContactArray;
@property (strong, nonatomic) NSMutableArray *autocompleteUnfollowedArray;
@property (strong, nonatomic) NSMutableArray *autocompleteUnrelatedArray;

@property (weak, nonatomic) IBOutlet UIButton *allowContactButton;

@end

@implementation AddFriendsViewController

// --------------------------------------------
#pragma mark - Life Cycle
// --------------------------------------------

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // init
    self.addressBookDictionnary = [NSMutableDictionary dictionaryWithDictionary:[AddressbookUtils getContactDictionnary]];
    
    // Allow contact button
    [self.allowContactButton setTitle:NSLocalizedString(@"allow_contact_title", nil) forState:UIControlStateNormal];
    self.allowContactButton.hidden = (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized);
    
    // Contact
    [self getContactAndFollowers];
    
    self.titleLabel.text = NSLocalizedString(@"find_by_username_controller_title", nil);
    [self.backButton setTitle:NSLocalizedString(@"back_button", nil) forState:UIControlStateNormal];
    
    self.usernameSearchBar.delegate = self;
    self.usernameSearchBar.showsCancelButton = NO;
    self.usernameSearchBar.tintColor = [UIColor blackColor];
    self.usernameSearchBar.placeholder = NSLocalizedString(@"find_by_username_textfield_placeholder", nil);
    [self.usernameSearchBar setSearchFieldBackgroundImage:[UIImage imageNamed:@"searchbar"]forState:UIControlStateNormal];
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setDefaultTextAttributes:@{NSFontAttributeName: [UIFont fontWithName:@"NHaasGroteskDSPro-65Md" size:15],}];
    [[UILabel appearanceWhenContainedIn:[UISearchBar class], nil] setTextColor:[UIColor colorWithRed:0./255. green:0./255. blue:0./255. alpha:0.2]];
    [self.usernameSearchBar setImage:[UIImage imageNamed:@"searchbar_icon"] forSearchBarIcon:UISearchBarIconSearch state:UIControlStateNormal];
    self.usernameSearchBar.searchTextPositionAdjustment = UIOffsetMake(5.0f, 0.0f);


    self.resultTableView.delegate = self;
    self.resultTableView.dataSource = self;
    self.resultTableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectZero];
    self.resultTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    // Reset new flasher / follower at 0
    [GeneralUtils setNewNewAddressbookFlasherCount:0];
    [GeneralUtils setNewUnfollowedFollowerCount:0];
    
    // Reload
    [self reloadTableView];
}

- (void)getContactAndFollowers {
    // AB Contacts
    [DatastoreUtils getAllABContactsLocallySuccess:^(NSArray *contacts) {
        self.abContactArray = [contacts sortedArrayUsingComparator:^NSComparisonResult(ABContact *obj1, ABContact *obj2) {
            NSString *name1 = self.addressBookDictionnary[obj1.number] ? self.addressBookDictionnary[obj1.number] : @"?";
            NSString *name2 = self.addressBookDictionnary[obj2.number] ? self.addressBookDictionnary[obj2.number] : @"?";
            return [name1 caseInsensitiveCompare:name2];
        }];
    } failure:nil];

    // Get unfollowed follower
    [DatastoreUtils getUnfollowedFollowersLocallyAndExecuteSuccess:^(NSArray *followers) {
        self.unfollowedArray = followers;
        [self reloadTableView];
    } failure:nil];
    
    // Get unrelated contacts
    [DatastoreUtils getUnrelatedUserInAddressBook:[self.addressBookDictionnary allKeys]
                                          success:^(NSArray *unrelatedUser) {
                                              self.unrelatedArray = unrelatedUser;
                                              [self reloadTableView];
                                          } failure:nil];
}


// --------------------------------------------
#pragma mark - Actions
// --------------------------------------------
- (IBAction)backButtonClicked:(id)sender {
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (IBAction)allowContactButtonClicked:(id)sender {
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {
        ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
            if (granted) {
                [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                NSMutableDictionary *contactDictionnary = [AddressbookUtils getFormattedPhoneNumbersFromAddressBook:addressBook];
                [AddressbookUtils saveContactDictionnary:contactDictionnary];
                [ApiManager findFlashUsersContainedInAddressBook:[contactDictionnary allKeys]
                                                         success:^(NSArray *userArray) {
                                                             [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
                                                             [self getContactAndFollowers];
                                                         } failure:^(NSError *error) {
                                                             [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
                                                             [self getContactAndFollowers];
                                                         }];
                
                // Current user real name
                NSString *abName = contactDictionnary[[User currentUser].username];
                if (abName && abName.length > 0 && ![[User currentUser].addressbookName isEqualToString:abName]) {
                    [ApiManager saveAddressbookName:contactDictionnary[[User currentUser].username]];
                }
                
                self.allowContactButton.hidden = YES;
            }
        });
    } else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusDenied) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"contact_access_error_title",nil)
                                    message:NSLocalizedString(@"contact_access_error_message",nil)
                                   delegate:self
                          cancelButtonTitle:NSLocalizedString(@"later_button",nil)
                          otherButtonTitles:NSLocalizedString(@"ok_button",nil), nil] show];
    }
}

// --------------------------------------------
#pragma mark - Textfield delegate
// --------------------------------------------
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self reloadTableView];
}


// --------------------------------------------
#pragma mark - Tableview
// --------------------------------------------
- (void)reloadTableView {
    NSString *substring = self.usernameSearchBar.text;
    
    if (substring.length == 0) {
        self.autocompleteUnfollowedArray = [NSMutableArray arrayWithArray:self.unfollowedArray];
        self.autocompleteUnrelatedArray = [NSMutableArray arrayWithArray:self.unrelatedArray];
        self.autocompleteAbContactArray = [NSMutableArray arrayWithArray:self.abContactArray];
    } else {
        self.autocompleteUnfollowedArray = [NSMutableArray new];
        self.autocompleteUnrelatedArray = [NSMutableArray new];
        self.autocompleteAbContactArray = [NSMutableArray new];
        for(User *user in self.unfollowedArray) {
            NSRange substringRange = [user.transformedUsername rangeOfString:substring options:NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch];
            if (substringRange.location == 0) {
                [self.autocompleteUnfollowedArray addObject:user];
            }
        }
        for(User *user in self.unrelatedArray) {
            NSRange substringRange = [user.transformedUsername rangeOfString:substring options:NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch];
            if (substringRange.location == 0) {
                [self.autocompleteUnrelatedArray addObject:user];
            }
        }
        
        for(ABContact *contact in self.abContactArray) {
            NSString *name = self.addressBookDictionnary[contact.number];
            NSRange substringRange = [name rangeOfString:substring options:NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch];
            if (substringRange.location == 0) {
                [self.autocompleteAbContactArray addObject:contact];
            }
        }

    }
    [self.resultTableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self numberOfRowsForSection:section];
}

- (NSInteger)numberOfRowsForSection:(NSInteger)section {
    if ([self isUsernameSearchedSection:section]) {
        return self.usernameSearchBar.text.length > 0 ? 1 : 0;
    } else if ([self isABUserSection:section]) {
        return self.autocompleteUnrelatedArray.count;
    } else if ([self isFollowerSection:section]) {
        return self.autocompleteUnfollowedArray.count;
    } else if ([self isABContactSection:section]) {
        return self.autocompleteAbContactArray.count;
    } else {
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self isABContactSection:indexPath.section]) {
        InviteContactTableViewCell *cell = (InviteContactTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"InviteUserCell"];
        ABContact *contact = (ABContact *)self.autocompleteAbContactArray[indexPath.row];
        [cell initWithName:self.addressBookDictionnary[contact.number] number:contact.number friendCount:contact.users.count];
        cell.delegate = self;
        return cell;
    } else {
        AddUserTableViewCell *cell = (AddUserTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"AddUserCell"];
        if (!cell) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"AddUserTableViewCell" owner:self options:nil];
            cell = [nib objectAtIndex:0];
            cell.delegate = self;
        }
        
        if ([self isUsernameSearchedSection:indexPath.section]) {
            [cell setSearchedUsernameTo:self.usernameSearchBar.text];
        } else if ([self isABUserSection:indexPath.section]) {
            if (indexPath.row < self.autocompleteUnrelatedArray.count) {
                User *user = (User *)self.autocompleteUnrelatedArray[indexPath.row];
                [cell setCellUserTo:user realName:self.addressBookDictionnary[user.username]];
            }
        } else if ([self isFollowerSection:indexPath.section]) {
            if (indexPath.row < self.autocompleteUnfollowedArray.count) {
                User *user = (User *)self.autocompleteUnfollowedArray[indexPath.row];
                [cell setCellUserTo:user realName:user.addressbookName];
            }
        }
        
        cell.separatorView.hidden = (1 + indexPath.row == [self numberOfRowsForSection:indexPath.section]);
        return cell;
    }
    return nil;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 58;
}


-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 20)];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(16, 2, tableView.frame.size.width - 32, 18)];
    [label setFont:[UIFont fontWithName:@"NHaasGroteskDSPro-65Md" size:14]];
    label.textColor = [UIColor colorWithRed:0./255 green:0./255 blue:0./255 alpha:0.2];
    if ([self isUsernameSearchedSection:section]) {
        NSString *string = NSLocalizedString(@"username_section_title", nil);
        [label setText:string];
    } else if ([self isABUserSection:section]) {
        if (self.autocompleteUnrelatedArray.count == 0) {
            return nil;
        }
        NSString *string = NSLocalizedString(@"addressbook_section_title", nil);
        [label setText:string];
    } else if ([self isFollowerSection:section]) {
        if (self.autocompleteUnfollowedArray.count == 0) {
            return nil;
        }
        NSString *string = NSLocalizedString(@"follower_section_title", nil);
        [label setText:string];
    } else {
        if (self.autocompleteAbContactArray.count == 0) {
            return nil;
        }
        NSString *string = NSLocalizedString(@"invite_section_title", nil);
        [label setText:string];
    }
    [view addSubview:label];
    [view setBackgroundColor:[UIColor colorWithRed:229/255.0 green:229/255.0 blue:229/255.0 alpha:1.0]];
    return view;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if ([self isUsernameSearchedSection:section] && self.usernameSearchBar.text.length == 0) {
        return 0;
    }
    if ([self isABUserSection:section] && self.autocompleteUnrelatedArray.count == 0) {
        return 0;
    }
    if ([self isFollowerSection:section] && self.autocompleteUnfollowedArray.count == 0) {
        return 0;
    }
    return 20;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self.usernameSearchBar resignFirstResponder];
}

// --------------------------------------------
#pragma mark - Section utils
// --------------------------------------------
- (BOOL)isUsernameSearchedSection:(NSInteger)section {
    return section == 0;
}

- (BOOL)isABUserSection:(NSInteger)section {
    return section == 1;
}

- (BOOL)isFollowerSection:(NSInteger)section {
    return section == 2;
}

- (BOOL)isABContactSection:(NSInteger)section {
    return section == 3;
}

// --------------------------------------------
#pragma mark - Add user Cell Delegate
// --------------------------------------------
- (void)addFollowingRelationAndReloadVideo:(Follow *)follow {
    [self.followingRelations insertObject:follow atIndex:0];
    [self reloadFeedVideo];
}

- (void)removeFollowingRelationAndReloadVideo:(Follow *)follow {
    [self.followingRelations removeObject:follow];
    [self reloadFeedVideo];
}

- (void)reloadFeedVideo {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"retrieve_video"
                                                        object:nil
                                                      userInfo:nil];
}


// --------------------------------------------
#pragma mark - Invite user Cell Delegate
// --------------------------------------------

- (void)inviteUser:(NSString *)name number:(NSString *)number {
    [ApiManager sendInviteTo:number
                        name:[name componentsSeparatedByString:@" "].firstObject
                     success:nil
                     failure:nil];
    
    // Remove user
    [self.addressBookDictionnary removeObjectForKey:number];
    
    // Reload addressbook section
    [self reloadTableView];
}

// ----------------------------------------------------------
#pragma mark AlertView
// ----------------------------------------------------------
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([alertView.title isEqualToString:NSLocalizedString(@"contact_access_error_title", nil)]) {
        if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"ok_button", nil)]) {
            [GeneralUtils openSettings];
        }
    }
}
@end
