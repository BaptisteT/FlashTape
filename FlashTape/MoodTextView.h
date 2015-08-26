//
//  CaptionTextView.h
//  FlashTape
//
//  Created by Baptiste Truchot on 5/19/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//

@import Foundation;
@import UIKit;


@interface MoodTextView : UITextView <UIGestureRecognizerDelegate>

- (void)setEmoji:(NSString *)emoji;
- (void)playSound:(BOOL)flag;

@end




