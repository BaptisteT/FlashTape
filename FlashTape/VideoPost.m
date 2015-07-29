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
#import "FlashLogger.h"

#define FLASHVIDEOPOSTLOG YES && GLOBALLOGENABLED

@implementation VideoPost

// Local
@synthesize downloadProgress;
@synthesize localUrl;
@synthesize isDownloading;
@synthesize thumbmail;
@synthesize videoProperties;

// Variable saved on parse
@dynamic videoFile;
@dynamic user;
@dynamic viewerIdsArray;
@dynamic recordedAt;
@dynamic tempId;

static int downloadingCount = 0;

+ (void)load {
    [self registerSubclass];
}

+ (NSString * __nonnull)parseClassName
{
    return NSStringFromClass([self class]);
}

+ (VideoPost *)createCurrentUserPost {
    VideoPost *post = [VideoPost object];
    post.user = [User currentUser];
    post.recordedAt = [NSDate date];
    post.tempId = [[NSUUID UUID] UUIDString];
    post.localUrl = [post videoLocalURL];
    return post;
}

+ (VideoPost *)createPostWithUser:(User *)user ressourceUrl:(NSURL *)url
{
    VideoPost *post = [VideoPost object];
    post.user = user;
    post.recordedAt = [NSDate date];
    post.localUrl = url;
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
                [self getDataInBackgroundAndExecuteSuccess:nil failure:nil];
            } else {
                [NSTimer scheduledTimerWithTimeInterval:kDelayBeforeRetryDownload target:self selector:@selector(downloadVideoFile) userInfo:nil repeats:NO];
                NSLog(@"blocked");
            }
        }
    }
}

- (void)getDataInBackgroundAndExecuteSuccess:(void(^)())successBlock
                                     failure:(void(^)(NSError *error))failureBlock
{
    downloadingCount ++;
    NSLog(@"%d",downloadingCount);
    self.isDownloading = YES;
    [self.videoFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        self.isDownloading = NO;
        downloadingCount --;
        if (data) {
            [self saveDataToLocalURL:data];
            if (successBlock) successBlock();
        } else {
            if ([self.videoFile isDataAvailable]) {
                [self saveDataToLocalURL:[self.videoFile getData]];
                if (successBlock) successBlock();
            } else {
                NSLog(@"Get Data in Background Error: %@ %@", error, [error userInfo]);
                if (failureBlock) failureBlock(error);
            }
        }
    } progressBlock:^(int percentDone) {
        self.downloadProgress = percentDone;
    }];
}

- (void)migrateDataFromTemporaryToPermanentURL {
    if (!self.objectId || self.objectId.length == 0 || !self.localUrl)
        return;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager moveItemAtURL:self.localUrl toURL:[self videoLocalURL] error:nil]) {
        self.localUrl = [self videoLocalURL];
    };
}

- (void)saveDataToLocalURL:(NSData *)data {
    NSError * savingError = nil;
    if (![data writeToURL:[self videoLocalURL] options:NSAtomicWrite error:&savingError] || savingError) {
        NSLog(@"Could not Get Available Data. Error:%@",savingError);
    } else {
        self.localUrl = [self videoLocalURL];
    }
}

- (NSURL *)videoLocalURL {
    NSURL *tmpDirURL = [NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES];
    NSString *postId = self.objectId && self.objectId.length > 0 ? self.objectId : (self.tempId ? self.tempId : @"");
    return [[tmpDirURL URLByAppendingPathComponent:postId] URLByAppendingPathExtension:@"mp4"];
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

+ (void)createTutoVideoAndExecuteSuccess:(void(^)(NSArray *videoArray))successBlock
                            failureBlock:(void(^)(NSError *error))failureBlock
{
    PFQuery *userQuery = [User query];
    [userQuery whereKey:@"objectId" equalTo:kAdminUserObjectId];
    [userQuery getFirstObjectInBackgroundWithBlock:^(PFObject *user, NSError *error) {
        if (!error) {
            VideoPost *post1 = [VideoPost createPostWithUser:(User *)user ressourceUrl:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"tuto_video_1" ofType:@"mp4"]]];
            VideoPost *post2 = [VideoPost createPostWithUser:(User *)user ressourceUrl:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"tuto_video_2" ofType:@"mp4"]]];
            VideoPost *post3 = [VideoPost createPostWithUser:(User *)user ressourceUrl:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"tuto_video_3" ofType:@"mp4"]]];
            VideoPost *post4 = [VideoPost createPostWithUser:(User *)user ressourceUrl:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"tuto_video_4" ofType:@"mp4"]]];
            if (successBlock) {
                successBlock(@[post1,post2, post3, post4]);
            }
        } else {
            if (failureBlock) failureBlock(error);
        }
    }];
}


@end
