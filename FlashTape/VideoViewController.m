//
//  VideoViewController.m
//  FlashTape
//
//  Created by Baptiste Truchot on 4/25/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
#import <AddressBook/AddressBook.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "MBProgressHUD.h"

#import "ApiManager.h"
#import "VideoPost.h"

#import "VideoViewController.h"

#import "AVPlayerItem+VideoDate.h"
#import "AddressbookUtils.h"
#import "ConstantUtils.h"
#import "ColorUtils.h"
#import "GeneralUtils.h"
#import "NSDate+DateTools.h"

@interface VideoViewController ()

// Playing
@property (strong, nonatomic) NSMutableArray *videoPostArray;
@property (nonatomic) ABAddressBookRef addressBook;
@property (strong, nonatomic) NSDictionary *contactDictionnary;
@property (strong, nonatomic) AVQueuePlayer *avQueueVideoPlayer;
@property (strong, nonatomic) AVPlayerLayer *playerLayer;
@property (weak, nonatomic) IBOutlet UILabel *playingCountLabel;
@property (weak, nonatomic) IBOutlet UIButton *replayButton;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIView *metadataView;

// Recording
@property (weak, nonatomic) IBOutlet UIView *recordingProgressContainer;
@property (strong, nonatomic) SCRecorder *recorder;
@property (strong, nonatomic) UITapGestureRecognizer *tapGestureRecogniser;
@property (strong, nonatomic) UILongPressGestureRecognizer *longPressGestureRecogniser;
@property (weak, nonatomic) IBOutlet UIView *previewView;
@property (strong, nonatomic) UIView *recordingProgressBar;
@property (weak, nonatomic) IBOutlet UILabel *recordTutoLabel;
@property (weak, nonatomic) IBOutlet UIButton *cameraSwitchButton;

// Sending
@property (strong, nonatomic) NSMutableArray *failedVideoPostArray;
@property (nonatomic) NSInteger isSendingCount;
@property (weak, nonatomic) IBOutlet UIView *sendingLoaderView;

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
    self.isSendingCount = 0;
    
    // Init gesture
    self.longPressGestureRecogniser = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGesture:)];
    self.longPressGestureRecogniser.delegate = self;
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
    _recorder.videoConfiguration.preset = SCPresetLowQuality;
    _recorder.audioConfiguration.preset = SCPresetLowQuality;
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
    self.playerLayer.backgroundColor = [UIColor blackColor].CGColor;
    self.playerLayer.hidden = YES;
    
    // Labels
    [self.view bringSubviewToFront:self.playingCountLabel];
    [self.view bringSubviewToFront:self.metadataView];
    self.playingCountLabel.text = @"";
    self.nameLabel.text = @"";
    self.timeLabel.text = @"";
    self.recordTutoLabel.text = NSLocalizedString(@"hold_ro_record_label", nil);
    self.replayButton.hidden = YES;
    
    // Get contacts and retrieve videos
    self.contactDictionnary = [AddressbookUtils getContactDictionnary];
    [self retrieveVideo];
    
    // Init address book
    self.addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        ABAddressBookRequestAccessWithCompletion(self.addressBook, ^(bool granted, CFErrorRef error) {
            if (granted) {
                NSDictionary *newContactDictionnary = [AddressbookUtils getFormattedPhoneNumbersFromAddressBook:self.addressBook];
                if (self.contactDictionnary.count != newContactDictionnary.count) {
                    [self retrieveVideo];
                }
                self.contactDictionnary = newContactDictionnary;
                [AddressbookUtils saveContactDictionnary:self.contactDictionnary];
            }
        });
    });
    
    // Video Post array
    self.videoPostArray = [NSMutableArray new];
    self.failedVideoPostArray = [NSMutableArray new];
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
    
    // Start with camera
    [self setPreviewMode];
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
    [self setPreviewMode];
    [self retrieveVideo];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Disable iOS 7 back gesture
    [self.navigationController.navigationBar setHidden:YES];
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    self.navigationController.interactivePopGestureRecognizer.delegate = self;
}


// --------------------------------------------
#pragma mark - Feed
// --------------------------------------------
- (void)retrieveVideo {
    // Add current user to contacts array
    NSMutableArray *contactArray = [NSMutableArray arrayWithArray:[self.contactDictionnary allKeys]];
    [contactArray addObject:[User currentUser].username];
    
    // Get video
    [ApiManager getVideoFromContacts:contactArray
                             success:^(NSArray *posts) {
                                 self.videoPostArray = [NSMutableArray arrayWithArray:posts];
                                 [self setReplayButtonUI];
                             } failure:^(NSError *error) {
                                 // todo BT handle error
                             }];
}

// --------------------------------------------
#pragma mark - Actions
// --------------------------------------------
- (void)handleLongPressGesture:(UILongPressGestureRecognizer *)gesture
{
    if (_isExporting)
        return;
    
    if (gesture.state == UIGestureRecognizerStateBegan) {
        [self startRecording];
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        // do nothing
    } else {
        if ([self.recorder isRecording])
            [self stopRecording];
    }
}

- (void)handleTapGesture:(UITapGestureRecognizer *)gesture
{
    BOOL playingMode = !self.playerLayer.hidden;
    if (playingMode) {
        // avance to next video
        [self.avQueueVideoPlayer advanceToNextItem];
        [self playerItemDidReachEnd:nil];
    }
}

- (IBAction)replayButtonClicked:(id)sender {
    if (self.failedVideoPostArray.count > 0) {
        [self sendFailedVideo];
    } else {
        [self playVideos];
    }
}

- (IBAction)flipCameraButtonClicked:(id)sender {
    self.recorder.device = self.recorder.device == AVCaptureDevicePositionBack ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack;
}

// --------------------------------------------
#pragma mark - Playing
// --------------------------------------------
- (void)playVideos {
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
        [self setPlayingMode:YES];
        [self setPlayingMetaData];
        [self.avQueueVideoPlayer play];
    } else {
        // todo bt make robust
        [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(playVideos) userInfo:nil repeats:NO];
    }
}

// After an item is played, add a new end to the end of the queue
- (void)playerItemDidReachEnd:(NSNotification *)notification
{
    // Save item date
    if (notification) {
        AVPlayerItem *itemPlayed = (AVPlayerItem *)notification.object;
        [GeneralUtils saveLastVideoSeenDate:itemPlayed.videoPost.createdAt];
        [self.avQueueVideoPlayer removeItem:itemPlayed];
    }
    
    // Playing count label
    if (self.avQueueVideoPlayer.items.count > 0) {
        [self setPlayingMetaData];
    }
    
    // Add new post to the queue
    
    // Security check
    // If no more video to play, return to camera
    if (self.videoPostArray.count == 0 || _videoIndex >= self.videoPostArray.count) {
        if (self.avQueueVideoPlayer.items.count == 0) {
            [self setPreviewMode];
        }
        return;
    }
    
    // Get post and update index
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
    playerItem.videoPost = videoPost;
    playerItem.indexInVideoArray = 1 + [self.videoPostArray indexOfObject:videoPost];
    [self.avQueueVideoPlayer insertItem:playerItem afterItem:self.avQueueVideoPlayer.items.lastObject];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(playerItemDidReachEnd:)
                                                 name: AVPlayerItemDidPlayToEndTimeNotification
                                               object: playerItem];
}

- (void)setPlayingMetaData {
    AVPlayerItem *itemPlayed = ((AVPlayerItem *)self.avQueueVideoPlayer.items.firstObject);
    self.playingCountLabel.text = [NSString stringWithFormat:@"%lu / %lu",itemPlayed.indexInVideoArray,self.videoPostArray.count];
    
    self.nameLabel.text = self.contactDictionnary[itemPlayed.videoPost.user.username];
    self.timeLabel.text = [itemPlayed.videoPost.createdAt timeAgoSinceNow];
}

// --------------------------------------------
#pragma mark - Recording
// --------------------------------------------
- (void)startRecording {
    [self prepareSession];
    [self setRecordingMode];
    
    // Begin appending video/audio buffers to the session
    [self.recorder record];
}

- (void)stopRecording {
    [self.recorder pause:^{
        [self exportAndSaveSession:self.recorder.session];
    }];
    [self setPreviewMode];
}

- (void)exportAndSaveSession:(SCRecordSession *)recordSession {
    if (CMTimeGetSeconds(recordSession.segmentsDuration) < kRecordMinDuration) {
        [self displayTopMessage:NSLocalizedString(@"video_too_short", nil)];
    } else {
        _isExporting = YES;
        [recordSession mergeSegmentsUsingPreset:AVAssetExportPresetHighestQuality completionHandler:^(NSURL *url, NSError *error) {
            if (error == nil) {
                VideoPost *post = [VideoPost createPostWithRessourceUrl:url];
                [self sendVideoPost:post];
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
#pragma mark - Sending
// --------------------------------------------
- (void)sendVideoPost:(VideoPost *)post
{
    self.isSendingCount ++;
    [ApiManager saveVideoPost:post
            andExecuteSuccess:^() {
                self.isSendingCount --;
                [self.videoPostArray addObject:post];
                [self setReplayButtonUI];
            } failure:^(NSError *error) {
                self.isSendingCount --;
                [self.failedVideoPostArray addObject:post];
                [self setReplayButtonUI];
            }];
}

- (void)sendFailedVideo
{
    NSArray *tempArray = [NSArray arrayWithArray:self.failedVideoPostArray];
    [self.failedVideoPostArray removeAllObjects];
    for (VideoPost *post in tempArray) {
        [self sendVideoPost:post];
    }
    [self setReplayButtonUI];
}

- (void)setIsSendingCount:(NSInteger)isSendingCount {
    _isSendingCount = isSendingCount;
    // sending anim
    if (isSendingCount == 0) {
        [MBProgressHUD hideHUDForView:self.sendingLoaderView animated:YES];
    } else {
        MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:self.sendingLoaderView];
        hud.color = [UIColor clearColor];
        hud.activityIndicatorColor = [ColorUtils orange];
        [self.sendingLoaderView addSubview:hud];
        [hud show:YES];
    }
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
    messageView.backgroundColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:0.8];
    UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, messageView.frame.size.height - kTopMessageLabelHeight, messageView.frame.size.width - 20 - 5, kTopMessageLabelHeight)];
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

- (void)setPlayingMode:(BOOL)flag
{
    self.playingCountLabel.hidden = !flag;
    self.metadataView.hidden = !flag;
    [self.playerLayer setHidden:!flag];
    if (flag) {
        self.longPressGestureRecogniser.minimumPressDuration = 0.5;
    } else {
        [self.avQueueVideoPlayer pause];
    }
}

- (void)setPreviewMode
{
    [self setPlayingMode:NO];
    
    self.longPressGestureRecogniser.minimumPressDuration = 0;
    self.recordingProgressContainer.hidden = YES;
    self.replayButton.hidden = NO;
    self.recordTutoLabel.hidden = NO;
    self.cameraSwitchButton.hidden = NO;
    [self setReplayButtonUI];
}

- (void)setRecordingMode {
    [self setPlayingMode:NO];
    
    self.replayButton.hidden = YES;
    self.recordTutoLabel.hidden = YES;
    self.cameraSwitchButton.hidden = YES;
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
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)setReplayButtonUI {
    if (self.failedVideoPostArray.count > 0) {
        // failed video state
        self.replayButton.backgroundColor = [ColorUtils transparentRed];
        [self.replayButton setTitle:NSLocalizedString(@"video_sending_failed", nil) forState:UIControlStateNormal];
        // todo bt
    } else if (self.videoPostArray.count == 0) {
        // No button state
        self.replayButton.hidden = YES;
        return;
    } else {
        // Replay or new state
        NSString *buttonTitle;
        NSDate *lastSeenDate = [GeneralUtils getLastVideoSeenDate];
        int kkk = 0;
        for (int i = (int)(self.videoPostArray.count - 1) ; i >= 0 ; i--) {
            NSDate *videoDate = ((VideoPost *)(self.videoPostArray[i])).createdAt ? ((VideoPost *)(self.videoPostArray[i])).createdAt : [NSDate date];
            if ([videoDate compare:lastSeenDate] == NSOrderedDescending) {
                kkk ++;
            } else {
                break;
            }
        }
        if (kkk == 0) {
            _videoIndex = 0;
            self.replayButton.backgroundColor = [ColorUtils transparentBlack];
            buttonTitle = NSLocalizedString(@"replay_label", nil);
        } else {
            _videoIndex = self.videoPostArray.count - kkk;
            self.replayButton.backgroundColor = [ColorUtils transparentOrange];
            buttonTitle = [NSString stringWithFormat:@"%d %@",kkk,kkk < 2 ? NSLocalizedString(@"new_video_label", nil) : NSLocalizedString(@"new_videos_label", nil)];
        }
        [self.replayButton setTitle:buttonTitle forState:UIControlStateNormal];
        self.replayButton.hidden = NO;
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    // Disallow recognition of tap gestures in the segmented control.
    if ((touch.view == self.replayButton || touch.view == self.cameraSwitchButton)) {
        return NO;
    }
    return YES;
}

@end
