//
//  EmojiTableViewCell.m
//  FlashTape
//
//  Created by Baptiste Truchot on 7/28/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//

#import "EmojiTableViewCell.h"

#import "ConstantUtils.h"
#import "DesignUtils.h"
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
    if (!emojis) {
        return;
    }
    self.backgroundColor = [UIColor clearColor];
    self.contentView.backgroundColor = [ UIColor clearColor];
    
    if (!self.buttons || self.buttons.count != kNumberOfEmojisByColumn) {
        self.buttons = [NSArray arrayWithObjects:self.emojiButton1,self.emojiButton2,self.emojiButton3,self.emojiButton4,self.emojiButton5,self.emojiButton6,nil];
    }
   
    for (UIButton *button in self.buttons) {
        button.backgroundColor = [UIColor clearColor];
        button.transform = CGAffineTransformMakeRotation(M_PI/2);
        button.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        NSInteger fontSize = (IS_IPHONE_4_OR_LESS || IS_IPHONE_5) ? 60 : (IS_IPHONE_6P ? 80 : 70);
        button.titleLabel.font = [UIFont systemFontOfSize:fontSize];
        if (flag && button == self.buttons.firstObject) {
            [button addTarget:self action:@selector(unlockClicked) forControlEvents:UIControlEventTouchUpInside];
            [button setTitle:@"" forState:UIControlStateNormal];
            UIImage *image = [[UIImage imageNamed:@"unlock_icon"] imageWithAlignmentRectInsets:UIEdgeInsetsMake(-18, -18, -18, -18)];
            [button setBackgroundImage:image forState:UIControlStateNormal];
        } else {
            NSString *emoji = emojis[MAX(0,emojis.count - 1 - [self.buttons indexOfObject:button] + (flag ? 1 : 0))];
            [button setTitle:emoji forState:UIControlStateNormal];
            [button removeTarget:self action:@selector(unlockClicked) forControlEvents:UIControlEventTouchUpInside];
            [button addTarget:self action:@selector(emojiClicked:) forControlEvents:UIControlEventTouchUpInside];
            [button setBackgroundImage:nil forState:UIControlStateNormal];
        }
    }
    
}


- (IBAction)emojiClicked:(id)sender {
    [self.delegate emojiClicked:((UIButton *)sender).titleLabel.text];
}

- (void)unlockClicked {
    [self.delegate unlockClicked];
}

                    
@end
