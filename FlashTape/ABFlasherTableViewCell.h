//
//  ABFlasherTableViewCell.h
//  FlashTape
//
//  Created by Baptiste Truchot on 6/28/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ABFlasherTVCDelegate;
@class User;

@interface ABFlasherTableViewCell : UITableViewCell

@property (weak, nonatomic) id<ABFlasherTVCDelegate> delegate;

- (void)initWithUser:(User *)flasher name:(NSString *)name state:(BOOL)toAdd;

@end

@protocol ABFlasherTVCDelegate

- (void)addUserToFlasherToAdd:(User *)user;
- (void)removeUserFromFlasherToAdd:(User *)user;

@end
