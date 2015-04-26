//
//  VideoPost.m
//  FlashTape
//
//  Created by Baptiste Truchot on 4/25/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
#import "VideoPost.h"

@implementation VideoPost
@dynamic posterName;
@dynamic ressourceUrl;

+ (VideoPost *)videoPostWith
{
    VideoPost *post = (VideoPost *)[PFObject objectWithClassName:@"videoPost"];
    post.posterName = @"bob";
//    post.ressourceUrl = @"";
    return post;
}



@end
