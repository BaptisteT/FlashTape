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

@property (retain) NSURL *localUrl;
@property (retain) User *user;
@property (retain) UIImage *thumbnail;
@property (retain) PFFile *videoFile;

+ (VideoPost *)createPostWithRessourceUrl:(NSURL *)url;

+ (NSString *)parseClassName;

@end
