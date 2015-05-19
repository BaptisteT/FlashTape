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

@synthesize downloadProgress;
@synthesize videoData;
@synthesize localUrl;
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
    post.user = [User currentUser];
    return post;
}

- (void)downloadVideoFile
{
    NSError *err;
    if ([[self videoLocalURL] checkResourceIsReachableAndReturnError:&err]) {
        self.localUrl = [self videoLocalURL];
    } else {
        [self.videoFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
            NSError * savingError = nil;
            if (data) {
                if (![data writeToURL:self.localUrl options:NSAtomicWrite error:&savingError] || savingError) {
                    NSLog(@"Could not remove old files. Error:%@",savingError);
                }
                self.localUrl = [self videoLocalURL];
            } else {
                if ([self.videoFile isDataAvailable]) {
                    NSData *data = [self.videoFile getData];
                    NSError * savingError = nil;
                    if (![data writeToURL:self.localUrl options:NSAtomicWrite error:&savingError] || savingError) {
                        NSLog(@"Could not Get Available Data. Error:%@",savingError);
                    }
                    self.localUrl = [self videoLocalURL];
                } else {
                    NSLog(@"Get Data in Background Error: %@ %@", error, [error userInfo]);
                }
            }
        } progressBlock:^(int percentDone) {
            self.downloadProgress = percentDone;
        }];
    }
}

- (NSURL *)videoLocalURL {
    NSURL *tmpDirURL = [NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES];
    return [[tmpDirURL URLByAppendingPathComponent:self.objectId] URLByAppendingPathExtension:@"mp4"];
}

+ (void)downloadVideoFromPosts:(NSArray *)fbPosts
{
    for (VideoPost *post in fbPosts) {
        [post downloadVideoFile];
    }
}



@end
