//
//  FirstFlashTutoViewController.m
//  FlashTape
//
//  Created by Baptiste Truchot on 6/28/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//

#import "FirstFlashTutoViewController.h"

#import "ConstantUtils.h"

@interface FirstFlashTutoViewController ()

@property (weak, nonatomic) IBOutlet UILabel *tutoLabel;
@property (weak, nonatomic) IBOutlet UILabel *tapToNextLabel;

@end

@implementation FirstFlashTutoViewController {
    NSInteger _tapIndex;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _tapIndex = 0;
    UITapGestureRecognizer *tapGestureRecogniser = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap)];
    [self.view addGestureRecognizer:tapGestureRecogniser];
    
    self.tutoLabel.numberOfLines = 0;
    self.tutoLabel.text = NSLocalizedString(@"first_flash_message_1", nil);
    
    self.tapToNextLabel.text = NSLocalizedString(@"tap_to_next", nil);
}


- (void)handleTap {
    _tapIndex ++;
    if (_tapIndex == 1) {
        self.tutoLabel.text = NSLocalizedString(@"first_flash_message_2", nil);
    } else {
        [self dismissViewControllerAnimated:NO completion:nil];
    }
}

@end
