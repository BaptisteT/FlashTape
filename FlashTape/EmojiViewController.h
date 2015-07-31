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

- (void)reloadEmojis;

@property (weak, nonatomic) id<EmojiVCDelegate> delegate;

@end

@protocol EmojiVCDelegate

- (void)emojiClicked:(NSString *)emoji;

@end