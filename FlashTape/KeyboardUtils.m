//
//  KeyboardUtils.m
//  FlashTape
//
//  Created by Baptiste Truchot on 6/1/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//

#import "KeyboardUtils.h"

@implementation KeyboardUtils

// Animation to change the view frame as keyboard moves
+ (void)changeFrameOfView:(UIView *)topView whenKeyboardMoveNotification:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    NSValue *afterValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect afterKeyboardRect = [afterValue CGRectValue];
    
    CGRect newTextViewFrame = topView.frame;
    newTextViewFrame.size.height = afterKeyboardRect.origin.y - newTextViewFrame.origin.y;
    
    // Get the duration of the animation.
    NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration;
    [animationDurationValue getValue:&animationDuration];
    
    // Animate the resize of the text view's frame in sync with the keyboard's appearance.
    [UIView animateWithDuration:animationDuration animations:^() {
        topView.frame = newTextViewFrame;
    }];
}

// Animation to move up the view as the keyboard shows
+ (void)pushUpTopView:(UIView *)topView whenKeyboardWillShowNotification:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    NSValue *beforeValue = [userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey];
    NSValue *afterValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect beforeKeyboardRect = [beforeValue CGRectValue];
    CGRect afterKeyboardRect = [afterValue CGRectValue];
    
    CGRect newTextViewFrame = topView.frame;
    newTextViewFrame.origin.y = topView.frame.origin.y - beforeKeyboardRect.origin.y + afterKeyboardRect.origin.y;
    
    // Get the duration of the animation.
    NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration;
    [animationDurationValue getValue:&animationDuration];
    
    // Animate the resize of the text view's frame in sync with the keyboard's appearance.
    [UIView animateWithDuration:animationDuration animations:^() {
        topView.frame = newTextViewFrame;
    }];
}

// Animation to move down the view as the keyboard hides
+ (void)pushDownTopView:(UIView *)topView whenKeyboardWillhideNotification:(NSNotification *) notification {
    
    NSDictionary *userInfo = [notification userInfo];
    NSValue *beforeValue = [userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey];
    NSValue *afterValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect beforeKeyboardRect = [beforeValue CGRectValue];
    CGRect afterKeyboardRect = [afterValue CGRectValue];
    
    CGRect newTextViewFrame = topView.frame;
    newTextViewFrame.origin.y = topView.frame.origin.y - beforeKeyboardRect.origin.y + afterKeyboardRect.origin.y;
    
    NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration;
    [animationDurationValue getValue:&animationDuration];
    
    [UIView animateWithDuration:animationDuration animations:^() {
        topView.frame = newTextViewFrame;
    }];
}


@end
