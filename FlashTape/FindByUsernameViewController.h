//
//  FindByUsernameViewController.h
//  FlashTape
//
//  Created by Baptiste Truchot on 6/6/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
#import "AddUserTableViewCell.h"

#import <UIKit/UIKit.h>

@interface FindByUsernameViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, AddUserTVCDelegate>

@property (strong, nonatomic) NSMutableOrderedSet *friends;

@end
