//
//  User.h
//  FlashTape
//
//  Created by Baptiste Truchot on 5/6/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/parse.h>

@interface User : PFUser <PFSubclassing>

@property (nonatomic) NSInteger score;
@property (retain) NSString *flashUsername;
@property (retain) NSString *transformedUsername;

+ (User *)createUserWithNumber:(NSString *)phoneNumber;

+ (User *)currentUser;


@end
