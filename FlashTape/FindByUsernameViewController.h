//
//  FindByUsernameViewController.h
//  FlashTape
//
//  Created by Baptiste Truchot on 6/6/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
#import "AddUserTableViewCell.h"

#import <UIKit/UIKit.h>

#import "FlashTapeParentViewController.h"

@interface FindByUsernameViewController : FlashTapeParentViewController <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, AddUserTVCDelegate>

@property (strong, nonatomic) NSMutableOrderedSet *followingRelations;

@end
