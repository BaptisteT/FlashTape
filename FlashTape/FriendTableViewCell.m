//
//  FriendTableViewCell.m
//  FlashTape
//
//  Created by Baptiste Truchot on 5/26/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
#import "User.h"

#import "FriendTableViewCell.h"

@interface FriendTableViewCell()

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *scoreLabel;
@property (weak, nonatomic) IBOutlet UIImageView *seenImageView;

@end


@implementation FriendTableViewCell

- (void)initWithName:(NSString *)name
               score:(NSString *)score
       hasSeenVideos:(BOOL)hasSeenVideos {
    self.nameLabel.text = name;
    self.scoreLabel.text = score;
    self.seenImageView.hidden = !hasSeenVideos;
    self.backgroundColor = [UIColor clearColor];
}

@end
