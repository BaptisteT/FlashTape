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

+ (AVPlayerItem *)createAVPlayerItemWithVideoPosts:(NSArray *)posts
                         andFillObservedTimesArray:(NSMutableArray *)observedTimesArray
{
    if (!posts || posts.count == 0)
        return nil;
    if (observedTimesArray)
        [observedTimesArray removeAllObjects];
    
    AVMutableComposition *composition = [AVMutableComposition composition];
    AVMutableCompositionTrack *videoCompositionTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                                preferredTrackID:kCMPersistentTrackID_Invalid];
    AVMutableCompositionTrack *audioCompositionTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                                                preferredTrackID:kCMPersistentTrackID_Invalid];
    NSMutableArray *instructions = [NSMutableArray new];
    CGSize size = CGSizeMake(720, 1280);
    CMTime time = kCMTimeZero;
    for (VideoPost *post in posts) {
        if (!post.videoLocalURL) {
            break;
        }
        AVAsset *asset = [AVAsset assetWithURL:post.videoLocalURL];
        AVAssetTrack *assetTrack = [asset tracksWithMediaType:AVMediaTypeVideo].firstObject;
        AVAssetTrack *audioAssetTrack = [asset tracksWithMediaType:AVMediaTypeAudio].firstObject;
        
        NSError *error;
        CMTime cutDuration = CMTimeMakeWithSeconds(CMTimeGetSeconds(assetTrack.timeRange.duration) - kVideoEndCutDuration, 600);
        CMTimeRange assetTimeRange = CMTimeRangeMake(kCMTimeZero, cutDuration);
        [videoCompositionTrack insertTimeRange:assetTimeRange
                                       ofTrack:assetTrack
                                        atTime:time
                                         error:&error];
        if (error) {
            NSLog(@"Error - %@", error.debugDescription);
        }
        
        [audioCompositionTrack insertTimeRange:assetTimeRange
                                       ofTrack:audioAssetTrack
                                        atTime:time
                                         error:&error];
        if (error) {
            NSLog(@"Error - %@", error.debugDescription);
        }
        
        AVMutableVideoCompositionInstruction *videoCompositionInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        videoCompositionInstruction.timeRange = CMTimeRangeMake(time, cutDuration);
        videoCompositionInstruction.layerInstructions = @[[AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoCompositionTrack]];
        
        AVMutableVideoCompositionLayerInstruction *firstVideoLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoCompositionTrack];
        
        if (!CGSizeEqualToSize(assetTrack.naturalSize,size)) {
            CGFloat scaleFactor = MAX(size.width / assetTrack.naturalSize.width, size.height / assetTrack.naturalSize.height);
            CGAffineTransform transform = CGAffineTransformMakeScale(scaleFactor,scaleFactor);
            [firstVideoLayerInstruction setTransform:transform atTime:kCMTimeZero];
            videoCompositionInstruction.layerInstructions = @[firstVideoLayerInstruction];
        }
        
        [instructions addObject:videoCompositionInstruction];
        
        time = CMTimeAdd(time, cutDuration);
        if (observedTimesArray)
            [observedTimesArray addObject:[NSValue valueWithCMTime:time]];
    }
    
    AVMutableVideoComposition *mutableVideoComposition = [AVMutableVideoComposition videoComposition];
    mutableVideoComposition.instructions = instructions;
    
    // Set the frame duration to an appropriate value (i.e. 30 frames per second for video).
    mutableVideoComposition.frameDuration = CMTimeMake(1, 30);
    mutableVideoComposition.renderSize = size;
    
    AVPlayerItem *pi = [AVPlayerItem playerItemWithAsset:composition];
    pi.videoComposition = mutableVideoComposition;

    return pi;
}


+ (void)saveVideoCompositionToCameraRoll:(AVAsset *)composition
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
            NSLog(@"%@",exportSession.error.description);
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
                                                NSLog(@"%@",error.description);
                                                if (failureBlock) {
                                                    failureBlock();
                                                }
                                            }
                                        }];
        };
    }];
}

@end
