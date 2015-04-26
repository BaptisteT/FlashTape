//
//  ApiManager.m
//  FlashTape
//
//  Created by Baptiste Truchot on 4/26/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
// With Parse, an API manager is not necessary. However I build this layer to be able to switch to our own backend in the future
#import <Parse/parse.h>

#import "ApiManager.h"


@implementation ApiManager

+ (void)saveVideoPost:(VideoPost *)post
    andExecuteSuccess:(void(^)())successBlock
              failure:(void(^)(NSError *error))failureBlock
{
    if (!post.localUrl) {
        failureBlock(nil);
        return;
    }
    PFObject *fbPost = [PFObject objectWithClassName:NSStringFromClass([post class])];
    fbPost[@"posterName"] = post.posterName;
    NSData *data = [NSData dataWithContentsOfURL:post.localUrl];
    PFFile *file = [PFFile fileWithName:@"video.mpeg4" data:data];
    [file saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            fbPost[@"videoFile"] = file;
            [fbPost saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (succeeded) {
                    post.objectId = fbPost.objectId;
                    post.createdAt = fbPost.createdAt;
                    post.updatedAt = fbPost.updatedAt;
                    successBlock();
                } else {
                    // There was a problem, check error.description
                    // todo BT
                    failureBlock(error);
                }
            }];
        } else {
            // There was a problem, check error.description
            // todo BT
            failureBlock(error);
        }
    }];
}

+ (void)getVideoPostsAndExecuteSuccess:(void(^)(NSArray *posts))successBlock
                               failure:(void(^)(NSError *error))failureBlock
{
    
}


@end
