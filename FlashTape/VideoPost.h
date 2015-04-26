//
//  VideoPost.h
//  FlashTape
//
//  Created by Baptiste Truchot on 4/25/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/parse.h>

@interface VideoPost : PFObject

@property (strong, nonatomic) PFFile *videoFile;
@property (strong, nonatomic) NSURL *localUrl;

@property (strong, nonatomic) NSString *posterName;


@end
