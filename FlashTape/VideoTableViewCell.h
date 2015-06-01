//
//  VideoTableViewCell.h
//  FlashTape
//
//  Created by Baptiste Truchot on 5/27/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol VideoTVCDelegate;
@class VideoPost;

@interface VideoTableViewCell : UITableViewCell

@property (strong, nonatomic) id<VideoTVCDelegate> delegate;
- (void)initWithPost:(VideoPost *)post detailedState:(BOOL)detailedState viewerNames:(NSArray *)names;

@end

@protocol VideoTVCDelegate

- (void)deleteButtonClicked:(VideoPost *)post;

@end