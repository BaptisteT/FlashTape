//
//  EmojiViewController.h
//  FlashTape
//
//  Created by Baptiste Truchot on 7/28/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "EmojiTableViewCell.h"
#import "PTEHorizontalTableView.h"

@protocol EmojiVCDelegate;

@interface EmojiViewController : UIViewController <PTETableViewDelegate, EmojiTVCDelegate>

- (void)resetFrame;
- (void)reloadEmojis;

@property (weak, nonatomic) id<EmojiVCDelegate> delegate;
@property (strong, nonatomic) NSArray *emojiArray;

@end

@protocol EmojiVCDelegate

- (void)emojiClicked:(NSString *)emoji;

@end