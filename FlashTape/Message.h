//
//  Message.h
//  FlashTape
//
//  Created by Baptiste Truchot on 6/1/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <Parse/parse.h>

#import "User.h"

@interface Message : PFObject<PFSubclassing>

@property (retain) User *sender;
@property (retain) User *receiver;
@property (retain) NSString *messageContent;
@property (nonatomic) BOOL read;

+ (Message *)createMessageWithContent:(NSString *)messageContent
                             receiver:(User *)receiver;

@end
