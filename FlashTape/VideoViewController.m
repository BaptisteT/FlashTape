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
#import "UICustomLineLabel.h"

#import "ApiManager.h"
#import "VideoPost.h"

#import "FriendsViewController.h"
#import "VideoViewController.h"

#import "AVPlayerItem+VideoDate.h"
#import "AddressbookUtils.h"
#import "ConstantUtils.h"
#import "ColorUtils.h"
#import "GeneralUtils.h"
#import "NSDate+DateTools.h"
#import "TrackingUtils.h"

@interface VideoViewController ()

// Playing
@property (strong, nonatomic) NSMutableArray *videoPostArray;
@property (nonatomic) ABAddressBookRef addressBook;
@property (strong, nonatomic) NSDictionary *contactDictionnary;
@property (strong, nonatomic) AVQueuePlayer *avQueueVideoPlayer;
@property (strong, nonatomic) AVPlayerLayer *playerLayer;
@property (weak, nonatomic) IBOutlet UIButton *replayButton;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIView *metadataView;
@property (strong, nonatomic) UIView *playingProgressView;
@property (strong, nonatomic) UITapGestureRecognizer *playingProgressViewTapGesture;

// Recording
@property (weak, nonatomic) IBOutlet UIView *recordingProgressContainer;
@property (strong, nonatomic) SCRecorder *recorder;
@property (strong, nonatomic) UITapGestureRecognizer *tapGestureRecogniser;
@property (strong, nonatomic) UILongPressGestureRecognizer *longPressGestureRecogniser;
@property (weak, nonatomic) IBOutlet UIView *cameraView;
@property (strong, nonatomic) UIView *recordingProgressBar;
@property (weak, nonatomic) IBOutlet UICustomLineLabel *recordTutoLabel;
@property (weak, nonatomic) IBOutlet UIButton *cameraSwitchButton;
@property (weak, nonatomic) IBOutlet UIButton *friendListButton;

// Preview Playing
@property (weak, nonatomic) IBOutlet SCVideoPlayerView *previewView;
@property (weak, nonatomic) IBOutlet UILabel *releaseToSendTuto;
@property (weak, nonatomic) IBOutlet UIView *cancelAreaView;
@property (weak, nonatomic) IBOutlet UILabel *cancelTutoLabel;
@property (weak, nonatomic) IBOutlet UIView *cancelConfirmView;
@property (weak, nonatomic) IBOutlet UILabel *cancelConfirmTutoLabel;

// Sending
@property (strong, nonatomic) VideoPost *postToSend; // preview post
@property (strong, nonatomic) NSMutableArray *failedVideoPostArray;
@property (nonatomic) NSInteger isSendingCount;
@property (weak, nonatomic) IBOutlet UIView *sendingLoaderView;


@end

@implementation VideoViewController {
    NSInteger _videoIndex;
    BOOL _isExporting;
    BOOL _longPressRunning;
}

// --------------------------------------------
#pragma mark - Life Cycle
// --------------------------------------------

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _isExporting = NO;
    _longPressRunning = NO;
    self.isSendingCount = 0;
    
    // Init gesture
    self.longPressGestureRecogniser = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGesture:)];
    self.longPressGestureRecogniser.delegate = self;
    [self.view addGestureRecognizer:self.longPressGestureRecogniser];
    self.tapGestureRecogniser = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGestureOnPlayer:)];
    [self.view addGestureRecognizer:self.tapGestureRecogniser];
    
    // Create the recorder
    self.recorder = [SCRecorder recorder];
    _recorder.captureSessionPreset = [SCRecorderTools bestCaptureSessionPresetCompatibleWithAllDevices];
    _recorder.maxRecordDuration = CMTimeMake(10, 1);
    _recorder.delegate = self;
    _recorder.autoSetVideoOrientation = YES;
    _recorder.device = AVCaptureDevicePositionFront;
    _recorder.maxRecordDuration = CMTimeMake(kRecordSessionMaxDuration, 1);
    _recorder.videoConfiguration.bitrate = 2000000;
    SCRecordSession *session = [SCRecordSession recordSession];
    session.fileType = AVFileTypeQuickTimeMovie;
    _recorder.session = session;
    if (![self.recorder startRunning]) { // Start running the flow of buffers
        NSLog(@"Something wrong there: %@", self.recorder.error);
    }
    
    // Filter
    SCFilter *testFilter = [SCFilter filterWithCIFilterName:@"CIColorCube"];
    [testFilter setParameterValue:@64 forKey:@"inputCubeDimension"];
    [testFilter setParameterValue:UIImageJPEGRepresentation([UIImage imageNamed:@"green"],1) forKey:@"inputCubeData"];
    self.recorder.videoConfiguration.filter = testFilter;
    
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
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    // Metadata
    [self.view bringSubviewToFront:self.metadataView];
    self.playingProgressView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, self.metadataView.frame.size.height)];
    self.playingProgressView.backgroundColor = [ColorUtils transparentOrange];
    self.playingProgressView.userInteractionEnabled = NO;
    [self.metadataView insertSubview:self.playingProgressView atIndex:0];
    self.playingProgressViewTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGestureOnMetadataView:)];
    [self.metadataView addGestureRecognizer:self.playingProgressViewTapGesture];
    self.nameLabel.text = @"";
    self.timeLabel.text = @"";
    
     // Labels
    self.recordTutoLabel.text = NSLocalizedString(@"hold_ro_record_label", nil);
    self.recordTutoLabel.lineType = LineTypeDown;
    self.recordTutoLabel.lineHeight = 4.0f;
    self.replayButton.hidden = YES;    
    
    // Preview
    self.releaseToSendTuto.text = NSLocalizedString(@"release_to_send", nil);
    self.cancelTutoLabel.text = NSLocalizedString(@"move_your_finger_to_cancel", nil);
    self.cancelConfirmTutoLabel.text = NSLocalizedString(@"release_to_cancel", nil);
    self.previewView.player.loopEnabled = YES;
    self.previewView.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
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
                    self.contactDictionnary = newContactDictionnary;
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
                                             selector: @selector(willResignActive)
                                                 name: UIApplicationWillResignActiveNotification
                                               object: nil];
    
    // Start with camera
    [self setCameraMode];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Disable iOS 7 back gesture
    [self.navigationController.navigationBar setHidden:YES];
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    self.navigationController.interactivePopGestureRecognizer.delegate = self;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    // Camera
    self.recorder.previewView = self.cameraView;
}

- (void)willResignActive {
    [self.avQueueVideoPlayer pause];
    [self setCameraMode];
    [self.avQueueVideoPlayer removeAllItems];
}

- (void)willBecomeActiveCallback {
    [self retrieveVideo];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSString * segueName = segue.identifier;
    if ([segueName isEqualToString: @"Friends From Video"]) {
        [self hideUIElementOnCamera:YES];
        ((FriendsViewController *) [segue destinationViewController]).delegate = self;
        ((FriendsViewController *) [segue destinationViewController]).contactDictionnary = self.contactDictionnary;
    }
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
    static BOOL isExporting;
    if (gesture.state == UIGestureRecognizerStateBegan) {
        _longPressRunning = YES;
        isExporting = _isExporting;
        if (!isExporting)
            [self startRecording];
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        if ([self isPreviewMode]) {
            BOOL cancelMode = CGRectContainsPoint(self.cancelAreaView.frame, [gesture locationInView:self.previewView]);
            self.cancelAreaView.hidden = cancelMode;
            self.releaseToSendTuto.hidden = cancelMode;
            self.cancelConfirmView.hidden = !cancelMode;
        }
    } else {
        _longPressRunning = NO;
        if ([self isPreviewMode]) {
            // cancel or send, & stop
            if (!CGRectContainsPoint(self.cancelAreaView.frame, [gesture locationInView:self.previewView])) {
                if (self.postToSend) {
                    [self sendVideoPost:self.postToSend];
                }
            } else {
                if (_isExporting) {
                    // todo bt
                    // boolean not to send
                    // avoid bug iphone 4
                }
            }
            self.postToSend = nil;
        } else if (!isExporting) {
            [self stopRecordingAndExecuteSuccess:^(VideoPost * post) {
                [self sendVideoPost:post];
                _isExporting = NO;
            }];
        }
        [self setCameraMode];
    }
}

- (void)handleTapGestureOnPlayer:(UITapGestureRecognizer *)gesture
{
    BOOL playingMode = !self.playerLayer.hidden;
    if (playingMode) {
        // avance to next video
        AVPlayerItem *itemPlayed = [self.avQueueVideoPlayer currentItem];
        [self.avQueueVideoPlayer advanceToNextItem];
        [self playerItemDidReachEnd:nil];
        [GeneralUtils saveLastVideoSeenDate:itemPlayed.videoPost.createdAt];
    }
}

- (void)handleTapGestureOnMetadataView:(UITapGestureRecognizer *)gesture
{
    if (self.videoPostArray.count < 3) {
        return;
    }
    AVPlayerItem *itemPlayed = [self.avQueueVideoPlayer currentItem];
    [GeneralUtils saveLastVideoSeenDate:itemPlayed.videoPost.createdAt];
    
    float widthPosition = (float)[gesture locationInView:self.metadataView].x / self.metadataView.frame.size.width;
    _videoIndex = (NSInteger)(self.videoPostArray.count * widthPosition);
    [self.avQueueVideoPlayer removeAllItems];
    [self playVideos];
}

- (IBAction)replayButtonClicked:(id)sender {
    if (self.failedVideoPostArray.count > 0) {
        [self sendFailedVideo];
    } else {
        [self playVideos];
        [TrackingUtils trackReplayButtonClicked];
    }
}

- (IBAction)flipCameraButtonClicked:(id)sender {
    self.recorder.device = self.recorder.device == AVCaptureDevicePositionBack ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack;
}

- (IBAction)friendsButtonClicked:(id)sender {
    [self performSegueWithIdentifier:@"Friends From Video" sender:nil];
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
        } else {
            // todo BT
            // handle this case
            [self.replayButton setTitle:[NSString stringWithFormat:@"%@ (%lu%%)",NSLocalizedString(@"downloading_label", nil),post.downloadProgress] forState:UIControlStateNormal];
            [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(setReplayButtonUI) userInfo:nil repeats:NO];
            return;
        }
        _videoIndex ++;
    }
    if (self.avQueueVideoPlayer.items.count != 0) {
        [self setPlayingMetaData];
        [self setPlayingMode:YES];
        [self.avQueueVideoPlayer play];
    } else {
        // todo bt make robust
        // alert ?
    }
}

// After an item is played, add a new end to the end of the queue
- (void)playerItemDidReachEnd:(NSNotification *)notification
{
    [TrackingUtils trackVideoSeen];
    
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
            [self setCameraMode];
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
    AVPlayerItem *itemPlayed = ((AVPlayerItem *)[self.avQueueVideoPlayer currentItem]);
    float startRatio = (float)(itemPlayed.indexInVideoArray - 1 )/ self.videoPostArray.count;
    float progressRatio = (float)itemPlayed.indexInVideoArray / self.videoPostArray.count;
    [self.playingProgressView setFrame:CGRectMake(0, 0, startRatio * self.metadataView.frame.size.width, self.metadataView.frame.size.height)];
    [UIView animateWithDuration:CMTimeGetSeconds([[itemPlayed asset] duration])
                     animations:^{
                         [self.playingProgressView setFrame:CGRectMake(0, 0, progressRatio * self.metadataView.frame.size.width, self.metadataView.frame.size.height)];
                     }];
    
    self.nameLabel.text = self.contactDictionnary[itemPlayed.videoPost.user.username];
    self.timeLabel.text = [itemPlayed.videoPost.createdAt timeAgoSinceNow];
}

// --------------------------------------------
#pragma mark - Recording
// --------------------------------------------
- (void)startRecording {
    [self.recorder.session removeAllSegments];
    [self setRecordingMode];
    
    // Begin appending video/audio buffers to the session
    [self.recorder record];
}

- (void)stopRecordingAndExecuteSuccess:(void(^)(VideoPost *))successBlock {
    if (_isExporting)
        return;
    _isExporting = YES;
    [self.recorder pause:^{
        [self exportAndSaveSession:self.recorder.session
                           success:successBlock];
    }];
}

- (void)exportAndSaveSession:(SCRecordSession *)recordSession
                     success:(void(^)(VideoPost *))successBlock
{
    if (CMTimeGetSeconds(recordSession.segmentsDuration) < kRecordMinDuration) {
        if (CMTimeGetSeconds(recordSession.segmentsDuration) != 0) // to avoid pb segment not ready
            [self displayTopMessage:NSLocalizedString(@"video_too_short", nil)];
        _isExporting = NO;
    } else {
        AVAsset *asset = recordSession.assetRepresentingSegments;
        SCAssetExportSession *assetExportSession = [[SCAssetExportSession alloc] initWithAsset:asset];
        assetExportSession.outputUrl = recordSession.outputUrl;
        assetExportSession.outputFileType = AVFileTypeMPEG4;
        assetExportSession.videoConfiguration.preset = SCPresetMediumQuality;
        assetExportSession.audioConfiguration.preset = SCPresetMediumQuality;
        
        // Audio fade in
        CGFloat fadeLength = 0.5;
        CMTime fadeDuration = CMTimeMakeWithSeconds(fadeLength, 100);
        CMTimeRange fadeInTimeRange = CMTimeRangeMake(kCMTimeZero, fadeDuration);
        CMTime startFadeOutTime = CMTimeMakeWithSeconds(CMTimeGetSeconds(asset.duration) - fadeLength, 100);
        CMTimeRange fadeOutTimeRange = CMTimeRangeMake(startFadeOutTime, fadeDuration);
        AVAssetTrack *track = [asset tracksWithMediaType:AVMediaTypeAudio].firstObject;
        AVMutableAudioMixInputParameters *exportAudioMixInputParameters = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:track];
        exportAudioMixInputParameters.trackID = [track trackID];
        [exportAudioMixInputParameters setVolumeRampFromStartVolume:0. toEndVolume:1.0 timeRange:fadeInTimeRange];
        [exportAudioMixInputParameters setVolumeRampFromStartVolume:1.0 toEndVolume:0. timeRange:fadeOutTimeRange];
        AVMutableAudioMix *exportAudioMix = [AVMutableAudioMix audioMix];
        exportAudioMix.inputParameters = [NSArray arrayWithObject:exportAudioMixInputParameters];
        assetExportSession.audioConfiguration.audioMix = exportAudioMix;
        
        // Export
        [assetExportSession exportAsynchronouslyWithCompletionHandler: ^{
            if (assetExportSession.error == nil) {
                VideoPost *post = [VideoPost createPostWithRessourceUrl:recordSession.outputUrl];
                if (successBlock) {
                    successBlock(post);
                }
            } else {
                NSLog(@"Export failed: %@", assetExportSession.error);
            }
        }];
    }
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
                [TrackingUtils trackVideoSent];
            } failure:^(NSError *error) {
                self.isSendingCount --;
                [self.failedVideoPostArray addObject:post];
                [self setReplayButtonUI];
                [TrackingUtils trackVideoSendingFailure];
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
        [MBProgressHUD hideAllHUDsForView:self.sendingLoaderView animated:YES];
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
    if (_isExporting) {
        return;
    }
    [self.previewView.player setItemByAsset:recordSession.assetRepresentingSegments];
    [self.previewView.player play];
    [self setPreviewMode];
    [self stopRecordingAndExecuteSuccess:^(VideoPost *post) {
        _isExporting = NO;
        if (!_longPressRunning) { // to handle the case of simultaneity
            [self sendVideoPost:post];
            [self setCameraMode];
        } else {
            // Save post to be sent after long press
            self.postToSend = post;
        }
    }];
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
#pragma mark - UI Mode
// --------------------------------------------

- (BOOL)isPreviewMode {
    return !self.previewView.hidden;
}

- (BOOL)isRecordingMode {
    return self.recorder.isRecording;
}

- (void)setPlayingMode:(BOOL)flag
{
    self.metadataView.hidden = !flag;
    [self.playerLayer setHidden:!flag];
    if (flag) {
        [self endPreviewMode];
        self.longPressGestureRecogniser.minimumPressDuration = 0.5;
    } else {
        [self.avQueueVideoPlayer pause];
    }
}

- (void)setCameraMode
{
    [self setPlayingMode:NO];
    [self endPreviewMode];
    
    self.longPressGestureRecogniser.minimumPressDuration = 0;
    self.recordingProgressContainer.hidden = YES;
    [self hideUIElementOnCamera:NO];
    [self setReplayButtonUI];
}

- (void)setRecordingMode {
    [self setPlayingMode:NO];
    [self endPreviewMode];
    
    [self hideUIElementOnCamera:YES];
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

- (void)endPreviewMode {
    self.previewView.hidden = YES;
    [self.previewView.player pause];
}

- (void)setPreviewMode {
    [self setPlayingMode:NO];
    self.cancelConfirmView.hidden = YES;
    self.cancelAreaView.hidden = NO;
    self.releaseToSendTuto.hidden = NO;
    self.previewView.hidden = NO;
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
            buttonTitle = [NSString stringWithFormat:NSLocalizedString(@"replay_label", nil)];
        } else {
            _videoIndex = self.videoPostArray.count - kkk;
            self.replayButton.backgroundColor = [ColorUtils transparentOrange];
            buttonTitle = [NSString stringWithFormat:@"%d %@",kkk,kkk < 2 ? NSLocalizedString(@"new_video_label", nil) : NSLocalizedString(@"new_videos_label", nil)];
        }
        [self.replayButton setTitle:buttonTitle forState:UIControlStateNormal];
        self.replayButton.hidden = NO;
    }
}

- (void)hideUIElementOnCamera:(BOOL)flag {
    self.replayButton.hidden = flag;
    self.recordTutoLabel.hidden = flag;
    self.cameraSwitchButton.hidden = flag;
    self.friendListButton.hidden = flag;
}

// --------------------------------------------
#pragma mark - Details
// --------------------------------------------

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    // Disallow recognition of tap gestures in the segmented control.
    if ((touch.view == self.replayButton || touch.view == self.cameraSwitchButton) || touch.view == self.friendListButton) {
        return NO;
    }
    return YES;
}

@end
