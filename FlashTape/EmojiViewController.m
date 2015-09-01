//
//  EmojiViewController.m
//  FlashTape
//
//  Created by Baptiste Truchot on 7/28/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
#import "User.h"

#import "EmojiViewController.h"

#import "ConstantUtils.h"

@interface EmojiViewController ()

@property (weak, nonatomic) IBOutlet PTEHorizontalTableView *horizontalTableView;

@end

@implementation EmojiViewController

// --------------------------------------------
#pragma mark - Tableview
// --------------------------------------------
- (void)viewDidAppear:(BOOL)animated {
    [self resetFrame];
    [super viewDidAppear:animated];
}

// --------------------------------------------
#pragma mark - Tableview
// --------------------------------------------

- (void)reloadEmojis {
    [self resetFrame];
    [self.horizontalTableView.tableView reloadData];
}

- (void)resetFrame {
    self.horizontalTableView.frame = self.view.frame;
}

- (NSInteger)tableView:(PTEHorizontalTableView *)horizontalTableView numberOfRowsInSection:(NSInteger)section
{
    return (NSInteger)(self.emojiArray.count / kNumberOfEmojisByColumn);
}

- (UITableViewCell *)tableView:(PTEHorizontalTableView *)horizontalTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    EmojiTableViewCell * cell = [horizontalTableView.tableView dequeueReusableCellWithIdentifier:@"EmojiTableViewCell"];
    BOOL isUnlockRow = NO;
    
    NSRange range = NSMakeRange(indexPath.row * kNumberOfEmojisByColumn, kNumberOfEmojisByColumn - (isUnlockRow ? 1 : 0));
    if (range.length + range.location > self.emojiArray.count) {
        range = NSMakeRange(range.location, self.emojiArray.count - range.location);
    }
    NSArray *emojis = [self.emojiArray subarrayWithRange:range];
    [cell initWithEmojis:emojis isUnlockRow:isUnlockRow];
    cell.delegate = self;
    return cell;
}

- (CGFloat)tableView:(PTEHorizontalTableView *)horizontalTableView widthForCellAtIndexPath:(NSIndexPath *)indexPath{
    return self.view.frame.size.width / 4;
}

// --------------------------------------------
#pragma mark - Emoji TVC Delegate
// --------------------------------------------

- (void)emojiClicked:(NSString *)emoji {
    [self.delegate emojiClicked:emoji];
}

- (void)unlockClicked {
    [self performSegueWithIdentifier:@"Unlock From Emoji" sender:nil];
}


@end
