//
//  WelcomeViewController.m
//  FlashTape
//
//  Created by Baptiste Truchot on 5/6/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//

#import "WelcomeViewController.h"
#import "ColorUtils.h"

@interface WelcomeViewController ()

@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (strong, nonatomic) IBOutlet UIView *colorView;

@end

@implementation WelcomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    //Hide Status Bar & Navigation Bar Controller
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    [[self navigationController] setNavigationBarHidden:YES animated:YES];
    
    //Login Button
    [self.loginButton setTitle:NSLocalizedString(@"login_button", nil) forState:UIControlStateNormal];

    //ColorView
    [self doBackgroundColorAnimation];
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
    
    [UIView animateWithDuration:1.5f animations:^{
        self.colorView.backgroundColor = [colors objectAtIndex:i];
    } completion:^(BOOL finished) {
        ++i;
        [self doBackgroundColorAnimation];
    }];
    
}



@end
