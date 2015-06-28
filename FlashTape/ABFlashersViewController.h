//
//  ABFlashersViewController.h
//  FlashTape
//
//  Created by Baptiste Truchot on 6/28/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ABFlasherTableViewCell.h"

@interface ABFlashersViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, ABFlasherTVCDelegate>

@property (nonatomic, strong) NSArray *flashersArray;

@end
