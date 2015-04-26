//
//  VideoPost.m
//  FlashTape
//
//  Created by Baptiste Truchot on 4/25/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
#import "VideoPost.h"

@implementation VideoPost

+ (VideoPost *)createPostWithRessourceUrl:(NSURL *)url
{
    VideoPost *post = [VideoPost new];
    post.posterName = @"bob";
    post.localUrl = url;
    return post;
}



@end
