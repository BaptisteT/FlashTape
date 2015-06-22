//
//  ReadMessageViewController.h
//  FlashTape
//
//  Created by Baptiste Truchot on 6/7/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "FlashTapeParentViewController.h"

@class SendMessageViewController;
@class User;

@protocol ReadMessageVCDelegate;

@interface ReadMessageViewController : FlashTapeParentViewController

@property (strong, nonatomic) NSMutableArray *messagesArray;
@property (strong, nonatomic) User *messageSender;
@property (weak, nonatomic) id<ReadMessageVCDelegate> delegate;
@end

@protocol ReadMessageVCDelegate

- (SendMessageViewController *)sendMessageController;

@end
