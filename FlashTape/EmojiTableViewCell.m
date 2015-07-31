//
//  EmojiTableViewCell.m
//  FlashTape
//
//  Created by Baptiste Truchot on 7/28/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//

#import "EmojiTableViewCell.h"

#import "ConstantUtils.h"
#import "GeneralUtils.h"

@interface EmojiTableViewCell()

@property (strong, nonatomic) NSArray *buttons;
@property (weak, nonatomic) IBOutlet UIButton *emojiButton1;
@property (weak, nonatomic) IBOutlet UIButton *emojiButton2;
@property (weak, nonatomic) IBOutlet UIButton *emojiButton3;
@property (weak, nonatomic) IBOutlet UIButton *emojiButton4;
@property (weak, nonatomic) IBOutlet UIButton *emojiButton5;
@property (weak, nonatomic) IBOutlet UIButton *emojiButton6;

@end

@implementation EmojiTableViewCell

- (void)initWithEmojis:(NSArray *)emojis isUnlockRow:(BOOL)flag
{
    if (!emojis || emojis.count < kNumberOfEmojisByColumn) {
        return;
    }
    self.backgroundColor = [UIColor clearColor];
    self.contentView.backgroundColor = [ UIColor clearColor];
    
    self.buttons = [NSArray arrayWithObjects:self.emojiButton1,self.emojiButton2,self.emojiButton3,self.emojiButton4,self.emojiButton5,self.emojiButton6,nil];
   
    for (UIButton *button in self.buttons) {
        button.titleLabel.numberOfLines = 1;
        button.titleLabel.font = [UIFont systemFontOfSize:120.0];
        button.titleLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
        button.titleLabel.adjustsFontSizeToFitWidth = YES;
        if (flag && button == self.buttons.firstObject) {
            [button addTarget:self action:@selector(unlockClicked) forControlEvents:UIControlEventTouchUpInside];
            [button setTitle:@"" forState:UIControlStateNormal];
            [button setImage:[UIImage imageNamed:@"Add_icon"] forState:UIControlStateNormal];
        } else {
            NSString *emoji = emojis[[self.buttons indexOfObject:button] - (flag ? 1 : 0)];
            [button addTarget:self action:@selector(emojiClicked:) forControlEvents:UIControlEventTouchUpInside];
            [button setTitle:emoji forState:UIControlStateNormal];
            [button setImage:nil forState:UIControlStateNormal];
        }
        button.transform = CGAffineTransformMakeRotation(M_PI/2);
    }
    
}

- (IBAction)emojiClicked:(id)sender {
    [self.delegate emojiClicked:((UIButton *)sender).titleLabel.text];
}

- (void)unlockClicked {
    [self.delegate unlockClicked];
}

                    
@end
