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

+ (void)saveLastVideoSelfieModePref:(BOOL)selfieMode;

+ (BOOL)getLastVideoSelfieModePref;

+ (NSString *)transformedUsernameFromOriginal:(NSString *)original;

+ (void)openSettings;

@end
