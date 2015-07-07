//
//  BackwardTextField.m
//  FlashTape
//
//  Created by Baptiste Truchot on 7/7/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//

#import "BackwardTextField.h"

@implementation BackwardTextField

@dynamic delegate;

-(void)deleteBackward;
{
    if (self.text.length == 0) {
        [self.delegate backspaceOnEmptyStringDetected];
    }
    [super deleteBackward];
}

- (BOOL)shouldChangeTextInRange:(UITextRange *)range replacementText:(NSString *)text {
    return [super shouldChangeTextInRange:range replacementText:text];
}

-(void) setDelegate:(id<BackwardTextFieldDelegate>) delegate {
    [super setDelegate: delegate];
}
- (id) delegate {
    return [super delegate];
}

@end
