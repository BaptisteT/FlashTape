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


// Recording
static const float kRecordSessionMaxDuration = 2.0;
static const float kRecordTimerBarHeight = 60;
static const float kRecordMinDuration = 0.5;

// Playing
static const NSInteger kPlayerQueueLength = 3;

// Top message
static const float kTopMessageViewHeight = 40;
static const float kTopMessageLabelHeight = 20;
static const float kTopMessageAnimDuration = 0.5;
static const float kTopMessageAnimDelay = 1.5;