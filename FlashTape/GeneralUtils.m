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

#define SAVE_STORY_EXPLANATION_HIDDEN_PREF @"Save Story Explanation Hidden"
#define MUTE_EXPLANATION_HIDDEN_PREF @"Mute Explanation Hidden"
#define DELETE_EXPLANATION_HIDDEN_PREF @"Delete Explanation Hidden"

#define LAST_UNFOLLOWED_FOLLOWER_RETRIEVE_DATE @"Last Unfollowed Follower Retrieve Date"
#define NEW_UNFOLLOWED_FOLLOWER_COUNT @"New Unfollowed Follower Count"
#define LAST_ADDRESSBOOK_FLASHER_RETRIEVE_DATE @"Last Addressbook Flashers Retrieve Date"
#define NEW_ADDRESSBOOK_FLASHER_COUNT @"New Addressbook Flashers Count"

#define RATE_ALERT_ACCEPTED @"Rate Alert Accepted"

#define HIDE_SKIP_CONTACT @"Hide Skip Contact Pref"


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

+ (BOOL)isIOS7
{
    return [[[UIDevice currentDevice] systemVersion] floatValue] < 8.0;
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

+ (void)setSaveStoryExplanationHidden:(BOOL)hide
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:[NSNumber numberWithBool:hide] forKey:SAVE_STORY_EXPLANATION_HIDDEN_PREF];
    [prefs synchronize];
}

+ (BOOL)explainBeforeSavingStory
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    return [prefs objectForKey:SAVE_STORY_EXPLANATION_HIDDEN_PREF] ? ![[prefs objectForKey:SAVE_STORY_EXPLANATION_HIDDEN_PREF] boolValue] : YES;
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

+ (NSDate *)getLastUnfollowedFollowerRetrieveDate
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    return [prefs objectForKey:LAST_UNFOLLOWED_FOLLOWER_RETRIEVE_DATE] ? [prefs objectForKey:LAST_UNFOLLOWED_FOLLOWER_RETRIEVE_DATE] : [NSDate date];
}

+ (void)setLastUnfollowedFollowerRetrieveDate:(NSDate *)date
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:date forKey:LAST_UNFOLLOWED_FOLLOWER_RETRIEVE_DATE];
    [prefs synchronize];
}

+ (NSDate *)getLastAddressBookFlasherRetrieveDate
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    return [prefs objectForKey:LAST_ADDRESSBOOK_FLASHER_RETRIEVE_DATE] ? [prefs objectForKey:LAST_ADDRESSBOOK_FLASHER_RETRIEVE_DATE] : [NSDate date];
}

+ (void)setLastAddressBookFlasherRetrieveDate:(NSDate *)date
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:date forKey:LAST_ADDRESSBOOK_FLASHER_RETRIEVE_DATE];
    [prefs synchronize];
}

+ (NSInteger)getNewUnfollowedFollowerCount
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    return [prefs objectForKey:NEW_UNFOLLOWED_FOLLOWER_COUNT] ? [[prefs objectForKey:NEW_UNFOLLOWED_FOLLOWER_COUNT] integerValue]: 0;
}

+ (void)setNewUnfollowedFollowerCount:(NSInteger)count
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:[NSNumber numberWithInteger:count] forKey:NEW_UNFOLLOWED_FOLLOWER_COUNT];
    [prefs synchronize];
}

+ (NSInteger)getNewAddressbookFlasherCount
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    return [prefs objectForKey:NEW_ADDRESSBOOK_FLASHER_COUNT] ? [[prefs objectForKey:NEW_ADDRESSBOOK_FLASHER_COUNT] integerValue]: 0;
}

+ (void)setNewNewAddressbookFlasherCount:(NSInteger)count
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:[NSNumber numberWithInteger:count] forKey:NEW_ADDRESSBOOK_FLASHER_COUNT];
    [prefs synchronize];
}

+ (void)setRatingAlertAccepted
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:[NSNumber numberWithBool:YES] forKey:RATE_ALERT_ACCEPTED];
    [prefs synchronize];
}

+ (NSInteger)getRatingAlertAcceptedPref
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    return [prefs objectForKey:RATE_ALERT_ACCEPTED] ? [[prefs objectForKey:RATE_ALERT_ACCEPTED] boolValue] : NO;
}

+ (BOOL)shouldPresentRateAlert:(NSInteger)score
{
    return (score % 10 == 0 && ![GeneralUtils getRatingAlertAcceptedPref]);
}

+ (void)setSkipContactPref
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:[NSNumber numberWithBool:true] forKey:HIDE_SKIP_CONTACT];
    [prefs synchronize];
}

+ (BOOL)getSkipContactPref
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    return [[prefs objectForKey:HIDE_SKIP_CONTACT] boolValue];
}

@end
