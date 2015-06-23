//
//  Follow.h
//  FlashTape
//
//  Created by Baptiste Truchot on 6/22/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/parse.h>

#import "User.h"

@interface Follow : PFObject<PFSubclassing>

@property (retain) User *from;
@property (retain) User *to;
@property (nonatomic) BOOL mute;
@property (nonatomic) BOOL blocked;

+ (Follow *)createRelationWithFollowing:(User *)user;

@end
