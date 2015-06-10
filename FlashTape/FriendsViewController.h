//
//  FriendsViewController.h
//  FlashTape
//
//  Created by Baptiste Truchot on 5/13/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//

#import <MessageUI/MessageUI.h>
#import <UIKit/UIKit.h>

#import "FriendTableViewCell.h"
#import "VideoTableViewCell.h"
#import "SendMessageViewController.h"
#import "ReadMessageViewController.h"

@class VideoPost;
@protocol FriendsVCProtocol;

@interface FriendsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, MFMessageComposeViewControllerDelegate, VideoTVCDelegate, FriendTVCDelegate, UIAlertViewDelegate, SendMessageVCDelegate, ReadMessageVCDelegate>

@property (weak, nonatomic) id<FriendsVCProtocol> delegate;
@property (strong, nonatomic) NSMutableArray *friends;

@end

@protocol FriendsVCProtocol

- (void)hideUIElementOnCamera:(BOOL)flag;
//- (void)playOneFriendVideos:(NSArray *)videos;
- (void)removeVideoFromVideosArray:(VideoPost *)video;
- (void)setMessagesLabel:(NSInteger)count;
- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion;
- (void)parseContactsAndFindFriendsIfAuthNotDetermined;

@end