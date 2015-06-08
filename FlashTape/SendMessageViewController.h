//
//  SendMessageViewController.h
//  FlashTape
//
//  Created by Baptiste Truchot on 6/7/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SendMessageVCDelegate;

@class User;

@interface SendMessageViewController : UIViewController <UITextViewDelegate>

@property (strong, nonatomic) User *messageRecipient;
@property (strong, nonatomic) id<SendMessageVCDelegate> delegate;

@end

@protocol SendMessageVCDelegate

- (void)sendMessage:(NSString *)text toUser:(User *)user;
- (void)closeReadAndMessageViews;

@end
