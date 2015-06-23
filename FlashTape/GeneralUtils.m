//
//  GeneralUtils.m
//  FlashTape
//
//  Created by Baptiste Truchot on 4/27/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
#import <AVFoundation/AVFoundation.h>

#import "ApiManager.h"

#import "ConstantUtils.h"
#import "GeneralUtils.h"

#define MUTE_EXPLANATION_HIDDEN_PREF @"Mute Explanation Hidden"
#define DELETE_EXPLANATION_HIDDEN_PREF @"Delete Explanation Hidden"


@implementation GeneralUtils

+ (UIImage *)generateThumbImage:(NSURL *)url
{
    AVAsset *asset = [AVAsset assetWithURL:url];
    if (!asset) return nil;
    
    AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc]initWithAsset:asset];
    CMTime time = [asset duration];
    time.value = 0;
    CGImageRef imageRef = [imageGenerator copyCGImageAtTime:time actualTime:NULL error:NULL];
    UIImage *thumbnail = [UIImage imageWithCGImage:imageRef scale:4.0 orientation:UIImageOrientationUp];
    CGImageRelease(imageRef);  // CGImageRef won't be released by ARC
    return thumbnail;
}

// Show an alert message
+ (void)showAlertMessage:(NSString *)text withTitle:(NSString *)title
{
    [[[UIAlertView alloc] initWithTitle:title ? title : @""
                                message:text ? text : @""
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
}

// Show message on top of view
+ (void)displayTopMessage:(NSString *)message onView:(UIView *)superView
{
    UIView *messageView = [[UIView alloc] initWithFrame:CGRectMake(0, - kTopMessageViewHeight, superView.frame.size.width, kTopMessageViewHeight)];
    messageView.backgroundColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:0.8];
    UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, messageView.frame.size.height - kTopMessageLabelHeight, messageView.frame.size.width - 20 - 5, kTopMessageLabelHeight)];
    messageLabel.textAlignment = NSTextAlignmentCenter;
    messageLabel.text = message;
    messageLabel.font = [UIFont systemFontOfSize:14];
    messageLabel.textColor = [UIColor whiteColor];
    [messageView addSubview:messageLabel];
    [superView addSubview:messageView];
    [UIView animateWithDuration:kTopMessageAnimDuration
                     animations:^(){
                         messageView.frame = CGRectMake(0, 0, messageView.frame.size.width, kTopMessageViewHeight);
                     } completion:^(BOOL completed) {
                         if (completed) {
                             [UIView animateWithDuration:kTopMessageAnimDuration
                                                   delay:kTopMessageAnimDelay
                                                 options:UIViewAnimationOptionCurveLinear
                                              animations:^(){
                                                  messageView.frame = CGRectMake(0, - kTopMessageViewHeight, messageView.frame.size.width, kTopMessageViewHeight);
                                              } completion:^(BOOL completed) {
                                                  [messageView removeFromSuperview];
                                              }];
                         } else {
                             [messageView removeFromSuperview];
                         }
                     }];
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

+ (void)setMuteExplanationHidden:(BOOL)hide
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:[NSNumber numberWithBool:hide] forKey:MUTE_EXPLANATION_HIDDEN_PREF];
    [prefs synchronize];
}

+ (BOOL)explainBeforeMute
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    return [prefs objectForKey:MUTE_EXPLANATION_HIDDEN_PREF] ? ![[prefs objectForKey:MUTE_EXPLANATION_HIDDEN_PREF] boolValue] : YES;
}

+ (void)setDeleteExplanationHidden:(BOOL)hide
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:[NSNumber numberWithBool:hide] forKey:DELETE_EXPLANATION_HIDDEN_PREF];
    [prefs synchronize];
}

+ (BOOL)explainBeforeDelete
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    return [prefs objectForKey:DELETE_EXPLANATION_HIDDEN_PREF] ? ![[prefs objectForKey:DELETE_EXPLANATION_HIDDEN_PREF] boolValue] : YES;
}


+ (NSString *)transformedUsernameFromOriginal:(NSString *)original {
    NSMutableString *transformedUsername = [original mutableCopy];
    CFStringTransform((__bridge CFMutableStringRef)transformedUsername, NULL, kCFStringTransformStripCombiningMarks, NO);
    return [transformedUsername lowercaseString];
}

+ (void)openSettings
{
    BOOL canOpenSettings = (&UIApplicationOpenSettingsURLString != NULL);
    if (canOpenSettings) {
        NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        [[UIApplication sharedApplication] openURL:url];
    }
}

@end
