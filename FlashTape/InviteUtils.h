//
//  InviteUtils.h
//  FlashTape
//
//  Created by Baptiste Truchot on 6/29/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ABContact;

@interface InviteUtils : NSObject

+ (ABContact *)contactToBePresented;

+ (BOOL)shouldPresentInviteController;

+ (NSDate *)getLastInvitePresentedDate;

+ (void)setLastInvitePresentedDate:(NSDate *)date;

+ (NSInteger)getInvitePresentedCount;

+ (void)incrementInvitePresentedCount;


@end