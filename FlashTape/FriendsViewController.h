//
//  FriendsViewController.h
//  FlashTape
//
//  Created by Baptiste Truchot on 5/13/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//

#import <MessageUI/MessageUI.h>
#import <UIKit/UIKit.h>

#import "FlashTapeParentViewController.h"
#import "FriendTableViewCell.h"
#import "VideoTableViewCell.h"
#import "SendMessageViewController.h"
#import "ReadMessageViewController.h"

@class VideoPost;
@protocol FriendsVCProtocol;

@interface FriendsViewController : FlashTapeParentViewController <UITableViewDataSource, UITableViewDelegate, MFMessageComposeViewControllerDelegate, VideoTVCDelegate, FriendTVCDelegate, UIAlertViewDelegate, SendMessageVCDelegate, ReadMessageVCDelegate>

@property (weak, nonatomic) id<FriendsVCProtocol> delegate;
@property (strong, nonatomic) NSMutableOrderedSet *followingRelations;

// On click on feed friend name
@property (strong, nonatomic) NSString *friendUsername;


@end

@protocol FriendsVCProtocol

- (void)hideUIElementOnCamera:(BOOL)flag;
- (void)playOneFriendVideos:(NSArray *)videos;
- (void)removeVideoFromVideosArray:(VideoPost *)video;
- (void)setMessageCount:(NSInteger)messageCount;
- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion;

@end