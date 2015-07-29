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
#pragma mark - Life cycle
// --------------------------------------------


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self reloadEmojis];
}


// --------------------------------------------
#pragma mark - Tableview
// --------------------------------------------

- (void)reloadEmojis {
    self.horizontalTableView.frame = self.view.frame;
    [self.horizontalTableView.tableView reloadData];
}

- (NSInteger)tableView:(PTEHorizontalTableView *)horizontalTableView numberOfRowsInSection:(NSInteger)section
{
    return [User currentUser].emojiUnlocked ? (NSInteger)(emojiArrayCount() / kNumberOfEmojisByColumn) : kNumberOfColumns;
}

- (UITableViewCell *)tableView:(PTEHorizontalTableView *)horizontalTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    EmojiTableViewCell * cell = [horizontalTableView.tableView dequeueReusableCellWithIdentifier:@"EmojiTableViewCell"];
    
    BOOL isUnlockRow = ![User currentUser].emojiUnlocked && (indexPath.row == kNumberOfColumns - 1);
    
    NSArray *emojis = getEmojiAtRange(NSMakeRange(indexPath.row * kNumberOfEmojisByColumn, kNumberOfEmojisByColumn - (isUnlockRow ? 1 : 0)));
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
