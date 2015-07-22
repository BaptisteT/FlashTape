//
//  ABFlashersViewController.h
//  FlashTape
//
//  Created by Baptiste Truchot on 6/28/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ABFlasherTableViewCell.h"
#import "FlashTapeParentViewController.h"
#import "InviteContactTableViewCell.h"


@interface FirstTimeAddFriendsViewController : FlashTapeParentViewController <UITableViewDataSource, UITableViewDelegate, ABFlasherTVCDelegate, InviteContactTVCDelegate>

@property (nonatomic, strong) NSArray *flashersArray;
@property (nonatomic) UIViewController *initialViewController;

@end
