//
//  FriendsViewController.h
//  FlashTape
//
//  Created by Baptiste Truchot on 5/13/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
#import <FBSDKShareKit/FBSDKShareKit.h>
#import <UIKit/UIKit.h>

@protocol FriendsVCProtocol;

@interface FriendsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, FBSDKAppInviteDialogDelegate>

@property (weak, nonatomic) id<FriendsVCProtocol> delegate;
@property (weak, nonatomic) NSDictionary *contactDictionnary;

@end

@protocol FriendsVCProtocol

- (void)hideUIElementOnCamera:(BOOL)flag;

@end