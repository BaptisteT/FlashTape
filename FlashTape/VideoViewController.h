//
//  VideoViewController.h
//  FlashTape
//
//  Created by Baptiste Truchot on 4/25/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//

@import Foundation;
@import UIKit;

#import "SCRecorder.h"

#import "EmojiViewController.h"
#import "FlashTapeParentViewController.h"
#import "FriendsViewController.h"

@interface VideoViewController : FlashTapeParentViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate, SCRecorderDelegate, UIGestureRecognizerDelegate, FriendsVCProtocol, UITextViewDelegate, UIAlertViewDelegate, EmojiVCDelegate>

@property (nonatomic) BOOL navigateDirectlyToFriends;
@property (nonatomic) BOOL isSignup;

- (void)retrieveFollowingLocallyAndVideosRemotely;

@end
