//
//  EmojiTableViewCell.h
//  FlashTape
//
//  Created by Baptiste Truchot on 7/28/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol EmojiTVCDelegate;

@interface EmojiTableViewCell : UITableViewCell

@property (weak, nonatomic) id<EmojiTVCDelegate> delegate;

- (void)initWithEmojis:(NSArray *)emojis isUnlockRow:(BOOL)flag;

@end

@protocol EmojiTVCDelegate

- (void)emojiClicked:(NSString *)emoji;
- (void)unlockClicked;

@end