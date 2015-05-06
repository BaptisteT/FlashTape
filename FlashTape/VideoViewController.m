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

#import "AVPlayerItem+VideoDate.h"
#import "ConstantUtils.h"
#import "GeneralUtils.h"

@interface VideoViewController ()

// Playing
@property (strong, nonatomic) AVQueuePlayer *avQueueVideoPlayer;
@property (strong, nonatomic) NSMutableArray *videoPostArray;
@property (strong, nonatomic) AVPlayerLayer *playerLayer;
@property (weak, nonatomic) IBOutlet UILabel *playingCountLabel;
@property (weak, nonatomic) IBOutlet UIButton *replayButton;

// Recording
@property (weak, nonatomic) IBOutlet UIView *recordingProgressContainer;
@property (strong, nonatomic) SCRecorder *recorder;
@property (strong, nonatomic) UITapGestureRecognizer *tapGestureRecogniser;
@property (strong, nonatomic) UILongPressGestureRecognizer *longPressGestureRecogniser;
@property (weak, nonatomic) IBOutlet UIView *previewView;
@property (strong, nonatomic) UIView *recordingProgressBar;

// Reactions
@property (weak, nonatomic) IBOutlet UITableView *thumbTableView;


@end

@implementation VideoViewController {
    NSInteger _videoIndex;
    BOOL _isExporting;
}

// --------------------------------------------
#pragma mark - Life Cycle
// --------------------------------------------

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _isExporting = NO;
    
    // Init gesture
    self.longPressGestureRecogniser = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGesture:)];
//    self.longPressGestureRecogniser.minimumPressDuration = 0;
    [self.view addGestureRecognizer:self.longPressGestureRecogniser];
    self.tapGestureRecogniser = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    [self.view addGestureRecognizer:self.tapGestureRecogniser];
    
    // Create the recorder
    self.recorder = [SCRecorder recorder];
    _recorder.captureSessionPreset = [SCRecorderTools bestCaptureSessionPresetCompatibleWithAllDevices];
    _recorder.maxRecordDuration = CMTimeMake(10, 1);
    _recorder.delegate = self;
    _recorder.autoSetVideoOrientation = YES;
    _recorder.device = AVCaptureDevicePositionFront;
    _recorder.maxRecordDuration = CMTimeMake(kRecordSessionMaxDuration, 1);
    if (![self.recorder startRunning]) { // Start running the flow of buffers
        NSLog(@"Something wrong there: %@", self.recorder.error);
    }
    
    // Recording progress bar
    self.recordingProgressBar = [[UIView alloc] init];
    self.recordingProgressBar.backgroundColor = [UIColor colorWithRed:0 green:1 blue:0 alpha:0.2];
    [self.recordingProgressContainer addSubview:self.recordingProgressBar];
    self.recordingProgressContainer.hidden = YES;
    
    // Video player
    self.avQueueVideoPlayer = [AVQueuePlayer new];
    self.avQueueVideoPlayer.actionAtItemEnd = AVPlayerActionAtItemEndAdvance;
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.avQueueVideoPlayer];
    self.playerLayer.frame = self.view.frame;
    [self.view.layer addSublayer:self.playerLayer];
    self.playerLayer.backgroundColor = [UIColor whiteColor].CGColor;
    self.playerLayer.hidden = YES;
    
    // Playing count label & replay
    [self.view bringSubviewToFront:self.playingCountLabel];
    [self.view bringSubviewToFront:self.replayButton];
    self.playingCountLabel.text = @"";
    self.replayButton.hidden = YES;
    
    // Thumb table view
    [self.view bringSubviewToFront:self.thumbTableView];
    self.thumbTableView.hidden = YES;
    self.thumbTableView.delegate = self;
    self.thumbTableView.dataSource = self;
    
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
        
        // Update index
        NSDate *lastSeenVideoDate = [GeneralUtils getLastVideoSeenDate];
        NSInteger index = 0;
//        for (VideoPost *post in self.videoPostArray) {
//            if ([post.createdAt compare:lastSeenVideoDate] == NSOrderedAscending) {
//                index ++;
//            } else {
//                break;
//            }
//        }
        _videoIndex = index;
    } failure:nil];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    // Player preview
    self.recorder.previewView = self.previewView;
}

- (void)didEnterBackgroundCallback {
    [self.avQueueVideoPlayer pause];
}

- (void)willBecomeActiveCallback {
    [self playVideos];
    // todo BT
    // handle the case some videos are too old
    [ApiManager getVideoPostsAndExecuteSuccess:^(NSArray *posts) {
        // todo BT
        // change index
        self.videoPostArray = [NSMutableArray arrayWithArray:posts];
    } failure:nil];
}

// --------------------------------------------
#pragma mark - Actions
// --------------------------------------------
- (void)handleLongPressGesture:(UILongPressGestureRecognizer *)gesture
{
    if (_isExporting)
        return;
    
    if (gesture.state == UIGestureRecognizerStateBegan) {
        if (!self.playerLayer.hidden) {
            // Set recorder device
            CGPoint location = [gesture locationInView:self.view];
            self.recorder.device = location.y > self.view.frame.size.height / 2 ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack;
        }
        [self startRecording];
        [self setRecordingMode];
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        // todo BT
    } else {
        if ([self.recorder isRecording])
            [self stopRecording];
    }
}

- (void)handleTapGesture:(UITapGestureRecognizer *)gesture
{
    BOOL playingMode = !self.playerLayer.hidden;
    if (playingMode) {
        [self setRecordingMode];
        // Set recorder device
        CGPoint location = [gesture locationInView:self.view];
        self.recorder.device = location.y > self.view.frame.size.height / 2 ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack;
    } else {
        if (self.avQueueVideoPlayer.items.count == 0 && _videoIndex > self.videoPostArray.count - 1) {
            [self setInteractioMode];
        } else {
            [self playVideos];
        }
    }
}

- (IBAction)replayButtonClicked:(id)sender {
    _videoIndex = 0;
    [self playVideos];
}

// --------------------------------------------
#pragma mark - Playing
// --------------------------------------------
- (void)playVideos {
    [self setPlayingMode];
    
    if (self.videoPostArray.count == 0) {
        return;
    }
    NSInteger queueCount = self.avQueueVideoPlayer.items.count;
    for (NSInteger kk = 0; kk < kPlayerQueueLength - queueCount; kk++) {
        if (_videoIndex > self.videoPostArray.count - 1) {
            break;
        }
        VideoPost *post =  self.videoPostArray[_videoIndex];
        if (post.localUrl) {
            [self insertVideoInThePlayerQueue:post];
        }
        _videoIndex ++;
    }
    if (self.avQueueVideoPlayer.items.count != 0) {
        self.playingCountLabel.text = [NSString stringWithFormat:@"%lu / %lu",((AVPlayerItem *)self.avQueueVideoPlayer.items.firstObject).indexInVideoArray,self.videoPostArray.count];
        [self.avQueueVideoPlayer play];
    } else {
        // todo
        [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(playVideos) userInfo:nil repeats:NO];
    }
}

// After an item is played, add a new end to the end of the queue
- (void)playerItemDidReachEnd:(NSNotification *)notification
{
    // Save item date
    if (notification) {
        AVPlayerItem *itemPlayed = (AVPlayerItem *)notification.object;
        [GeneralUtils saveLastVideoSeenDate:itemPlayed.videoCreationDate];
        [self.avQueueVideoPlayer removeItem:itemPlayed];
    }
    
    // Playing count label
    if (self.avQueueVideoPlayer.items.count > 0) {
        self.playingCountLabel.text = [NSString stringWithFormat:@"%lu / %lu",((AVPlayerItem *)self.avQueueVideoPlayer.items.firstObject).indexInVideoArray,self.videoPostArray.count];
    }
    
    // Add new post to the queue
    
    // First, security check
    if (self.videoPostArray.count == 0 || _videoIndex >= self.videoPostArray.count) {
        if (self.avQueueVideoPlayer.items.count == 0) {
            [self setInteractioMode];
        }
        return;
    }
    
    // Get post and increment index
    VideoPost *post =  self.videoPostArray[_videoIndex];
    _videoIndex ++;
    if (post.localUrl) {
        [self insertVideoInThePlayerQueue:post];
    } else {
        [self playerItemDidReachEnd:nil];
    }
}

// Insert video at the end of the queue
- (void)insertVideoInThePlayerQueue:(VideoPost *)videoPost
{
    AVAsset *playerAsset = [AVAsset assetWithURL:videoPost.localUrl];
    
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:playerAsset];
    playerItem.videoCreationDate = videoPost.createdAt;
    playerItem.indexInVideoArray = 1 + [self.videoPostArray indexOfObject:videoPost];
    [self.avQueueVideoPlayer insertItem:playerItem afterItem:self.avQueueVideoPlayer.items.lastObject];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(playerItemDidReachEnd:)
                                                 name: AVPlayerItemDidPlayToEndTimeNotification
                                               object: playerItem];
    
//    NSArray *keys = [NSArray arrayWithObject:@"playable"];
//    
//    [playerAsset loadValuesAsynchronouslyForKeys:keys completionHandler:^() {
//        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:playerAsset];
//        playerItem.videoCreationDate = videoPost.createdAt;
//        playerItem.indexInVideoArray = 1 + [self.videoPostArray indexOfObject:videoPost];
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [self.avQueueVideoPlayer insertItem:playerItem afterItem:self.avQueueVideoPlayer.items.lastObject];
//            [[NSNotificationCenter defaultCenter] addObserver: self
//                                                     selector: @selector(playerItemDidReachEnd:)
//                                                         name: AVPlayerItemDidPlayToEndTimeNotification
//                                                       object: playerItem];
//        });
//    }];
}

// --------------------------------------------
#pragma mark - Recording
// --------------------------------------------
- (void)startRecording {
    [self prepareSession];
    
    // Start UI + progress bar anim
    self.recordingProgressContainer.hidden = NO;
    [self.recordingProgressBar.layer removeAllAnimations];
    self.recordingProgressBar.frame = CGRectMake(0,0, 0, self.recordingProgressContainer.frame.size.height);
    [UIView animateWithDuration:kRecordSessionMaxDuration
                          delay:0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         [self.recordingProgressBar setFrame:CGRectMake(0,0,self.recordingProgressContainer.frame.size.width, self.recordingProgressContainer.frame.size.height)];
                     } completion:nil];
    
    // Begin appending video/audio buffers to the session
    [self.recorder record];
}

- (void)stopRecording {
    self.recordingProgressContainer.hidden = YES;
    [self playVideos];
    [self.recorder pause:^{
        [self exportAndSaveSession:self.recorder.session];
    }];
}

- (void)exportAndSaveSession:(SCRecordSession *)recordSession {
    if (CMTimeGetSeconds(recordSession.segmentsDuration) < kRecordMinDuration) {
        [self displayTopMessage:NSLocalizedString(@"video_too_short", nil)];
    } else {
        _isExporting = YES;
        [recordSession mergeSegmentsUsingPreset:AVAssetExportPresetHighestQuality completionHandler:^(NSURL *url, NSError *error) {
            if (error == nil) {
                VideoPost *post = [VideoPost createPostWithRessourceUrl:url];
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
                NSLog(@"Export failed: %@", error);
            }
            _isExporting = NO;
        }];
    }
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

// ------------------------------
#pragma mark Message
// ------------------------------
- (void)displayTopMessage:(NSString *)message
{
    UIView *messageView = [[UIView alloc] initWithFrame:CGRectMake(0, - kTopMessageViewHeight, self.view.frame.size.width, kTopMessageViewHeight)];
    messageView.backgroundColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:0.5];
    UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, messageView.frame.size.height - kTopMessageLabelHeight - 5, messageView.frame.size.width - 20 - 5, kTopMessageLabelHeight)];
    messageLabel.textAlignment = NSTextAlignmentCenter;
    messageLabel.text = message;
    messageLabel.font = [UIFont systemFontOfSize:14];
    messageLabel.textColor = [UIColor whiteColor];
    [messageView addSubview:messageLabel];
    [self.view addSubview:messageView];
    [UIView animateWithDuration:kTopMessageAnimDuration
                     animations:^(){
                         messageView.frame = CGRectMake(0, 0, messageView.frame.size.width, kTopMessageViewHeight);
                     } completion:^(BOOL completed) {
                         if (completed) {
                             [UIView animateWithDuration:kTopMessageAnimDuration
                                                   delay:kTopMessageAnimDelay
                                                 options:UIViewAnimationOptionCurveLinear
                                              animations:^(){
                                                  messageView.frame = CGRectMake(0, - kTopMessageViewHeight, messageView.frame.size.width, kTopMessageViewHeight);
                                              } completion:^(BOOL completed) {
                                                  [messageView removeFromSuperview];
                                              }];
                         } else {
                             [messageView removeFromSuperview];
                         }
                     }];
}

// --------------------------------------------
#pragma mark - UI
// --------------------------------------------

- (void)setPlayingMode
{
    self.thumbTableView.hidden = YES;
    self.replayButton.hidden = YES;
    self.playingCountLabel.hidden = NO;
    [self.playerLayer setHidden:NO];
}

- (void)setRecordingMode
{
    self.thumbTableView.hidden = YES;
    self.replayButton.hidden = YES;
    self.playingCountLabel.hidden = YES;
    [self.playerLayer setHidden:YES];
    [self.avQueueVideoPlayer pause];
}

- (void)setInteractioMode
{
    [self.playerLayer setHidden:NO];
    self.playingCountLabel.text = @"";
    self.replayButton.hidden = NO;
    self.thumbTableView.hidden = NO;
    [self.thumbTableView reloadData];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

// ------------------------------
#pragma mark TableView
// ------------------------------
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.videoPostArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.thumbTableView dequeueReusableCellWithIdentifier:@"ThumbCell"];
    VideoPost *post = (VideoPost *)self.videoPostArray[indexPath.row];
    [cell.imageView setImage:post.thumbnail];
    [cell.imageView setContentMode:UIViewContentModeScaleAspectFill];
    cell.textLabel.text = @"Bob";
    return cell;
}

@end
