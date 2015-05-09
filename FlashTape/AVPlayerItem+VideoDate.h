//
//  AVPlayerItem+VideoDate.h
//  FlashTape
//
//  Created by Baptiste Truchot on 4/27/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

#import "VideoPost.h"

@interface AVPlayerItem (VideoDate)

@property (strong, nonatomic) VideoPost *videoPost;
@property (nonatomic) NSInteger indexInVideoArray;

@end
