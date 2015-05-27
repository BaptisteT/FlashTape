//
//  VideoTableViewCell.m
//  FlashTape
//
//  Created by Baptiste Truchot on 5/27/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
#import "VideoPost.h"

#import "VideoTableViewCell.h"

#import "GeneralUtils.h"
#import "NSDate+DateTools.h"

@interface VideoTableViewCell()

@property (strong, nonatomic) VideoPost *post;
@property (weak, nonatomic) IBOutlet UIImageView *videoThumbmail;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;

@end

@implementation VideoTableViewCell

- (void)initWithPost:(VideoPost *)post {
    self.post = post;
    if (!post.thumbmail) {
        post.thumbmail = [GeneralUtils generateThumbImage:post.localUrl];
    }
    self.videoThumbmail.image = post.thumbmail;
    self.videoThumbmail.contentMode = UIViewContentModeScaleAspectFill;
    self.videoThumbmail.layer.cornerRadius = self.videoThumbmail.frame.size.height / 2;
    self.videoThumbmail.clipsToBounds = YES;
    self.timeLabel.text = [post.createdAt shortTimeAgoSinceNow];
}

- (IBAction)deletButtonClicked:(id)sender {
    self.deleteButton.enabled = NO;
    [self.delegate deletePost:self.post];
}

@end
