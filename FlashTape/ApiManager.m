//
//  ApiManager.m
//  FlashTape
//
//  Created by Baptiste Truchot on 4/26/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
// With Parse, an API manager is not necessary. However I build this layer to be able to switch to our own backend in the future

#import "ApiManager.h"

@implementation ApiManager

+ (void)saveVideoPost:(VideoPost *)post
    andExecuteSuccess:(void(^)(VideoPost *post))successBlock
              failure:(void(^)(NSError *error))failureBlock
{
    if (!post.localUrl || post.localUrl.length == 0)
        return;
    NSData *data = [NSData dataWithContentsOfURL:post.localUrl];
    PFFile *file = [PFFile fileWithName:@"resume.txt" data:data];
    [file saveInBackground];
    post.videoFile = file;
    
    [post saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            successBlock(post);
        } else {
            // There was a problem, check error.description
            // todo BT
            failureBlock(error);
        }
    }];
}


@end
