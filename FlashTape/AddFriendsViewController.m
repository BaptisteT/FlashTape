//
//  AddFriendsViewController.m
//  FlashTape
//
//  Created by Baptiste Truchot on 6/6/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
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

@property (strong, nonatomic) NSMutableArray *unfollowedArray;
@property (strong, nonatomic) NSMutableDictionary *contactDictionnary;
@property (strong, nonatomic) NSMutableArray *unrelatedArray;

@property (strong, nonatomic) NSMutableArray *autocompleteNumberArray;
@property (strong, nonatomic) NSMutableArray *autocompleteContactArray;
@property (strong, nonatomic) NSMutableArray *autocompleteUnfollowedArray;
@property (strong, nonatomic) NSMutableArray *autocompleteUnrelatedArray;

@end

@implementation AddFriendsViewController

// --------------------------------------------
#pragma mark - Life Cycle
// --------------------------------------------

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // init
    self.unfollowedArray = [NSMutableArray new];
    self.unrelatedArray = [NSMutableArray new];
    self.autocompleteUnfollowedArray = [NSMutableArray arrayWithArray:self.unfollowedArray];
    self.autocompleteUnrelatedArray = [NSMutableArray arrayWithArray:self.unrelatedArray];
    
    // Contact
    self.contactDictionnary = [NSMutableDictionary dictionaryWithDictionary:[AddressbookUtils getContactDictionnary]];
    self.autocompleteNumberArray = [NSMutableArray arrayWithArray:[self.contactDictionnary allKeys]];
    self.autocompleteContactArray = [NSMutableArray arrayWithArray:[self.contactDictionnary allValues]];
    
    // Get unfollowed follower
    [DatastoreUtils getUnfollowedFollowersLocallyAndExecuteSuccess:^(NSArray *followers) {
        if (followers) {
            self.unfollowedArray = [NSMutableArray arrayWithArray:followers];
        }
        [self reloadTableView];
    } failure:nil];
    
    // Get unrelated contacts
    [DatastoreUtils getUnrelatedUserInAddressBook:[self.contactDictionnary allKeys]
                                          success:^(NSArray *unrelatedUser) {
                                              if (unrelatedUser) {
                                                  self.unrelatedArray = [NSMutableArray arrayWithArray:unrelatedUser];
                                              }
                                              [self reloadTableView];
                                          } failure:nil];
    
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
    self.resultTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    // Reset new flasher / follower at 0
    [GeneralUtils setNewNewAddressbookFlasherCount:0];
    [GeneralUtils setNewUnfollowedFollowerCount:0];
}


// --------------------------------------------
#pragma mark - Actions
// --------------------------------------------
- (IBAction)backButtonClicked:(id)sender {
    [self dismissViewControllerAnimated:NO completion:nil];
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
        self.autocompleteNumberArray = [NSMutableArray arrayWithArray:[self.contactDictionnary allKeys]];
        self.autocompleteContactArray = [NSMutableArray arrayWithArray:[self.contactDictionnary allValues]];
    } else {
        self.autocompleteUnfollowedArray = [NSMutableArray new];
        self.autocompleteUnrelatedArray = [NSMutableArray new];
        self.autocompleteNumberArray = [NSMutableArray new];
        self.autocompleteContactArray = [NSMutableArray new];
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
        
        for(NSString *number in [self.contactDictionnary allKeys]) {
            NSString *name = self.contactDictionnary[number];
            NSRange substringRange = [name rangeOfString:substring options:NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch];
            if (substringRange.location == 0) {
                [self.autocompleteContactArray addObject:name];
                [self.autocompleteNumberArray addObject:number];
            }
            // todo BT
            // check it's not another user
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
    if (section == 0) {
        return self.usernameSearchBar.text.length > 0 ? 1 : 0;
    } else if (section == 1) {
        return self.autocompleteUnfollowedArray.count;
    } else if (section == 2) {
        return self.autocompleteUnrelatedArray.count;
    } else if (section == 3) {
        return self.autocompleteContactArray.count;
    } else {
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 3) {
        InviteContactTableViewCell *cell = (InviteContactTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"InviteUserCell"];
        NSString *number = self.autocompleteNumberArray[indexPath.row];
        NSString *name = self.autocompleteContactArray[indexPath.row];
        [cell initWithName:name number:number];
        cell.delegate = self;
        return cell;
    } else {
        AddUserTableViewCell *cell = (AddUserTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"AddUserCell"];
        if (!cell) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"AddUserTableViewCell" owner:self options:nil];
            cell = [nib objectAtIndex:0];
            cell.delegate = self;
        }
        
        if (indexPath.section == 0) {
            [cell setSearchedUsernameTo:self.usernameSearchBar.text];
        } else if (indexPath.section == 1) {
            if (indexPath.row < self.autocompleteUnfollowedArray.count)
                [cell setCellUserTo:self.autocompleteUnfollowedArray[indexPath.row]];
        } else if (indexPath.section == 2) {
            if (indexPath.row < self.autocompleteUnrelatedArray.count)
                [cell setCellUserTo:self.autocompleteUnrelatedArray[indexPath.row]];
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
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 18)];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(16, 2, tableView.frame.size.width - 32, 18)];
    [label setFont:[UIFont fontWithName:@"NHaasGroteskDSPro-65Md" size:14]];
    label.textColor = [UIColor colorWithRed:0./255 green:0./255 blue:0./255 alpha:0.2];
    if (section == 0) {
        NSString *string = NSLocalizedString(@"username_section_title", nil);
        [label setText:string];
    } else if (section == 1) {
        NSString *string = NSLocalizedString(@"follower_section_title", nil);
        [label setText:string];
    } else if (section == 2) {
        NSString *string = NSLocalizedString(@"addressbook_section_title", nil);
        [label setText:string];
    } else {
        NSString *string = NSLocalizedString(@"invite_section_title", nil);
        [label setText:string];
    }
    [view addSubview:label];
    [view setBackgroundColor:[UIColor colorWithRed:229/255.0 green:229/255.0 blue:229/255.0 alpha:1.0]];
    return view;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self.usernameSearchBar resignFirstResponder];
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
                     success:^{
                         // do nothing
                     } failure:nil];
    
    // Remove user
    [self.contactDictionnary removeObjectForKey:number];
    
    // Reload addressbook section
    [self reloadTableView];
}
@end
