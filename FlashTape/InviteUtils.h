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

+ (void)pickContactsToPresent:(NSInteger)count
                      success:(void(^)(NSArray *contacts))successBlock
                      failure:(void(^)(NSError *error))failureBlock;

+ (BOOL)shouldPresentInviteController;

+ (void)incrementVideoSeenSinceLastInvitePresentedCount;

+ (void)resetVideoSeenSinceLastInvitePresentedCount;


@end
