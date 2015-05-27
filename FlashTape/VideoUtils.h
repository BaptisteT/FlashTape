//
//  VideoUtils.h
//  FlashTape
//
//  Created by Baptiste Truchot on 5/27/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>

@interface VideoUtils : NSObject

+ (NSMutableArray *)fillComposition:(AVMutableComposition *)composition
                     withVideoPosts:(NSArray *)posts;

+ (void)saveVideoCompositionToCameraRoll:(AVComposition *)composition
                                 success:(void(^)())successBlock
                                 failure:(void(^)())failureBlock;


@end
