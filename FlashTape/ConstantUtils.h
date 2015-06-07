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
static NSString * const kFlashTapeAppStoreLink = @"https://itunes.apple.com/us/app/id997449435";
static NSString * const kFlashTapeWebsiteLink = @""; // todo BT

// Parse
static NSString * const kParsePostsName = @"Posts";
static NSString * const kParseFriendsName = @"Friends";
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
static const float kMaxMessageLength = 100;

// User
static const NSInteger kUsernameMinLength = 3;
