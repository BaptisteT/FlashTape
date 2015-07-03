//
//  WelcomeViewController.m
//  FlashTape
//
//  Created by Baptiste Truchot on 5/6/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//

#import "WelcomeViewController.h"
#import "VideoViewController.h"

#import "ColorUtils.h"
#import "ConstantUtils.h"

@interface WelcomeViewController ()

@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (strong, nonatomic) IBOutlet UIView *colorView;
@property (weak, nonatomic) IBOutlet UILabel *termsLabel;

@end

@implementation WelcomeViewController {
    BOOL _stopAnimation;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [[self navigationController] setNavigationBarHidden:YES animated:YES];
    
    self.termsLabel.numberOfLines = 0;
    self.termsLabel.text = NSLocalizedString(@"terms_label", nil);
    self.termsLabel.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapOnLabel)];
    [self.termsLabel addGestureRecognizer:tapGesture];
    
    //Login Button
    [self.loginButton setTitle:NSLocalizedString(@"login_button", nil) forState:UIControlStateNormal];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    //ColorView
    _stopAnimation = NO;
    [self doBackgroundColorAnimation];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    _stopAnimation = YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSString * segueName = segue.identifier;
    if ([segueName isEqualToString: @"Video From Welcome"]) {
        if ([sender boolValue]) {
            ((VideoViewController *) [segue destinationViewController]).navigateDirectlyToFriends = YES;
        }
    }
}


// --------------------------------------------
#pragma mark - Background Color Cycle
// --------------------------------------------
- (void) doBackgroundColorAnimation {
    if (_stopAnimation) {
        return;
    }
    static NSInteger i = 0;
    NSArray *colors = [NSArray arrayWithObjects:[ColorUtils pink],
                                                [ColorUtils purple],
                                                [ColorUtils blue],
                                                [ColorUtils green],
                                                [ColorUtils orange], nil];
    if(i >= [colors count]) {
        i = 0;
    }
    [UIView animateWithDuration:1.5f
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction
                     animations:^{
        self.colorView.backgroundColor = [colors objectAtIndex:i];
    }   completion:^(BOOL finished) {
        ++i;
        [self doBackgroundColorAnimation];
    }];
    
}

- (void)handleTapOnLabel {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:kFlashTapeWebsiteTermsLink]];
}



@end
