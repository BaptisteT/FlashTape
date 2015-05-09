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
@property (retain) NSURL *localUrl;

+ (VideoPost *)createPostWithRessourceUrl:(NSURL *)url;

+ (NSString *)parseClassName;

+ (void)downloadVideoFromPosts:(NSArray *)fbPosts;

@end
