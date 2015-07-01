//
//  InviteContactViewController.h
//  FlashTape
//
//  Created by Baptiste Truchot on 6/29/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//

#import "FlashTapeParentViewController.h"

@class ABContact;

@interface InviteContactViewController : FlashTapeParentViewController

@property (strong, nonatomic) NSMutableArray *contactArray;

@property (strong, nonatomic) UIColor *backgroundColor;

@end
