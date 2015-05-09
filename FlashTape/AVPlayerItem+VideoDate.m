//
//  AVPlayerItem+VideoDate.m
//  FlashTape
//
//  Created by Baptiste Truchot on 4/27/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
#import <objc/runtime.h>

#import "AVPlayerItem+VideoDate.h"

NSString const *videoPostKey = @"video.post.key";
NSString const *indexInVideoArrayKey = @"index.in.array.key";

@implementation AVPlayerItem (VideoDate)

- (VideoPost *)videoPost
{
    return objc_getAssociatedObject(self, &videoPostKey);
}

- (void)setVideoPost:(VideoPost *)videoPost {
    objc_setAssociatedObject(self, &videoPostKey, videoPost, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSInteger)indexInVideoArray {
    return [objc_getAssociatedObject(self, &indexInVideoArrayKey) integerValue];
}

- (void)setIndexInVideoArray:(NSInteger)indexInVideoArray {
    objc_setAssociatedObject(self, &indexInVideoArrayKey, [NSNumber numberWithInteger:indexInVideoArray], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
