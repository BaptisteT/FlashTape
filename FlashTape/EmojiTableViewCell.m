//
//  EmojiTableViewCell.m
//  FlashTape
//
//  Created by Baptiste Truchot on 7/28/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//

#import "EmojiTableViewCell.h"

#import "GeneralUtils.h"

@interface EmojiTableViewCell()

@property (strong, nonatomic) NSMutableArray *buttons;

@end

@implementation EmojiTableViewCell

- (void)initWithEmojis:(NSArray *)emojis isUnlockRow:(BOOL)flag
{
    self.backgroundColor = [UIColor clearColor];
    NSInteger numberOfRows = emojis.count + (flag ? 1 : 0);
    
    if (!self.buttons) {
        self.buttons = [NSMutableArray new];
    }
    
    CGFloat width = self.frame.size.width;
    CGFloat height = self.frame.size.height;
    
    CGFloat marginFactor = [GeneralUtils isiPhone4] ? 4 : 3;
    CGFloat marginRatio = 1. / marginFactor;
    CGFloat buttonSize = width / ((marginFactor + 1) * numberOfRows * marginRatio + marginRatio);
    
    CGFloat verticalMargin = marginRatio * buttonSize;
    CGFloat horizontalMargin = (height - buttonSize) / 2.;
    
    // Case where buttons exist
    if (self.buttons.count == numberOfRows) {
        for (int row = 0; row < numberOfRows; row ++) {
            CGRect frame = CGRectMake(verticalMargin + row * (verticalMargin + buttonSize), horizontalMargin, buttonSize, buttonSize);
            UIButton *button = (UIButton *)self.buttons[row];
            [button setFrame:frame];
            if (flag && row == 0) {
                [button addTarget:self action:@selector(unlockClicked) forControlEvents:UIControlEventTouchUpInside];
                [button setTitle:@"" forState:UIControlStateNormal];
                [button setImage:[UIImage imageNamed:@"Add_icon"] forState:UIControlStateNormal];
            } else {
                NSString *emoji = emojis[row - (flag ? 1 : 0)];
                [button addTarget:self action:@selector(emojiClicked:) forControlEvents:UIControlEventTouchUpInside];
                [button setTitle:emoji forState:UIControlStateNormal];
                [button setImage:nil forState:UIControlStateNormal];
            }
            button.titleLabel.font = [UIFont systemFontOfSize:120];
        }
        return;
    }

    // Clean
    for (UIView *view in self.buttons) {
        [view removeFromSuperview];
    }
    [self.buttons removeAllObjects];
    
    for (int row = 0; row < numberOfRows; row ++) {
        CGRect frame = CGRectMake(verticalMargin + row * (verticalMargin + buttonSize), horizontalMargin, buttonSize, buttonSize);
        UIButton *button = [[UIButton alloc] initWithFrame:frame];
        button.titleLabel.numberOfLines = 1;
        button.titleLabel.font = [UIFont systemFontOfSize:120.0];
        button.titleLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
        button.titleLabel.adjustsFontSizeToFitWidth = YES;
        if (flag && row == 0) {
            [button addTarget:self action:@selector(unlockClicked) forControlEvents:UIControlEventTouchUpInside];
            [button setTitle:@"" forState:UIControlStateNormal];
            [button setImage:[UIImage imageNamed:@"Add_icon"] forState:UIControlStateNormal];
        } else {
            NSString *emoji = emojis[row - (flag ? 1 : 0)];
            [button addTarget:self action:@selector(emojiClicked:) forControlEvents:UIControlEventTouchUpInside];
            [button setTitle:emoji forState:UIControlStateNormal];
            [button setImage:nil forState:UIControlStateNormal];
        }
        button.transform = CGAffineTransformMakeRotation(M_PI/2);
        [self addSubview:button];
        [self.buttons addObject:button];
    }
}

- (void)emojiClicked:(UIButton *)sender {
    [self.delegate emojiClicked:sender.titleLabel.text];
}

- (void)unlockClicked {
    [self.delegate unlockClicked];
}

                    
@end
