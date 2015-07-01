//
//  ABContact.h
//  FlashTape
//
//  Created by Baptiste Truchot on 6/29/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/parse.h>

#import "User.h"

@interface ABContact : PFObject<PFSubclassing>

@property (retain) NSString *number;
@property (retain) NSArray *users;
@property (nonatomic) NSInteger inviteCount;
@property (nonatomic) NSInteger inviteSeenCount;
@property (nonatomic) BOOL isFlasher;

+ (ABContact *)createRelationWithNumber:(NSString *)number;

- (CGFloat)contactScore;

@end
