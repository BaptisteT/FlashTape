//
//  BackwardTextField.h
//  FlashTape
//
//  Created by Baptiste Truchot on 7/7/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol BackwardTextFieldDelegate;

@interface BackwardTextField : UITextField

@property (weak, nonatomic) id<BackwardTextFieldDelegate, UITextFieldDelegate> delegate;

@end

@protocol BackwardTextFieldDelegate <UITextFieldDelegate>

- (void)backspaceOnEmptyStringDetected;

@end
