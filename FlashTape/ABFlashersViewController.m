//
//  ABFlashersViewController.m
//  FlashTape
//
//  Created by Baptiste Truchot on 6/28/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
#import "ApiManager.h"
#import "DatastoreUtils.h"
#import "User.h"
#import "ColorUtils.h"

#import "ABFlashersViewController.h"

#import "AddressbookUtils.h"
#import "MBProgressHUD.h"

@interface ABFlashersViewController ()

@property (strong, nonatomic) NSDictionary *contactDictionnary;
@property (weak, nonatomic) IBOutlet UIButton *addFriendsButton;
@property (weak, nonatomic) IBOutlet UITableView *flashersTableView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) NSMutableArray *flashersToAddArray;
@property (strong, nonatomic) IBOutlet UIView *colorTopView;

@end

@implementation ABFlashersViewController

// ----------------------------------------------------------
#pragma mark Life cycle
// ----------------------------------------------------------

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Array
    if (!self.flashersArray || self.flashersArray.count == 0) {
        [self navigateToVideoController];
        return;
    }
    self.flashersToAddArray = [NSMutableArray arrayWithArray:self.flashersArray];
    
    // Get addressbook contacts
    self.contactDictionnary = [AddressbookUtils getContactDictionnary];
    
    // Tableview
    self.flashersTableView.dataSource = self;
    self.flashersTableView.delegate = self;
    self.flashersTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    // Title
    self.titleLabel.numberOfLines = 0;
    self.titleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"flashers_found_label", nil),self.flashersArray.count];
    
    // Button
    [self setAddFriendsButtonTitle];
    
    //Status Bar
    [self setNeedsStatusBarAppearanceUpdate];
    
    //Color background
    [self doBackgroundColorAnimation];
}

-(UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent; // Set status bar color to white
}

- (void)navigateToVideoController {
    [self performSegueWithIdentifier:@"Video From ABFlashers" sender:nil];
}

// ----------------------------------------------------------
#pragma mark Actions
// ----------------------------------------------------------

- (IBAction)addFriendsButtonClicked:(id)sender {
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [ApiManager createRelationWithFollowings:self.flashersToAddArray
                                     success:^{
                                         [MBProgressHUD hideAllHUDsForView:self.view animated:NO];
                                         [self navigateToVideoController];
                                     } failure:^(NSError *error) {
                                         [MBProgressHUD hideAllHUDsForView:self.view animated:NO];
                                         [self navigateToVideoController];
                                     }];
}

// ----------------------------------------------------------
#pragma mark Tableview
// ----------------------------------------------------------
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.flashersArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 58;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath  {
    ABFlasherTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ABFlasherTableViewCell"];
    User *user = (User *)[self.flashersArray objectAtIndex:indexPath.row];
    [cell initWithUser:user name:self.contactDictionnary[user.username] state:[self.flashersToAddArray containsObject:user]];
    cell.delegate = self;
    return cell;
}

// ----------------------------------------------------------
#pragma mark ABFlasherTableViewCell delegate
// ----------------------------------------------------------
- (void)addUserToFlasherToAdd:(User *)user {
    if (![self.flashersToAddArray containsObject:user]) {
        [self.flashersToAddArray addObject:user];
    }
    [self setAddFriendsButtonTitle];
}

- (void)removeUserFromFlasherToAdd:(User *)user {
    [self.flashersToAddArray removeObject:user];
    [self setAddFriendsButtonTitle];
}

// ----------------------------------------------------------
#pragma mark UI
// ----------------------------------------------------------
- (void)setAddFriendsButtonTitle {
    [self.addFriendsButton setTitle:[NSString stringWithFormat:NSLocalizedString(@"add_friends_button",nil),self.flashersToAddArray.count] forState:UIControlStateNormal];
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
    
    [UIView animateWithDuration:1.5f delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        self.colorTopView.backgroundColor = [colors objectAtIndex:i];
        [self.addFriendsButton setTitleColor:[colors objectAtIndex:i] forState:UIControlStateNormal];
    } completion:^(BOOL finished) {
        ++i;
        [self doBackgroundColorAnimation];
    }];
}

@end
