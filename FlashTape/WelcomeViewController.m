//
//  WelcomeViewController.m
//  FlashTape
//
//  Created by Baptiste Truchot on 5/6/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//

#import "WelcomeViewController.h"

@interface WelcomeViewController ()

@property (weak, nonatomic) IBOutlet UIButton *loginButton;

@end

@implementation WelcomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.loginButton setTitle:NSLocalizedString(@"login_button", nil) forState:UIControlStateNormal];
}



@end
