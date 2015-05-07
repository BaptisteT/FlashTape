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

#import "GeneralUtils.h"

@implementation VideoPost

@dynamic localUrl;
@dynamic thumbnail;

+ (void)load {
    [self registerSubclass];
}

+ (NSString * __nonnull)parseClassName
{
    return NSStringFromClass([self class]);
}

+ (VideoPost *)createPostWithRessourceUrl:(NSURL *)url
{
    VideoPost *post = [VideoPost object];
    post.localUrl = url;
    post.thumbnail = [GeneralUtils generateThumbImage:post.localUrl];
    return post;
}

- (void)downloadVideoFile
{
    [self.videoFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        if (data) {
            self.localUrl = [self saveFileURL];
            [data writeToURL:self.localUrl options:NSAtomicWrite error:nil];
            self.thumbnail = [GeneralUtils generateThumbImage:self.localUrl];
        } else {
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        }
    }];
}

//+ (NSArray *)videoPostsFromFacebookObjects:(NSArray *)fbObjects
//{
//    NSMutableArray *posts = [[NSMutableArray alloc] init];
//    for (PFObject *fbPost in fbObjects) {
//        [posts addObject:[VideoPost videoPostFromFacebookObject:fbPost]];
//    }
//    return posts;
//}

- (NSURL *)saveFileURL {
    NSURL *tmpDirURL = [NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES];
    return [[tmpDirURL URLByAppendingPathComponent:self.objectId] URLByAppendingPathExtension:@"mp4"];
}

@end
