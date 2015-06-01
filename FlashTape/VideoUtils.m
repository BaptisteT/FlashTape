//
//  VideoUtils.m
//  FlashTape
//
//  Created by Baptiste Truchot on 5/27/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
#import <AssetsLibrary/AssetsLibrary.h>
#import "SCAssetExportSession.h"

#import "ConstantUtils.h"
#import "VideoUtils.h"
#import "VideoPost.h"

@implementation VideoUtils

+ (NSMutableArray *)fillComposition:(AVMutableComposition *)composition
                     withVideoPosts:(NSArray *)posts
{
    NSMutableArray *observedTimesArray = [NSMutableArray new];
    if (!composition)
        return observedTimesArray;
    for (NSInteger kk = 0; kk < posts.count; kk++) {
        VideoPost *post = posts[kk];
        if (post.localUrl) {
            NSValue *observedTime = [VideoUtils addVideoAtURL:post.localUrl toComposition:composition];
            if (observedTime) {
                [observedTimesArray addObject:observedTime];
            }
        } else {
            return observedTimesArray;
        }
    }
    return observedTimesArray;
}

+ (NSValue *)addVideoAtURL:(NSURL *)videoUrl
             toComposition:(AVMutableComposition *)composition {
    if (videoUrl) {
        AVURLAsset* sourceAsset = [AVURLAsset assetWithURL:videoUrl];
        CMTimeRange assetTimeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(CMTimeGetSeconds(sourceAsset.duration) - kVideoEndCutDuration, 600));
        NSError *editError;
        [composition insertTimeRange:assetTimeRange
                             ofAsset:sourceAsset
                              atTime:[VideoUtils getCompositionEndCMTime:composition]
                               error:&editError];
        if (editError) {
            NSLog(@"%@",editError.description);
        }
        return [NSValue valueWithCMTime:[VideoUtils getCompositionEndCMTime:composition]];
    }
    return nil;
}

+ (CMTime)getCompositionEndCMTime:(AVComposition *)composition {
    return CMTimeMakeWithSeconds(CMTimeGetSeconds(composition.duration) -0.01,composition.duration.timescale);
}

+ (void)saveVideoCompositionToCameraRoll:(AVComposition *)composition
                                 success:(void(^)())successBlock
                                 failure:(void(^)())failureBlock
{
    SCAssetExportSession *exportSession = [[SCAssetExportSession alloc] initWithAsset:composition];
    exportSession.videoConfiguration.preset = SCPresetHighestQuality;
    exportSession.audioConfiguration.preset = SCPresetHighestQuality;
    exportSession.videoConfiguration.maxFrameRate = 35;
    NSString *exportVideoPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/FinishedVideo.m4v"];
    NSURL *exportURL = [NSURL fileURLWithPath:exportVideoPath];
    [[NSFileManager defaultManager] removeItemAtPath:exportVideoPath error:nil];
    exportSession.outputUrl = exportURL;
    exportSession.outputFileType = AVFileTypeMPEG4;
    
    // Adding our "Flash" watermark
    UILabel *label = [UILabel new];
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont boldSystemFontOfSize:40];
    label.text = @"FlashTape";
    [label sizeToFit];
    
    UIGraphicsBeginImageContext(label.frame.size);
    
    [label.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    exportSession.videoConfiguration.watermarkImage = image;
    exportSession.videoConfiguration.watermarkFrame = CGRectMake(10, 10, label.frame.size.width, label.frame.size.height);
    exportSession.videoConfiguration.watermarkAnchorLocation = SCWatermarkAnchorLocationBottomRight;

    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        if (exportSession.error) {
            if (failureBlock) {
                failureBlock();
            }
        } else {
            ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
            [library writeVideoAtPathToSavedPhotosAlbum:exportURL
                                        completionBlock:^(NSURL *assetURL, NSError *error) {
                                            if (error == nil) {
                                                if (successBlock) {
                                                    successBlock();
                                                }
                                            } else {
                                                if (failureBlock) {
                                                    failureBlock();
                                                }
                                            }
                                        }];
        };
    }];
}

@end
