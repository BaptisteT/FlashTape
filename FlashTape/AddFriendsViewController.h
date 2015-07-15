//
//  AddFriendsViewController.h
//  FlashTape
//
//  Created by Baptiste Truchot on 6/6/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
#import <UIKit/UIKit.h>

#import "AddUserTableViewCell.h"
#import "FlashTapeParentViewController.h"
#import "InviteContactTableViewCell.h"

@interface AddFriendsViewController : FlashTapeParentViewController <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, AddUserTVCDelegate, InviteContactTVCDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) NSMutableOrderedSet *followingRelations;

@end
