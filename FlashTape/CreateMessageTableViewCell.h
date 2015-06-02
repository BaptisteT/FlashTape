//
//  CreateMessageTableViewCell.h
//  FlashTape
//
//  Created by Baptiste Truchot on 6/2/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@protocol CreateMessageTVCDelegate;

@interface CreateMessageTableViewCell : UITableViewCell <UITextFieldDelegate>

@property (weak, nonatomic) id<CreateMessageTVCDelegate> delegate;

- (void)initWithDelegate:(id<CreateMessageTVCDelegate>)delegate;

@end

@protocol CreateMessageTVCDelegate <NSObject>

- (void)sendMessage:(NSString *)text;

@end