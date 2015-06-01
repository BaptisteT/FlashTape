//
//  KeyboardUtils.h
//  FlashTape
//
//  Created by Baptiste Truchot on 6/1/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//

@import Foundation;
@import UIKit;

@interface KeyboardUtils : NSObject

// Animation to move up the view as the keyboard shows
+ (void)pushUpTopView:(UIView *)topView whenKeyboardWillShowNotification:(NSNotification *)notification;

// Animation to move down the view as the keyboard hides
+ (void)pushDownTopView:(UIView *)topView whenKeyboardWillhideNotification:(NSNotification *) notification;



@end
