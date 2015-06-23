//
//  InviteContactTableViewCell.h
//  FlashTape
//
//  Created by Baptiste Truchot on 6/23/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol InviteContactTVCDelegate;

@interface InviteContactTableViewCell : UITableViewCell

@property (weak, nonatomic) id<InviteContactTVCDelegate> delegate;

- (void)initWithName:(NSString *)name number:(NSString *)number;
@end

@protocol InviteContactTVCDelegate

- (void)inviteButtonClicked:(NSString *)number;

@end