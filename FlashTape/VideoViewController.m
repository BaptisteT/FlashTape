//
//  VideoViewController.m
//  FlashTape
//
//  Created by Baptiste Truchot on 4/25/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <MobileCoreServices/MobileCoreServices.h>

#import "ApiManager.h"
#import "VideoPost.h"

#import "VideoViewController.h"

#import "ConstantUtils.h"

@interface VideoViewController ()

// Playing
@property (strong, nonatomic) AVQueuePlayer *avQueueVideoPlayer;
@property (strong, nonatomic) NSMutableArray *videoPostArray;
@property (strong, nonatomic) AVPlayerLayer *playerLayer;

// Recording
@property (strong, nonatomic) SCRecorder *recorder;
@property (strong, nonatomic) UILongPressGestureRecognizer *longPressGestureRecogniser;

@end

@implementation VideoViewController {
    NSInteger _videoIndex;
}

// --------------------------------------------
#pragma mark - Life Cycle
// --------------------------------------------

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Init Long press gesture
    self.longPressGestureRecogniser = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGesture:)];
    self.longPressGestureRecogniser.minimumPressDuration = 0;
    [self.view addGestureRecognizer:self.longPressGestureRecogniser];
    
    // Create the recorder
    self.recorder = [SCRecorder recorder];
    _recorder.captureSessionPreset = [SCRecorderTools bestCaptureSessionPresetCompatibleWithAllDevices];
    _recorder.maxRecordDuration = CMTimeMake(10, 1);
    _recorder.delegate = self;
    _recorder.autoSetVideoOrientation = YES;
    _recorder.device = AVCaptureDevicePositionFront;
    _recorder.maxRecordDuration = CMTimeMake(kRecordSessionMaxDuration, 1);
    self.recorder.previewLayer.frame = self.view.frame;
    [self.view.layer addSublayer:self.recorder.previewLayer];
    // Start running the flow of buffers
    if (![self.recorder startRunning]) {
        NSLog(@"Something wrong there: %@", self.recorder.error);
    }
    
    // Video player
    self.avQueueVideoPlayer = [AVQueuePlayer new];
    self.avQueueVideoPlayer.actionAtItemEnd = AVPlayerActionAtItemEndAdvance;
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.avQueueVideoPlayer];
    self.playerLayer.frame = self.view.frame;
    [self.view.layer addSublayer:self.playerLayer];
    self.playerLayer.backgroundColor = [UIColor blackColor].CGColor;
    
    // Init player items
    self.videoPostArray = [NSMutableArray new];
    _videoIndex = 0;
    
    // Callback
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(willBecomeActiveCallback)
                                                 name: UIApplicationWillEnterForegroundNotification
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(didEnterBackgroundCallback)
                                                 name: UIApplicationDidEnterBackgroundNotification
                                               object: nil];

    // Retrieve posts
    [ApiManager getVideoPostsAndExecuteSuccess:^(NSArray *posts) {
        self.videoPostArray = [NSMutableArray arrayWithArray:posts];
        [self playVideos];
    } failure:nil];
}

- (void)didEnterBackgroundCallback {
    // todo BT
}

- (void)willBecomeActiveCallback {
    [ApiManager getVideoPostsAndExecuteSuccess:^(NSArray *posts) {
        self.videoPostArray = [NSMutableArray arrayWithArray:posts];
    } failure:nil];
}

// --------------------------------------------
#pragma mark - Actions
// --------------------------------------------
- (void)handleLongPressGesture:(UILongPressGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateBegan) {
        [self startRecording];
        [self.avQueueVideoPlayer pause];
        self.playerLayer.hidden = YES;
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        // todo BT
    } else {
        if ([self.recorder isRecording])
            [self stopRecording];
    }
}

// --------------------------------------------
#pragma mark - Playing
// --------------------------------------------
- (void)playVideos {
    if (self.videoPostArray.count == 0) {
        return;
    }
    NSInteger queueCount = self.avQueueVideoPlayer.items.count;
    for (NSInteger kk = 0; kk < kMaxVidsInThePlayerQueue - queueCount; kk++) {
        VideoPost *post =  self.videoPostArray[_videoIndex];
        if (post.localUrl) {
            [self insertVideoInThePlayerQueue:post.localUrl];
        }
        if (_videoIndex < self.videoPostArray.count - 1) {
            _videoIndex ++;
        } else {
            _videoIndex = 0;
        }
    }
    if (self.avQueueVideoPlayer.items.count != 0) {
        [self.playerLayer setHidden:NO];
        [self.avQueueVideoPlayer play];
    } else {
        [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(playVideos) userInfo:nil repeats:NO];
    }
}

// After an item is played, add a new end to the end of the queue
- (void)playerItemDidReachEnd:(NSNotification *)notification
{
    // Security check
    if (self.videoPostArray.count == 0) {
        return;
    }
    if (_videoIndex >= self.videoPostArray.count) {
        _videoIndex = 0;
    }
    
    // Get post and increment index
    VideoPost *post =  self.videoPostArray[_videoIndex];
    if (_videoIndex < self.videoPostArray.count - 1) {
        _videoIndex ++;
    } else {
        _videoIndex = 0;
    }
    if (post.localUrl) {
        [self insertVideoInThePlayerQueue:post.localUrl];
    } else {
        [self playerItemDidReachEnd:nil];
    }
}

// Insert video at the end of the queue
- (void)insertVideoInThePlayerQueue:(NSURL *)videoUrl
{
    AVAsset *playerAsset = [AVAsset assetWithURL:videoUrl];
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:playerAsset];
    [self.avQueueVideoPlayer insertItem:playerItem afterItem:self.avQueueVideoPlayer.items.lastObject];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(playerItemDidReachEnd:)
                                                 name: AVPlayerItemDidPlayToEndTimeNotification
                                               object: playerItem];
}

// --------------------------------------------
#pragma mark - Recording
// --------------------------------------------
- (void)startRecording {
    [self prepareSession];
    // Begin appending video/audio buffers to the session
    [self.recorder record];
}

- (void)stopRecording {
    [self playVideos];
    [self.recorder pause:^{
        [self exportAndSaveSession:self.recorder.session];
    }];
}

- (void)exportAndSaveSession:(SCRecordSession *)recordSession {
    AVAssetExportSession *exportSession = [AVAssetExportSession exportSessionWithAsset:recordSession.assetRepresentingSegments presetName:AVAssetExportPresetHighestQuality];
    exportSession.outputURL = recordSession.outputUrl;
    exportSession.outputFileType = AVFileTypeMPEG4;
    exportSession.shouldOptimizeForNetworkUse = YES;
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        if (exportSession.error == nil) {
            VideoPost *post = [VideoPost createPostWithRessourceUrl:recordSession.outputUrl];
            [self.videoPostArray addObject:post];
            if (self.avQueueVideoPlayer.items.count == 0) {
                [self playVideos];
            }
            [ApiManager saveVideoPost:post
                    andExecuteSuccess:^() {
                        // do nothing
                    } failure:^(NSError *error) {
                        // todo BT
                        // remove ?
                        NSLog(@"fail to save video");
                    }];
        } else {
            // todo BT
            NSLog(@"fail to export");
        }
    }];
}

- (void)prepareSession {
    SCRecordSession *session = [SCRecordSession recordSession];
    session.fileType = AVFileTypeQuickTimeMovie;
    _recorder.session = session;
}

// --------------------------------------------
#pragma mark - SCRecorderDelegate
// --------------------------------------------

- (void)recorder:(SCRecorder *)recorder didCompleteSession:(SCRecordSession *)recordSession {
    [self stopRecording];
}

- (void)recorder:(SCRecorder *)recorder didInitializeAudioInSession:(SCRecordSession *)recordSession error:(NSError *)error {
    if (error == nil) {
        NSLog(@"Initialized audio in record session");
    } else {
        NSLog(@"Failed to initialize audio in record session: %@", error.localizedDescription);
    }
}

- (void)recorder:(SCRecorder *)recorder didInitializeVideoInSession:(SCRecordSession *)recordSession error:(NSError *)error {
    if (error == nil) {
        NSLog(@"Initialized video in record session");
    } else {
        NSLog(@"Failed to initialize video in record session: %@", error.localizedDescription);
    }
}

- (void)recorder:(SCRecorder *)recorder didBeginSegmentInSession:(SCRecordSession *)recordSession error:(NSError *)error {
    NSLog(@"Began record segment: %@", error);
}

- (void)recorder:(SCRecorder *)recorder didCompleteSegment:(SCRecordSessionSegment *)segment inSession:(SCRecordSession *)recordSession error:(NSError *)error {
    NSLog(@"Completed record segment at %@: %@ (frameRate: %f)", segment.url, error, segment.frameRate);
}

- (void)recorder:(SCRecorder *)recorder didSkipVideoSampleBufferInSession:(SCRecordSession *)recordSession {
    NSLog(@"Skipped video buffer");
}

- (void)recorder:(SCRecorder *)recorder didReconfigureAudioInput:(NSError *)audioInputError {
    NSLog(@"Reconfigured audio input: %@", audioInputError);
}

- (void)recorder:(SCRecorder *)recorder didReconfigureVideoInput:(NSError *)videoInputError {
    NSLog(@"Reconfigured video input: %@", videoInputError);
}

@end
