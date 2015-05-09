//
//  GeneralUtils.m
//  FlashTape
//
//  Created by Baptiste Truchot on 4/27/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
#import <AVFoundation/AVFoundation.h>

#import "GeneralUtils.h"

#define LAST_VIDEO_SEEN_DATE @"Last Video Seen Date"

@implementation GeneralUtils

+ (void)saveLastVideoSeenDate:(NSDate *)date
{
    if (!date)
        return;
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSDate *maxDate = [date compare:[GeneralUtils getLastVideoSeenDate]] == NSOrderedAscending ? [GeneralUtils getLastVideoSeenDate] : date;
    [prefs setObject:maxDate forKey:LAST_VIDEO_SEEN_DATE];
    [prefs synchronize];
}

+ (NSDate *)getLastVideoSeenDate
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    return [prefs objectForKey:LAST_VIDEO_SEEN_DATE] ? [prefs objectForKey:LAST_VIDEO_SEEN_DATE]: [NSDate dateWithTimeIntervalSince1970:0];
}

+ (UIImage *)generateThumbImage:(NSURL *)url
{
    AVAsset *asset = [AVAsset assetWithURL:url];
    AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc]initWithAsset:asset];
    CMTime time = [asset duration];
    time.value = 0;
    CGImageRef imageRef = [imageGenerator copyCGImageAtTime:time actualTime:NULL error:NULL];
    UIImage *thumbnail = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);  // CGImageRef won't be released by ARC
    return thumbnail;
}

// Show an alert message
+ (void)showMessage:(NSString *)text withTitle:(NSString *)title
{
    [[[UIAlertView alloc] initWithTitle:title ? title : @""
                                message:text ? text : @""
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
}

@end
