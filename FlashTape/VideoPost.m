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

#import "ConstantUtils.h"
#import "GeneralUtils.h"

@implementation VideoPost

// Local
@synthesize downloadProgress;
@synthesize videoData;
@synthesize localUrl;
@synthesize isDownloading;
@synthesize thumbmail;

// Variable saved on parse
@dynamic videoFile;
@dynamic user;
@dynamic viewerIdsArray;
@dynamic recordedAt;

static int downloadingCount = 0;

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
    post.recordedAt = [NSDate date];
    return post;
}

- (void)downloadVideoFile
{
    NSError *err;
    if ([[self videoLocalURL] checkResourceIsReachableAndReturnError:&err]) {
        self.localUrl = [self videoLocalURL];
    } else {
        if (!self.isDownloading) {
            if (downloadingCount < kMaxConcurrentVideoDownloadingCount) {
                downloadingCount ++;
                NSLog(@"%d",downloadingCount);
                self.isDownloading = YES;
                [self.videoFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                    self.isDownloading = NO;
                    downloadingCount --;
                    if (data) {
                        [self saveDataToLocalURL:data];
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
            } else {
                [NSTimer scheduledTimerWithTimeInterval:kDelayBeforeRetryDownload target:self selector:@selector(downloadVideoFile) userInfo:nil repeats:NO];
                NSLog(@"blocked");
            }
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

- (NSMutableArray *)viewerIdsArrayWithoutPoster {
    NSMutableArray *viewerIdsArrayWithoutPoster = [NSMutableArray arrayWithArray:self.viewerIdsArray];
    if ([viewerIdsArrayWithoutPoster indexOfObject:self.user.objectId] != NSNotFound) {
        [viewerIdsArrayWithoutPoster removeObjectAtIndex:[viewerIdsArrayWithoutPoster indexOfObject:self.user.objectId]];
    }
    return viewerIdsArrayWithoutPoster;
}

@end
