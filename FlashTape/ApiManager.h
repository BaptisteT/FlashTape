//
//  ApiManager.h
//  FlashTape
//
//  Created by Baptiste Truchot on 4/26/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
// With Parse, an API manager is not necessary. However I build this layer to be able to switch to our own backend in the future

#import <Foundation/Foundation.h>

@class VideoPost;

@interface ApiManager : NSObject

+ (void)saveVideoPost:(VideoPost *)post
    andExecuteSuccess:(void(^)())successBlock
              failure:(void(^)(NSError *error))failureBlock;

+ (void)getVideoPostsAndExecuteSuccess:(void(^)(NSArray *posts))successBlock
                               failure:(void(^)(NSError *error))failureBlock;
@end
