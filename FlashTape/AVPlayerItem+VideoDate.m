//
//  AVPlayerItem+VideoDate.m
//  FlashTape
//
//  Created by Baptiste Truchot on 4/27/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
#import <objc/runtime.h>

#import "AVPlayerItem+VideoDate.h"

NSString const *videoCreationDateKey = @"video.creation.date.key";
NSString const *indexInVideoArrayKey = @"index.in.array.key";

@implementation AVPlayerItem (VideoDate)

- (NSDate *)videoCreationDate
{
    return objc_getAssociatedObject(self, &videoCreationDateKey);
}

- (void)setVideoCreationDate:(NSDate *)videoCreationDate {
    objc_setAssociatedObject(self, &videoCreationDateKey, videoCreationDate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSInteger)indexInVideoArray {
    return [objc_getAssociatedObject(self, &indexInVideoArrayKey) integerValue];
}

- (void)setIndexInVideoArray:(NSInteger)indexInVideoArray {
    objc_setAssociatedObject(self, &indexInVideoArrayKey, [NSNumber numberWithInteger:indexInVideoArray], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
