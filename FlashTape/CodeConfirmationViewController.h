//
//  CodeConfirmationViewController.h
//  FlashTape
//
//  Created by Baptiste Truchot on 5/7/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "FlashTapeParentViewController.h"

@interface CodeConfirmationViewController : FlashTapeParentViewController <UITextFieldDelegate>

@property (strong, nonatomic) NSString *phoneNumber;
@property (strong, nonatomic) NSString *verificationCode;

@end
