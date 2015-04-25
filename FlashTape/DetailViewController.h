//
//  DetailViewController.h
//  FlashTape
//
//  Created by Baptiste Truchot on 4/25/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController

@property (strong, nonatomic) id detailItem;
@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;

@end

