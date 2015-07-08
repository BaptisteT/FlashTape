//
//  GeneralUtils.h
//  FlashTape
//
//  Created by Baptiste Truchot on 4/27/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//

@import Foundation;
@import UIKit;

@interface GeneralUtils : NSObject

+ (UIImage *)generateThumbImage:(NSURL *)url;

// Show an alert message
+ (void)showAlertMessage:(NSString *)text withTitle:(NSString *)title;

// Show message on top of view
+ (void)displayTopMessage:(NSString *)message onView:(UIView *)superView;

+ (void)removeFile:(NSURL *)fileURL;

+ (BOOL)isiPhone4;

+ (BOOL)isIOS7;

+ (NSString *)transformedUsernameFromOriginal:(NSString *)original;

+ (void)openSettings;

+ (void)setMuteExplanationHidden:(BOOL)hide;

+ (BOOL)explainBeforeMute;

+ (void)setDeleteExplanationHidden:(BOOL)hide;

+ (BOOL)explainBeforeDelete;

+ (void)setSaveStoryExplanationHidden:(BOOL)hide;

+ (BOOL)explainBeforeSavingStory;

+ (NSDate *)getLastUnfollowedFollowerRetrieveDate;

+ (void)setLastUnfollowedFollowerRetrieveDate:(NSDate *)date;

+ (NSDate *)getLastAddressBookFlasherRetrieveDate;

+ (void)setLastAddressBookFlasherRetrieveDate:(NSDate *)date;

+ (NSInteger)getNewUnfollowedFollowerCount;

+ (void)setNewUnfollowedFollowerCount:(NSInteger)count;

+ (NSInteger)getNewAddressbookFlasherCount;

+ (void)setNewNewAddressbookFlasherCount:(NSInteger)count;

+ (void)setRatingAlertAccepted;

+ (BOOL)shouldPresentRateAlert:(NSInteger)score;

@end
