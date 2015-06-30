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

typedef NS_ENUM(NSInteger,MessageStatus) {
    kMessageTypeNone = 0,
    kMessageTypeSending = 1,
    kMessageTypeFailed = 2,
    kMessageTypeSent = 3,
    kMessageTypeReceived = 4
};

@interface Message : PFObject<PFSubclassing>

@property (retain) User *sender;
@property (retain) User *receiver;
@property (retain) NSString *messageContent;
@property (retain) NSNumber *read;
@property (nonatomic) MessageStatus status;
@property (retain) NSDate *sentAt;

+ (Message *)createMessageWithContent:(NSString *)messageContent
                             receiver:(User *)receiver;

+ (Message *)createMessageWithContent:(NSString *)messageContent
                               sender:(User *)sender;

@end
