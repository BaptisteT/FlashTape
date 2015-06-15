//
//  VideoTableViewCell.m
//  FlashTape
//
//  Created by Baptiste Truchot on 5/27/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
#import "DatastoreUtils.h"
#import "VideoPost.h"

#import "VideoTableViewCell.h"

#import "ConstantUtils.h"
#import "GeneralUtils.h"
#import "NSDate+DateTools.h"

@interface VideoTableViewCell()

@property (strong, nonatomic) VideoPost *post;
@property (weak, nonatomic) IBOutlet UIImageView *videoThumbmail;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *viewsLabel;
@property (strong, nonatomic) NSMutableArray *viewerNamesLabel;
@property (strong, nonatomic) IBOutlet UIView *separatorView;

@end

@implementation VideoTableViewCell

- (void)initWithPost:(VideoPost *)post detailedState:(BOOL)detailedState viewerNames:(NSArray *)names {
    if (!self.post || self.post != post) {
        self.post = post;
        self.deleteButton.enabled = YES;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if (!post.thumbmail) {
                post.thumbmail = [GeneralUtils generateThumbImage:post.localUrl];
            }
            // update UI on the main thread
            dispatch_async(dispatch_get_main_queue(), ^{
                self.videoThumbmail.image = post.thumbmail;
            });
        });
        self.videoThumbmail.contentMode = UIViewContentModeScaleAspectFill;
        self.videoThumbmail.layer.cornerRadius = self.videoThumbmail.frame.size.height / 2;
        self.videoThumbmail.clipsToBounds = YES;
    }
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm"];
    NSString *stringDate = [dateFormatter stringFromDate:post.recordedAt];
    self.timeLabel.text = stringDate;
    self.viewsLabel.hidden = detailedState;
    self.deleteButton.hidden = !detailedState;
    
    if (!self.viewerNamesLabel) {
        self.viewerNamesLabel = [NSMutableArray new];
    }
    
    // Clean previous names if any
    for (UILabel *nameLabel in self.viewerNamesLabel) {
        [nameLabel removeFromSuperview];
    }
    [self.viewerNamesLabel removeAllObjects];
    
    // detail UI
    if (!detailedState) {
        NSInteger viewsCount = [post viewerIdsArrayWithoutPoster].count;
        self.viewsLabel.text = [NSString stringWithFormat:NSLocalizedString(@"story_views_label", nil),viewsCount];
    } else {
        NSArray *names = [DatastoreUtils getNamesOfUsersWithId:[post viewerIdsArrayWithoutPoster]];
        int ii = 0;
        for (NSString *name in names) {
            [self addLabelWithName:name yPosition:kVideoCellHeight+kVideoCellViewerAdditionalHeight*ii];
            ii ++;
        }
    }
}

- (void)addLabelWithName:(NSString *)name yPosition:(CGFloat)yPosition {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(self.videoThumbmail.frame.origin.x, yPosition, self.frame.size.width - 2 * self.videoThumbmail.frame.origin.x, kVideoCellViewerAdditionalHeight)];
    label.text = name;
    label.textColor = [UIColor whiteColor];
    label.minimumScaleFactor = 2;
    label.font = [UIFont fontWithName:@"NHaasGroteskDSPro-65Md" size:12];
    [self.viewerNamesLabel addObject:label];
    [self addSubview:label];
}

- (IBAction)deletButtonClicked:(id)sender {
    self.deleteButton.enabled = NO;
    [self.delegate deleteButtonClicked:self.post];
    self.deleteButton.enabled = YES;
}


@end
