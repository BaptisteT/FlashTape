//
//  ConstantUtils.h
//  FlashTape
//
//  Created by Baptiste Truchot on 4/25/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//

@import Foundation;
@import UIKit;

@interface ConstantUtils : NSObject

@end

// System
static NSString * const kFlashTapeAppStoreLink = @"http://beta.flashtape.co";
static NSString * const kFlashTapeWebsiteLink = @""; // todo BT

//Flurry token
static NSString * const kProdFlurryToken = @"5PFZ5RNNFKH6J6D6V4ZY";

//Mixpanel token
static NSString * const kMixpanelToken = @"51d7f02e924b3babe98ea09ca2dd423b";

// Parse
static NSString * const kParsePostsName = @"Posts";
static NSString * const kParseFollowingName = @"Friends";
static NSString * const kParseFollowersName = @"Followers";
static NSString * const kParseMessagesName = @"Messages";

// Download / feed
static NSInteger const kMaxConcurrentVideoDownloadingCount = 20;
static NSInteger const kDelayBeforeRetryDownload = 3;
static const NSInteger kFeedHistoryInHours = 24;

// Recording
static const float kRecordSessionMaxDuration = 2.0;
static const float kRecordMinDuration = 0.25;
static const float kVideoEndCutDuration = 0.1;
static const NSInteger kMaxScoreBeforeHidingTuto = 20;

// Playing
static const NSInteger kPlayerQueueLength = 3;

// Top message
static const float kTopMessageViewHeight = 20;
static const float kTopMessageLabelHeight = 20;
static const float kTopMessageAnimDuration = 0.5;
static const float kTopMessageAnimDelay = 1.5;

// Messaging
static const NSInteger kMaxMessageLength = 100;
static const NSInteger kMessageReceivedMaxFontSize = 50;
static const NSInteger kEmojiMaxFontSize = 250;

// User
static const NSInteger kUsernameMinLength = 3;

// Cell
static const NSInteger kVideoCellHeight = 50;
static const NSInteger kVideoCellViewerAdditionalHeight = 20;

NSString * getEmojiAtIndex(NSInteger index);
BOOL belonsToEmojiArray(NSString *emoji) ;
