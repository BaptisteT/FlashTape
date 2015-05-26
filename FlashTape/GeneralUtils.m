//
//  GeneralUtils.m
//  FlashTape
//
//  Created by Baptiste Truchot on 4/27/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
#import <AVFoundation/AVFoundation.h>

#import "ConstantUtils.h"
#import "GeneralUtils.h"

#define LAST_VIDEO_SEEN_DATE @"Last Video Seen Date"
#define LAST_CLEANING_DATE @"Last Cleaning Date"
#define LAST_VIDEO_SELFIE_MODE @"Last Video Selfie Mode"

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

+ (void)deleteStoredData
{
    NSString *tmpDirectory = NSTemporaryDirectory();
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    NSArray *cacheFiles = [fileManager contentsOfDirectoryAtPath:tmpDirectory error:&error];
    for (NSString *file in cacheFiles)
    {
        error = nil;
        if (![fileManager removeItemAtPath:[tmpDirectory stringByAppendingPathComponent:file] error:&error]) {
            NSLog(@"Error deleting: %@",error);
        }
    }
}

+ (BOOL)shouldDeleteStoredData {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSDate *previousDate = [prefs objectForKey:LAST_CLEANING_DATE] ? [prefs objectForKey:LAST_CLEANING_DATE]: [NSDate date];
    [prefs setObject:[NSDate date] forKey:LAST_CLEANING_DATE];
    return [[previousDate dateByAddingTimeInterval:kDaysBetweenCashCleaning*24*3600] compare:[NSDate date]]== NSOrderedAscending;
}

+ (void)removeFile:(NSURL *)fileURL
{
    NSString *filePath = [fileURL path];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:filePath]) {
        NSError *error;
        if ([fileManager removeItemAtPath:filePath error:&error] == NO) {
            NSLog(@"removeItemAtPath %@ error:%@", filePath, error);
        }
    }
}

+ (BOOL)isiPhone4
{
    return [[UIScreen mainScreen] bounds].size.height == 480;
}

+ (void)saveLastVideoSelfieModePref:(BOOL)selfieMode
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:[NSNumber numberWithBool:selfieMode] forKey:LAST_VIDEO_SELFIE_MODE];
    [prefs synchronize];
}

+ (BOOL)getLastVideoSelfieModePref
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    return [prefs objectForKey:LAST_VIDEO_SELFIE_MODE] ? [[prefs objectForKey:LAST_VIDEO_SELFIE_MODE ] boolValue] : YES;
}

@end
