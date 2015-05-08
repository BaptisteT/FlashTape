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

@synthesize localUrl;
@synthesize thumbnail;
@dynamic videoFile;
@dynamic user;

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
    post.user = [User currentUser];
    return post;
}

- (void)downloadVideoFile
{
    [self.videoFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        if (data) {
            self.localUrl = [self videoLocalURL];
            [data writeToURL:self.localUrl options:NSAtomicWrite error:nil];
            self.thumbnail = [GeneralUtils generateThumbImage:self.localUrl];
        } else {
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        }
    }];
}

- (NSURL *)videoLocalURL {
    NSURL *tmpDirURL = [NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES];
    return [[tmpDirURL URLByAppendingPathComponent:self.objectId] URLByAppendingPathExtension:@"mp4"];
}

+ (void)downloadVideoFromPosts:(NSArray *)fbPosts
{
    for (VideoPost *post in fbPosts) {
        [post downloadVideoFile];
        [post.user fetchIfNeededInBackground];
    }
}


@end
