//
//  InviteContactTableViewCell.h
//  FlashTape
//
//  Created by Baptiste Truchot on 6/23/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol InviteContactTVCDelegate;

@class ABContact;

@interface InviteContactTableViewCell : UITableViewCell

@property (weak, nonatomic) id<InviteContactTVCDelegate> delegate;

- (void)initWithName:(NSString *)name
             contact:(ABContact *)contact
            firstRow:(BOOL)firstRow;
@end

@protocol InviteContactTVCDelegate

- (void)inviteUser:(ABContact *)contact;

@end