//
//  FindByUsernameViewController.m
//  FlashTape
//
//  Created by Baptiste Truchot on 6/6/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//

#import "FindByUsernameViewController.h"

#import "AddressbookUtils.h"
#import "ConstantUtils.h"
#import "DatastoreUtils.h"

@interface FindByUsernameViewController ()
@property (weak, nonatomic) IBOutlet UISearchBar *usernameSearchBar;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UITableView *resultTableView;

@property (strong, nonatomic) NSMutableArray *unfollowedArray;
@property (strong, nonatomic) NSDictionary *contactDictionnary;
@property (strong, nonatomic) NSMutableArray *unrelatedArray;

@end

@implementation FindByUsernameViewController

// --------------------------------------------
#pragma mark - Life Cycle
// --------------------------------------------

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Get unfollowed follower
    _unfollowedArray = [NSMutableArray new];
    [DatastoreUtils getUnfollowedFollowersLocallyAndExecuteSuccess:^(NSArray *followers) {
        self.unfollowedArray = [NSMutableArray arrayWithArray:followers];
        // todo BT reload
    } failure:nil];
    
    // Get unrelated contacts
    self.contactDictionnary = [AddressbookUtils getContactDictionnary];
    [DatastoreUtils getUnrelatedUserInAddressBook:[self.contactDictionnary allKeys]
                                          success:^(NSArray *unrelatedUser) {
                                              self.unrelatedArray = [NSMutableArray arrayWithArray:unrelatedUser];
                                              // todo BT reload
                                          } failure:nil];
    
    self.titleLabel.text = NSLocalizedString(@"find_by_username_controller_title", nil);
    [self.backButton setTitle:NSLocalizedString(@"back_button", nil) forState:UIControlStateNormal];
    
    self.usernameSearchBar.delegate = self;
    self.usernameSearchBar.showsCancelButton = NO;
    self.usernameSearchBar.tintColor = [UIColor blackColor];
    self.usernameSearchBar.placeholder = NSLocalizedString(@"find_by_username_textfield_placeholder", nil);
    [self.usernameSearchBar becomeFirstResponder];
    
    self.resultTableView.delegate = self;
    self.resultTableView.dataSource = self;
    self.resultTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
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
    [self.resultTableView reloadData];
}


// --------------------------------------------
#pragma mark - Tableview
// --------------------------------------------
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.usernameSearchBar.text.length > 0 ? 1 : 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    AddUserTableViewCell *cell = (AddUserTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"AddUserCell"];
    if (!cell) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"AddUserTableViewCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
        cell.delegate = self;
    }
    [cell setSearchedUsernameTo:self.usernameSearchBar.text];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return NSLocalizedString(@"username_section_title", nil);
    } else {
        return @"";
    }
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

@end
