//
//  FriendsViewController.h
//  FlashTape
//
//  Created by Baptiste Truchot on 5/13/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//

#import <MessageUI/MessageUI.h>
#import <UIKit/UIKit.h>

#import "CreateMessageTableViewCell.h"
#import "FriendTableViewCell.h"
#import "VideoTableViewCell.h"

@class VideoPost;
@protocol FriendsVCProtocol;

@interface FriendsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, MFMessageComposeViewControllerDelegate, VideoTVCDelegate, FriendTVCDelegate, UIAlertViewDelegate, CreateMessageTVCDelegate >

@property (weak, nonatomic) id<FriendsVCProtocol> delegate;
@property (strong, nonatomic) NSMutableArray *friends;
@property (strong, nonatomic) NSDictionary *contactDictionnary;

@end

@protocol FriendsVCProtocol

- (void)hideUIElementOnCamera:(BOOL)flag;
//- (void)playOneFriendVideos:(NSArray *)videos;
- (void)removeVideoFromVideosArray:(VideoPost *)video;
- (void)setMessagesLabel:(NSInteger)count;

@end