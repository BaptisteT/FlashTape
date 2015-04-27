//
//  AVPlayerItem+VideoDate.m
//  FlashTape
//
//  Created by Baptiste Truchot on 4/27/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
#import <objc/runtime.h>

#import "AVPlayerItem+VideoDate.h"

NSString const *key = @"my.very.unique.key";

@implementation AVPlayerItem (VideoDate)

- (NSDate *)videoCreationDate
{
    return objc_getAssociatedObject(self, &key);
}

- (void)setVideoCreationDate:(NSDate *)videoCreationDate {
    objc_setAssociatedObject(self, &key, videoCreationDate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
