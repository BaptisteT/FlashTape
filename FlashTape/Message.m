//
//  Message.m
//  FlashTape
//
//  Created by Baptiste Truchot on 6/1/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//

#import "Message.h"

@implementation Message

@dynamic sender;
@dynamic receiver;
@dynamic messageContent;
@dynamic read;

@synthesize status;

+ (void)load {
    [self registerSubclass];
}

+ (NSString * __nonnull)parseClassName
{
    return NSStringFromClass([self class]);
}

+ (Message *)createMessageWithContent:(NSString *)messageContent
                             receiver:(User *)receiver
{
    Message *message = [Message object];
    message.sender = [User currentUser];
    message.receiver = receiver;
    message.messageContent = messageContent;
    message.read = [NSNumber numberWithBool:false];
    return message;
}


@end
