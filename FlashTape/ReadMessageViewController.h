//
//  ReadMessageViewController.h
//  FlashTape
//
//  Created by Baptiste Truchot on 6/7/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//

#import <UIKit/UIKit.h>

@class User;

@protocol ReadMessageVCDelegate;

@interface ReadMessageViewController : UIViewController

@property (strong, nonatomic) NSMutableArray *messagesArray;
@property (strong, nonatomic) User *messageSender;
@property (weak, nonatomic) id<ReadMessageVCDelegate> delegate;
@end

@protocol ReadMessageVCDelegate

- (void)presentSendViewController:(User *)friend;

@end
