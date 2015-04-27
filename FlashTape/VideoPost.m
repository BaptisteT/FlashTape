//
//  VideoPost.m
//  FlashTape
//
//  Created by Baptiste Truchot on 4/25/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
#import "VideoPost.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
@implementation VideoPost

+ (VideoPost *)createPostWithRessourceUrl:(NSURL *)url
{
    VideoPost *post = [VideoPost new];
    post.posterName = @"bob";
    post.localUrl = url;
    return post;
}

+ (VideoPost *)videoPostFromFacebookObject:(PFObject *)fbPost
{
    VideoPost *post = [VideoPost new];
    post.objectId = fbPost.objectId;
    post.createdAt = fbPost.createdAt;
    post.updatedAt = fbPost.updatedAt;
    PFFile *videoPFFile = fbPost[@"videoFile"];
    [videoPFFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        if (data) {
            post.localUrl = [post saveFileURL];
            [data writeToURL:post.localUrl options:NSAtomicWrite error:nil];
        } else {
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        }
    }];
    return post;
}

+ (NSArray *)videoPostsFromFacebookObjects:(NSArray *)fbObjects
{
    NSMutableArray *posts = [[NSMutableArray alloc] init];
    for (PFObject *fbPost in fbObjects) {
        [posts addObject:[VideoPost videoPostFromFacebookObject:fbPost]];
    }
    return posts;
}

- (NSURL *)saveFileURL {
    NSURL *tmpDirURL = [NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES];
    return [[tmpDirURL URLByAppendingPathComponent:self.objectId] URLByAppendingPathExtension:@"mp4"];
}

@end
