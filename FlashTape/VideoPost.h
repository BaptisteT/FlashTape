//
//  VideoPost.h
//  FlashTape
//
//  Created by Baptiste Truchot on 4/25/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
#import <Parse/parse.h>
#import <Foundation/Foundation.h>

#import "BaseObject.h"

@interface VideoPost : BaseObject

@property (strong, nonatomic) NSURL *localUrl;
@property (strong, nonatomic) NSString *posterName;
@property (strong, nonatomic) UIImage *thumbnail;

+ (VideoPost *)createPostWithRessourceUrl:(NSURL *)url;
+ (VideoPost *)videoPostFromFacebookObject:(PFObject *)fbPost;
+ (NSArray *)videoPostsFromFacebookObjects:(NSArray *)fbObjects;

@end
