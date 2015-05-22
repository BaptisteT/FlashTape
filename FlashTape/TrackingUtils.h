//
//  TrackingUtils.h
//  FlashTape
//
//  Created by Baptiste Truchot on 5/10/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TrackingUtils : NSObject

+ (void)trackVideoSent;

+ (void)trackVideoSendingFailure;

+ (void)trackVideoSeen;

+ (void)trackReplayButtonClicked;

+ (void)trackOpenApp;

+ (void)trackInviteButtonClicked;

@end
