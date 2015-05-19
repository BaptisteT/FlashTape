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
        if ([self.videoFile isDataAvailable]) {
            [self saveDataToLocalURL:[self.videoFile getData]];
        } else {
            [self.videoFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                if (data) {
                    [self saveDataToLocalURL:[self.videoFile getData]];
                } else {
                    if ([self.videoFile isDataAvailable]) {
                        [self saveDataToLocalURL:[self.videoFile getData]];
                    } else {
                        NSLog(@"Get Data in Background Error: %@ %@", error, [error userInfo]);
                    }
                }
            } progressBlock:^(int percentDone) {
                self.downloadProgress = percentDone;
            }];
        }
    }
}

- (void)saveDataToLocalURL:(NSData *)data {
    NSError * savingError = nil;
    if (![data writeToURL:[self videoLocalURL] options:NSAtomicWrite error:&savingError] || savingError) {
        NSLog(@"Could not Get Available Data. Error:%@",savingError);
    }
    self.localUrl = [self videoLocalURL];
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
