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
#import "VideoPost.h"

@implementation ApiManager

+ (void)saveVideoPost:(VideoPost *)post
    andExecuteSuccess:(void(^)())successBlock
              failure:(void(^)(NSError *error))failureBlock
{
    if (!post.localUrl) {
        failureBlock(nil);
        return;
    }
    PFObject *fbPost = [PFObject objectWithClassName:@"videoPost"];
    fbPost[@"posterName"] = post.posterName;
    NSData *data = [NSData dataWithContentsOfURL:post.localUrl];
    PFFile *file = [PFFile fileWithName:@"video.mp4" data:data];
    [file saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            fbPost[@"videoFile"] = file;
            [fbPost saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (succeeded) {
                    post.objectId = fbPost.objectId;
                    post.createdAt = fbPost.createdAt;
                    post.updatedAt = fbPost.updatedAt;
                    if (successBlock)
                        successBlock();
                } else {
                    // Log details of the failure
                    NSLog(@"Error: %@ %@", error, [error userInfo]);
                    if (failureBlock)
                        failureBlock(error);
                }
            }];
        } else {
            // Log details of the failure
            NSLog(@"Error: %@ %@", error, [error userInfo]);
            if (failureBlock)
                failureBlock(error);
        }
    }];
}

+ (void)getVideoPostsAndExecuteSuccess:(void(^)(NSArray *posts))successBlock
                               failure:(void(^)(NSError *error))failureBlock
{
    PFQuery *query = [PFQuery queryWithClassName:@"videoPost"];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            // The find succeeded.
            NSLog(@"Successfully retrieved %lu scores.", (unsigned long)objects.count);
            
            if (successBlock) {
                successBlock([VideoPost videoPostsFromFacebookObjects:objects]);
            }
        } else {
            // Log details of the failure
            NSLog(@"Error: %@ %@", error, [error userInfo]);
            if (failureBlock)
                failureBlock(error);
        }
    }];
}


@end
