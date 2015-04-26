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
    VideoPost *post = [VideoPost new];
    post.ressourceUrl = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"heart_slide" ofType:@"mp4"]];
    [self.videoPostArray addObject:post];
    [self insertVideoInThePlayerQueue:post.ressourceUrl];
    VideoPost *post1 = [VideoPost new];
    post1.ressourceUrl = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"matching_tap" ofType:@"mp4"]];
    [self.videoPostArray addObject:post1];
    [self insertVideoInThePlayerQueue:post1.ressourceUrl];
    VideoPost *post2 = [VideoPost new];
    post2.ressourceUrl = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"blackout-end" ofType:@"mp4"]];
    [self.videoPostArray addObject:post2];
    [self insertVideoInThePlayerQueue:post2.ressourceUrl];
    
    // Callback
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(willBecomeActiveCallback)
                                                 name: UIApplicationWillEnterForegroundNotification
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(didEnterBackgroundCallback)
                                                 name: UIApplicationDidEnterBackgroundNotification
                                               object: nil];
}

- (void)viewDidAppear:(BOOL)animated {
    self.playerLayer.hidden = NO;
    [self.avQueueVideoPlayer play];
}

- (void)didEnterBackgroundCallback {
    // todo BT
}

- (void)willBecomeActiveCallback {
    // todo BT
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
// After an item is played, delete it and add a new end to the end of the queue
- (void)playerItemDidReachEnd:(NSNotification *)notification
{
//    if (_videoIndex >= self.videoPostArray.count) {
//        _videoIndex = 0;
//    }

    NSLog(@"before %lu %lu %lu",self.videoPostArray.count, self.avQueueVideoPlayer.items.count,_videoIndex);
    
    for (NSInteger kk=0; kk < MIN(self.videoPostArray.count,kNumberOfVidsInThePlayerQueue - self.avQueueVideoPlayer.items.count + 1); kk++) {
        VideoPost *post =  self.videoPostArray[_videoIndex];
        [self insertVideoInThePlayerQueue:post.ressourceUrl];
        if (_videoIndex < self.videoPostArray.count - 1) {
            _videoIndex ++;
        } else {
            _videoIndex = 0;
        }
    }
//    [self.avQueueVideoPlayer removeItem:self.avQueueVideoPlayer.items.firstObject];
    NSLog(@"after %lu %lu %lu",self.videoPostArray.count, self.avQueueVideoPlayer.items.count,_videoIndex);
//    if (self.videoPostArray.count == 1) {
//        [self.avQueueVideoPlayer advanceToNextItem];
//        [self.avQueueVideoPlayer play];
//    }
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
    self.playerLayer.hidden = NO;
    [self.avQueueVideoPlayer play];
    [self.recorder pause:^{
        [self saveAndAddSession:self.recorder.session];
    }];
}

- (void)saveAndAddSession:(SCRecordSession *)recordSession {
//    [[SCRecordSessionManager sharedInstance] saveRecordSession:recordSession];
    // Merge all the segments into one file using an AVAssetExportSession
    [recordSession mergeSegmentsUsingPreset:AVAssetExportPresetHighestQuality completionHandler:^(NSURL *url, NSError *error) {
        if (error == nil) {
            VideoPost *post = [VideoPost new];
            post.ressourceUrl = url;
            
            [ApiManager saveBaseObject:post
                     andExecuteSuccess:^(BaseObject *baseObject) {
                         // todo BT;
                         [self.videoPostArray addObject:post];
                         [self insertVideoInThePlayerQueue:url];
                     } failure:^(NSError *error) {
                        // todo BT
                     }];
        } else {
            NSLog(@"Bad things happened: %@", error);
        }
    }];
}

- (void)prepareSession {
    if (_recorder.session == nil) {
        SCRecordSession *session = [SCRecordSession recordSession];
        session.fileType = AVFileTypeQuickTimeMovie;
        _recorder.session = session;
    } else {
        [_recorder.session removeAllSegments:YES];
    }
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
