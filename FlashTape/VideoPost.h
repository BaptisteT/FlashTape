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
@property (retain) NSDate *recordedAt;
@property (retain) NSString *tempId;

@property (retain) NSURL *localUrl;
@property (nonatomic) NSInteger downloadProgress;
@property (nonatomic) BOOL isDownloading;
@property (retain) UIImage *thumbmail;
@property (retain) NSDictionary *videoProperties;

+ (VideoPost *)createCurrentUserPost ;

+ (NSString *)parseClassName;

+ (void)downloadVideoFromPosts:(NSArray *)fbPosts;

- (void)migrateDataFromTemporaryToPermanentURL ;

- (NSURL *)videoLocalURL;

- (NSMutableArray *)viewerIdsArrayWithoutPoster;

+ (void)createTutoVideoAndExecuteSuccess:(void(^)(NSArray *videoArray))successBlock
                            failureBlock:(void(^)(NSError *error))failureBlock;
@end
