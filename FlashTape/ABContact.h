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

+ (ABContact *)createRelationWithNumber:(NSString *)number;

@end
