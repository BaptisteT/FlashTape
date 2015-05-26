//
//  VideoPost.h
//  FlashTape
//
//  Created by Baptiste Truchot on 4/25/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <Parse/parse.h>

#import "User.h"

@interface VideoPost : PFObject<PFSubclassing>

@property (retain) User *user;
@property (retain) PFFile *videoFile;
@property (retain) NSArray *viewerIdsArray;
@property (retain) NSURL *localUrl;
@property (retain) NSData *videoData; // use for failure (url is reused for other videos..)
@property (nonatomic) NSInteger downloadProgress;
@property (nonatomic) BOOL isDownloading;

+ (VideoPost *)createPostWithRessourceUrl:(NSURL *)url;

+ (NSString *)parseClassName;

+ (void)downloadVideoFromPosts:(NSArray *)fbPosts;

- (NSURL *)videoLocalURL;

@end
