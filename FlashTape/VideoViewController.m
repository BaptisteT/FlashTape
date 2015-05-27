//
//  VideoViewController.m
//  FlashTape
//
//  Created by Baptiste Truchot on 4/25/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
#import <AddressBook/AddressBook.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "MBProgressHUD.h"
#import "UICustomLineLabel.h"

#import "ApiManager.h"
#import "DatastoreUtils.h"
#import "VideoPost.h"

#import "CaptionTextView.h"
#import "FriendsViewController.h"
#import "VideoViewController.h"

#import "AddressbookUtils.h"
#import "ConstantUtils.h"
#import "ColorUtils.h"
#import "GeneralUtils.h"
#import "NSDate+DateTools.h"
#import "TrackingUtils.h"
#import "VideoUtils.h"

// Degrees to radians
#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)

@interface VideoViewController ()

// Contacts
@property (nonatomic) ABAddressBookRef addressBook;
@property (strong, nonatomic) NSDictionary *contactDictionnary;
@property (strong, nonatomic) NSArray *friends;

// Playing
@property (strong, nonatomic) NSMutableArray *videoPostArray;
@property (weak, nonatomic) IBOutlet SCVideoPlayerView *friendVideoView;
@property (strong, nonatomic) NSMutableArray *videoPlayingObservedTimesArray;
@property (strong, nonatomic) NSMutableArray *compositionTimerObserverArray;
@property (weak, nonatomic) IBOutlet UIButton *replayButton;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIView *metadataView;
@property (strong, nonatomic) UIView *playingProgressView;
@property (strong, nonatomic) UILongPressGestureRecognizer *playingProgressViewLongPressGesture;
@property (strong, nonatomic) AVAudioPlayer *whiteNoisePlayer;
@property (strong, nonatomic) UITapGestureRecognizer *videoTapGestureRecogniser;

// Recording
@property (weak, nonatomic) IBOutlet UIView *recordingProgressContainer;
@property (strong, nonatomic) SCRecorder *recorder;
@property (strong, nonatomic) UILongPressGestureRecognizer *longPressGestureRecogniser;
@property (weak, nonatomic) IBOutlet UIView *cameraView;
@property (strong, nonatomic) UIView *recordingProgressBar;
@property (weak, nonatomic) IBOutlet UICustomLineLabel *recordTutoLabel;
@property (weak, nonatomic) IBOutlet UIButton *cameraSwitchButton;
@property (weak, nonatomic) IBOutlet UIButton *friendListButton;

// Caption
@property (weak, nonatomic) IBOutlet UIButton *captionButton;
@property (strong, nonatomic) CaptionTextView *captionTextView;
@property (nonatomic) CGAffineTransform captionTransform;
@property (nonatomic) CGPoint captionCenter;

// Preview Playing
@property (weak, nonatomic) IBOutlet SCVideoPlayerView *previewView;
@property (weak, nonatomic) IBOutlet UICustomLineLabel *releaseToSendTuto;
@property (weak, nonatomic) IBOutlet UIView *cancelAreaView;
@property (weak, nonatomic) IBOutlet UILabel *cancelTutoLabel;
@property (weak, nonatomic) IBOutlet UIView *cancelConfirmView;
@property (weak, nonatomic) IBOutlet UICustomLineLabel *cancelConfirmTutoLabel;

// Sending
@property (strong, nonatomic) VideoPost *postToSend; // preview post
@property (strong, nonatomic) NSMutableArray *failedVideoPostArray;
@property (nonatomic) NSInteger isSendingCount;
@property (weak, nonatomic) IBOutlet UIView *sendingLoaderView;
@property (strong, nonatomic) MBProgressHUD* sendingHud;


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

    _videoIndex = 0;
    [[UIApplication sharedApplication] setStatusBarHidden:YES];

    _isExporting = NO;
    _longPressRunning = NO;
    self.isSendingCount = 0;
    
    // HUD
    self.sendingHud = [[MBProgressHUD alloc] initWithView:self.sendingLoaderView];
    self.sendingHud.color = [UIColor clearColor];
    self.sendingHud.activityIndicatorColor = [UIColor whiteColor];
    [self.sendingLoaderView addSubview:self.sendingHud];
    
    // Recording gesture
    self.longPressGestureRecogniser = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGesture:)];
    self.longPressGestureRecogniser.delegate = self;
    self.longPressGestureRecogniser.minimumPressDuration = 0;
    [self.cameraView addGestureRecognizer:self.longPressGestureRecogniser];
    
    // Caption
    self.captionTextView = [[CaptionTextView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height/2, self.view.frame.size.width, 0)];
    [self.cameraView insertSubview:self.captionTextView belowSubview:self.replayButton];
    self.captionTextView.hidden = YES;
    self.captionTextView.text = @"";
    self.captionTextView.delegate = self;
    self.captionTextView.captionDelegate = self;
    self.captionTransform = CGAffineTransformIdentity;
    
    // Audio session
    AVAudioSession* audioSession = [AVAudioSession sharedInstance];
    BOOL success; NSError* error;
    success = [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord
                             error:&error];
    if (!success)
        NSLog(@"AVAudioSession error setting category:%@",error);
    [audioSession setActive:YES error:nil];
    
    // Create the recorder
    self.recorder = [SCRecorder recorder];
    _recorder.captureSessionPreset = [SCRecorderTools bestCaptureSessionPresetCompatibleWithAllDevices];
    _recorder.delegate = self;
    _recorder.autoSetVideoOrientation = YES;
    _recorder.device = [GeneralUtils getLastVideoSelfieModePref] ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack;
    _recorder.videoConfiguration.preset = SCPresetMediumQuality;
    _recorder.audioConfiguration.preset = SCPresetMediumQuality;
     _recorder.autoSetVideoOrientation = NO;
    _recorder.maxRecordDuration = CMTimeMakeWithSeconds(kRecordSessionMaxDuration + kVideoEndCutDuration, 600);
    SCRecordSession *session = [SCRecordSession recordSession];
    session.fileType = AVFileTypeMPEG4;
    _recorder.session = session;

    // Filter
//    if (![GeneralUtils isiPhone4]) {
        SCFilter *testFilter = [SCFilter filterWithCIFilterName:@"CIColorCube"];
        [testFilter setParameterValue:@64 forKey:@"inputCubeDimension"];
        [testFilter setParameterValue:UIImageJPEGRepresentation([UIImage imageNamed:@"green"],1) forKey:@"inputCubeData"];
        self.recorder.videoConfiguration.filter = testFilter;
//    } else {
//        self.recorder.videoConfiguration.filter = nil;
//    }
    
    // Start running the flow of buffers
    if (![self.recorder startRunning]) {
        NSLog(@"Something wrong there: %@", self.recorder.error);
    }
    
    // Recording progress bar
    self.recordingProgressBar = [[UIView alloc] init];
    self.recordingProgressBar.backgroundColor = [UIColor whiteColor];
    [self.recordingProgressContainer addSubview:self.recordingProgressBar];
    self.recordingProgressContainer.hidden = YES;
    
    // Video player
    self.friendVideoView.player.loopEnabled = NO;
    self.friendVideoView.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    // Video tap gesture
    self.videoTapGestureRecogniser = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapOnVideo)];
    [self.friendVideoView addGestureRecognizer:self.videoTapGestureRecogniser];
    
    // White noise player
    NSString *soundPath = [[NSBundle mainBundle] pathForResource:@"whiteNoise" ofType:@".wav"];
    NSURL *soundURL = [NSURL fileURLWithPath:soundPath];
    self.whiteNoisePlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:soundURL error:nil];
    self.whiteNoisePlayer.volume = 0.001;
    self.whiteNoisePlayer.numberOfLoops = -1;
    
    // Metadata
    [self.friendVideoView bringSubviewToFront:self.metadataView];
    self.playingProgressView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, self.metadataView.frame.size.height)];
    self.playingProgressView.backgroundColor = [UIColor whiteColor];
    self.playingProgressView.userInteractionEnabled = NO;
    [self.metadataView insertSubview:self.playingProgressView atIndex:0];
    self.playingProgressViewLongPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGestureOnMetaDataView:)];
    self.playingProgressViewLongPressGesture.minimumPressDuration = 0;
    [self.metadataView addGestureRecognizer:self.playingProgressViewLongPressGesture];
    self.nameLabel.text = @"";
    self.timeLabel.text = @"";
    
     // Labels
    if ([User currentUser].score >= kMaxScoreBeforeHidingTuto) {
        [self.recordTutoLabel removeFromSuperview];
        [self.releaseToSendTuto removeFromSuperview];
    } else {
        self.recordTutoLabel.text = NSLocalizedString(@"hold_ro_record_label", nil);
        self.recordTutoLabel.lineType = LineTypeDown;
        self.recordTutoLabel.lineHeight = 4.0f;
    }
    self.replayButton.hidden = YES;
    
    // Preview
    self.releaseToSendTuto.text = NSLocalizedString(@"release_to_send", nil);
    self.releaseToSendTuto.lineType = LineTypeDown;
    self.releaseToSendTuto.lineHeight = 4.0f;
    self.cancelTutoLabel.text = NSLocalizedString(@"move_your_finger_to_cancel", nil);
    self.cancelConfirmTutoLabel.text = NSLocalizedString(@"release_to_cancel", nil);
    self.cancelConfirmTutoLabel.lineType = LineTypeDown;
    self.cancelConfirmTutoLabel.lineHeight = 4.0f;
    self.previewView.player.loopEnabled = YES;
    self.previewView.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    self.previewView.hidden = YES;
    
    // Get local videos
    self.videoPostArray = [NSMutableArray arrayWithArray:[DatastoreUtils getVideoLocallyFromUser:nil]];
    self.failedVideoPostArray = [NSMutableArray new];
    
    // Retrieve friends from local datastore
    self.contactDictionnary = [AddressbookUtils getContactDictionnary];
    [DatastoreUtils getFriendsFromLocalDatastoreAndExecuteSuccess:^(NSArray *friends) {
        self.friends = friends;
        [self retrieveVideo];
    } failure:nil];
    
    // Load address book, friends & video (if the result is different from cashing)
    self.addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        ABAddressBookRequestAccessWithCompletion(self.addressBook, ^(bool granted, CFErrorRef error) {
            if (granted) {
                self.contactDictionnary = [AddressbookUtils getFormattedPhoneNumbersFromAddressBook:self.addressBook];
                NSMutableArray *contactArray = [NSMutableArray arrayWithArray:[self.contactDictionnary allKeys]];
                [contactArray addObject:[User currentUser].username];
                [ApiManager getListOfFriends:contactArray
                                     success:^(NSArray *friends) {
                                         if (friends.count != self.friends.count) {
                                             [self retrieveVideo];
                                         }
                                         self.friends = friends;
                                     } failure:nil];
                [AddressbookUtils saveContactDictionnary:self.contactDictionnary];
            }
        });
    });
    
    // Callback
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(willBecomeActiveCallback)
                                                 name: UIApplicationWillEnterForegroundNotification
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(willResignActive)
                                                 name: UIApplicationWillResignActiveNotification
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(routeChangeCallback:)
                                                 name: AVAudioSessionRouteChangeNotification
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
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
    [self setPlayingMode:NO];
    [self setCameraMode];
}

- (void)willBecomeActiveCallback {
    [self retrieveVideo];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSString * segueName = segue.identifier;
    if ([segueName isEqualToString: @"Friends From Video"]) {
        [self hideUIElementOnCamera:YES];
        ((FriendsViewController *) [segue destinationViewController]).delegate = self;
        ((FriendsViewController *) [segue destinationViewController]).friends = self.friends;
        ((FriendsViewController *) [segue destinationViewController]).contactDictionnary = self.contactDictionnary;
    }
}

-(void)routeChangeCallback:(NSNotification*)notification {
    if ([self isPlayingMode]) {
        // To avoid pause when plug / unplug headset
        [self.friendVideoView.player play];
    }
}


// --------------------------------------------
#pragma mark - Feed
// --------------------------------------------
- (void)retrieveVideo {
    // Get video
    [ApiManager getVideoFromContacts:self.friends
                             success:^(NSArray *posts) {
                                 [self setVideoArray:posts];
                             } failure:nil];
}

- (void)setVideoArray:(NSArray *)videoPostArray {
    self.videoPostArray = [NSMutableArray arrayWithArray:videoPostArray];
    [self setReplayButtonUI];
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
        if (!isExporting) {
            [self startRecording];
        }
        [self.captionTextView resignFirstResponder];
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        if ([self isPreviewMode]) {
            BOOL cancelMode = CGRectContainsPoint(self.cancelAreaView.frame, [gesture locationInView:self.previewView]);
            self.cancelAreaView.hidden = cancelMode;
            self.releaseToSendTuto.hidden = cancelMode || self.captionTextView.text.length != 0;
            self.captionTextView.hidden = cancelMode || self.captionTextView.text.length == 0;
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
                    // todo bt boolean not to send
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

- (void)handleLongPressGestureOnMetaDataView:(UILongPressGestureRecognizer *)gesture {
    float widthRatio = (float)[gesture locationInView:self.metadataView].x / self.metadataView.frame.size.width;
    [self.playingProgressView.layer removeAllAnimations];
    [self.friendVideoView.player seekToTime:CMTimeMakeWithSeconds(CMTimeGetSeconds(self.friendVideoView.player.itemDuration) * widthRatio, self.friendVideoView.player.itemDuration.timescale)];
    [self.playingProgressView setFrame:CGRectMake(0, 0, widthRatio * self.metadataView.frame.size.width, self.metadataView.frame.size.height)];
    if (gesture.state == UIGestureRecognizerStateBegan) {
        [self showMetaData:NO];
        [self.friendVideoView.player pause];
        [self.whiteNoisePlayer pause];
    } else if (gesture.state == UIGestureRecognizerStateChanged) {

    } else {
        [self.friendVideoView.player play];
        [self.whiteNoisePlayer play];
        [self animatePlayingProgressBar:CMTimeGetSeconds(self.friendVideoView.player.currentItem.duration) * (1 - widthRatio)];
    }
}

- (IBAction)replayButtonClicked:(id)sender {
    if (self.failedVideoPostArray.count > 0) {
        [self sendFailedVideo];
    } else {
        [self createCompositionAndPlayVideos:[self.videoPostArray subarrayWithRange:NSMakeRange(_videoIndex, self.videoPostArray.count - _videoIndex)]];
        [TrackingUtils trackReplayButtonClicked];
    }
}

- (IBAction)flipCameraButtonClicked:(id)sender {
    self.recorder.device = self.recorder.device == AVCaptureDevicePositionBack ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack;
    [GeneralUtils saveLastVideoSelfieModePref:(self.recorder.device == AVCaptureDevicePositionFront)];
}

- (IBAction)friendsButtonClicked:(id)sender {
    [self.captionTextView resignFirstResponder];
    [self performSegueWithIdentifier:@"Friends From Video" sender:nil];
}

- (IBAction)captionButtonClicked:(id)sender {
    [self.captionTextView becomeFirstResponder];
}

-(IBAction)backToCameraButtonClicked:(id)sender {
    [self returnToCameraMode];
}

- (void)handleTapOnVideo {
    if (![self isPlayingMode]) {
        return;
    }
    CMTime observedTime;
    for (NSValue *observedValue in self.videoPlayingObservedTimesArray) {
        if (observedValue == self.videoPlayingObservedTimesArray.lastObject) {
            [self returnToCameraMode];
        } else {
            [observedValue getValue:&observedTime];
            if (CMTIME_COMPARE_INLINE(self.friendVideoView.player.currentTime, <, observedTime)) {
                [self.friendVideoView.player seekToTime:observedTime];
                CGFloat videoDuration = CMTimeGetSeconds(self.friendVideoView.player.currentItem.duration);
                CGFloat currentTime = CMTimeGetSeconds(observedTime);
                [self.playingProgressView.layer removeAllAnimations];
                [self.playingProgressView setFrame:CGRectMake(0, 0, currentTime / videoDuration * self.metadataView.frame.size.width, self.metadataView.frame.size.height)];
                [self animatePlayingProgressBar:videoDuration - currentTime];
                return;
            }
        }
    }
}

// --------------------------------------------
#pragma mark - Playing
// --------------------------------------------
- (void)createCompositionAndPlayVideos:(NSArray *)videoArray {
    AVMutableComposition *composition = [AVMutableComposition new];
    self.videoPlayingObservedTimesArray = [VideoUtils fillComposition:composition withVideoPosts:videoArray];
    
    // Case where video not yet downloaded
    if (videoArray.count == 0 || !composition) return;
    if (composition.duration.value <= 0) {
        [self.replayButton setTitle:[NSString stringWithFormat:@"%@ (%lu%%)",NSLocalizedString(@"downloading_label", nil),(long)((VideoPost *)videoArray[0]).downloadProgress] forState:UIControlStateNormal];
        [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(setReplayButtonUI) userInfo:nil repeats:NO];
        return;
    }
    
    // Set item
    [self.friendVideoView.player setItemByAsset:composition];
    [self.friendVideoView.player seekToTime:kCMTimeZero];
    
    // Time observer
    if (self.compositionTimerObserverArray) {
        for (id observer in self.compositionTimerObserverArray) {
            [self.friendVideoView.player removeTimeObserver:observer];
        }
    }
    self.compositionTimerObserverArray = [NSMutableArray new];
    for (int ii = 0; ii < self.videoPlayingObservedTimesArray.count; ii++) {
        [self.compositionTimerObserverArray addObject:[self.friendVideoView.player addBoundaryTimeObserverForTimes:[NSArray arrayWithObject:self.videoPlayingObservedTimesArray[ii]] queue:dispatch_get_main_queue() usingBlock:^{
            [TrackingUtils trackVideoSeen];

            if (ii >= videoArray.count) return;
            
            // Update viewer ids and last video seen date
            VideoPost *videoSeen = (VideoPost *)videoArray[ii];
            [GeneralUtils saveLastVideoSeenDate:videoSeen.createdAt];
            if (videoSeen.user != [User currentUser]) {
                [videoSeen addUniqueObject:[User currentUser].objectId forKey:@"viewerIdsArray"];
            }
            
            // update metadata & last seen date
            if (ii < self.videoPlayingObservedTimesArray.count - 1 && videoArray.count > ii + 1) {
                [self setPlayingMetaDataForVideoPost:videoArray[ii + 1]];
            } else {
                [self returnToCameraMode];
            };
        }]];
    }
    
    // Play
    [self.friendVideoView.player play];
    [self setPlayingMode:YES];
    [self setPlayingMetaDataForVideoPost:videoArray[0]];
    [self.playingProgressView setFrame:CGRectMake(0, 0, 0, self.metadataView.frame.size.height)];
    [self animatePlayingProgressBar:CMTimeGetSeconds(composition.duration)];
}


// and then we implement the observation callback
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    AVPlayer *player = (AVPlayer *)object;
    if(object==self.previewView.player) {
        if(player.status==AVPlayerStatusFailed) {
            NSLog(@"player status failure");
        } else if(player.status==AVPlayerStatusReadyToPlay) {
            NSLog(@"ready to play");
            [self playPreview];
            [self.previewView.player removeObserver:self forKeyPath:@"status"];
        } else if(player.status==AVPlayerStatusUnknown) {
            NSLog(@"player status unknown");
        }
    }
}

- (void)setPlayingMetaDataForVideoPost:(VideoPost *)post {
    [self showMetaData:YES];
    self.nameLabel.text = self.contactDictionnary[post.user.username];
    self.timeLabel.text = [post.createdAt timeAgoSinceNow];
}

- (void)showMetaData:(BOOL)flag {
    self.nameLabel.hidden = !flag;
    self.timeLabel.hidden = !flag;
}

- (void)returnToCameraMode {
    [self setCameraMode];
    [ApiManager updateVideoPosts:self.videoPostArray];
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
        NSLog(@"too short");
    } else {
        AVAsset *asset = recordSession.assetRepresentingSegments;
        AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:asset
                                                                          presetName:AVAssetExportPresetMediumQuality];
        [GeneralUtils removeFile:recordSession.outputUrl];
        exporter.outputURL = recordSession.outputUrl;
        exporter.outputFileType = AVFileTypeMPEG4;
        exporter.shouldOptimizeForNetworkUse = YES;
        
        exporter.videoComposition = [self addCaptionToVideo:asset];

        // Export
        [exporter exportAsynchronouslyWithCompletionHandler: ^{
            if (exporter.error == nil) {
                VideoPost *post = [VideoPost createPostWithRessourceUrl:recordSession.outputUrl];
                if (successBlock) {
                    successBlock(post);
                }
            } else {
                _isExporting = NO;
                NSLog(@"Export failed: %@", exporter.error);
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
                [TrackingUtils trackVideoSent];
                if (![self isPlayingMode])
                    [self setReplayButtonUI];
            } failure:^(NSError *error) {
                self.isSendingCount --;
                [self.failedVideoPostArray addObject:post];
                [self setReplayButtonUI];
                [TrackingUtils trackVideoSendingFailure];
            }];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.captionTextView.text = @"";
        self.captionTextView.hidden = YES;
    });
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
    dispatch_async(dispatch_get_main_queue(), ^{
        // sending anim
        if (_isSendingCount !=0) {
            [self.sendingHud show:YES];
        } else {
            [self.sendingHud hide:YES];
        }
    });
}

// --------------------------------------------
#pragma mark - SCRecorderDelegate
// --------------------------------------------

- (void)recorder:(SCRecorder *)recorder didCompleteSession:(SCRecordSession *)recordSession {
    if (_isExporting) {
        return;
    }
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
    [self.previewView.player setItemByAsset:recordSession.assetRepresentingSegments];
    if (self.previewView.player.status == AVPlayerStatusReadyToPlay) {
        [self playPreview];
    } else {
        [self.previewView.player addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:NULL];
    }
}

- (void)playPreview {
    [self.previewView.player play];
    [self setPreviewMode];
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

- (BOOL)isPlayingMode {
    return !self.friendVideoView.hidden;
}

- (BOOL)isPreviewMode {
    return !self.previewView.hidden;
}

- (BOOL)isRecordingMode {
    return self.recorder.isRecording;
}

- (void)setPlayingMode:(BOOL)flag
{
    self.friendVideoView.hidden = !flag;
    if (flag) {
        [self.whiteNoisePlayer play];
        [self endPreviewMode];
    } else {
        [self.playingProgressView.layer removeAllAnimations];
        [self.whiteNoisePlayer pause];
        [self.friendVideoView.player pause];
        [self.friendVideoView.player seekToTime:kCMTimeZero];
    }
}

- (void)setCameraMode
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setPlayingMode:NO];
        [self endPreviewMode];
        self.recordingProgressContainer.hidden = YES;
        [self hideUIElementOnCamera:NO];
        [self setReplayButtonUI];
    });
}

- (void)setRecordingMode {
    [self setPlayingMode:NO];
    [self endPreviewMode];
    
    [self hideUIElementOnCamera:YES];
    
    // Show caption on camera
    self.captionTextView.hidden = (self.captionTextView.text.length == 0);
    
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
    [self.cameraView insertSubview:self.captionTextView belowSubview:self.replayButton];
    self.previewView.hidden = YES;
    [self.previewView.player pause];
}

- (void)setPreviewMode {
    [self setPlayingMode:NO];
    self.cancelConfirmView.hidden = YES;
    self.cancelAreaView.hidden = NO;
    self.previewView.hidden = NO;
    if (self.captionTextView.text != 0) {
        self.releaseToSendTuto.hidden = YES;
        [self.previewView insertSubview:self.captionTextView belowSubview:self.cancelConfirmView];
    } else {
        self.releaseToSendTuto.hidden = NO;
    }
}

- (void)setReplayButtonUI {
    if (self.failedVideoPostArray.count > 0) {
        // failed video state
        self.replayButton.backgroundColor = [ColorUtils transparentRed];
        NSString *title = self.failedVideoPostArray.count > 1 ? [NSString stringWithFormat:NSLocalizedString(@"videos_sending_failed", nil),self.failedVideoPostArray.count] : NSLocalizedString(@"video_sending_failed", nil);
        [self.replayButton setTitle:title forState:UIControlStateNormal];
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
            self.replayButton.backgroundColor = [ColorUtils black];
            buttonTitle = [NSString stringWithFormat:NSLocalizedString(@"replay_label", nil)];
        } else {
            _videoIndex = self.videoPostArray.count - kkk;
            self.replayButton.backgroundColor = [ColorUtils purple];
            buttonTitle = [NSString stringWithFormat:@"%d %@",kkk,kkk < 2 ? NSLocalizedString(@"new_video_label", nil) : NSLocalizedString(@"new_videos_label", nil)];
        }
        [self.replayButton setTitle:buttonTitle forState:UIControlStateNormal];
        self.replayButton.hidden = NO;
    }
}

- (void)animatePlayingProgressBar:(float)duration {
    [UIView animateWithDuration:duration
                          delay:0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         [self.playingProgressView setFrame:CGRectMake(0, 0, self.metadataView.frame.size.width, self.metadataView.frame.size.height)];
                     } completion:nil];
}


// --------------------------------------------
#pragma mark - Friends VC Delegate
// --------------------------------------------

- (void)hideUIElementOnCamera:(BOOL)flag {
    if (flag) {
        self.replayButton.hidden = YES;
        self.recordTutoLabel.hidden = YES;
        self.captionTextView.hidden = YES;
    } else {
        [self setReplayButtonUI];
        self.captionTextView.hidden = (self.captionTextView.text.length == 0);
        self.recordTutoLabel.hidden = !(self.captionTextView.text.length == 0);
    }
    self.cameraSwitchButton.hidden = flag;
    self.friendListButton.hidden = flag;
    self.captionButton.hidden = flag;
}

- (void)playOneFriendVideos:(NSArray *)videoArray {
    [self createCompositionAndPlayVideos:videoArray];
}

- (void)removeVideoFromVideosArray:(VideoPost *)video {
    [self.videoPostArray removeObject:video];
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
    if ((touch.view == self.replayButton || touch.view == self.cameraSwitchButton) || touch.view == self.friendListButton || touch.view == self.captionButton || touch.view == self.captionTextView) {
        return NO;
    }
    return YES;
}

// --------------------------------------------
#pragma mark - Caption TextView delegate
// --------------------------------------------
- (void)textViewDidBeginEditing:(UITextView *)textView
{
    self.recordTutoLabel.hidden = YES;
    self.captionTextView.hidden = NO;
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    if (self.captionTextView.text.length == 0) {
        self.captionTextView.hidden = YES;
        self.recordTutoLabel.hidden = NO;
        self.captionTextView.transform = CGAffineTransformIdentity;
        self.captionTextView.center = self.view.center;
    }
}
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        [self.captionTextView resignFirstResponder];
        return NO;
    }
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
    CGSize size = [self.captionTextView sizeThatFits:CGSizeMake(self.view.frame.size.width, 1000)];
    CGRect previousFrame = self.captionTextView.frame;
    self.captionTextView.frame = CGRectMake(previousFrame.origin.x + (previousFrame.size.width - size.width) / 2, previousFrame.origin.y + previousFrame.size.height - size.height, size.width, size.height);
}


// ----------------------------------------------------------
#pragma mark Keyboard
// ----------------------------------------------------------
// Caption editing UI
- (void)keyboardWillShow:(NSNotification *)notification {
    // Save current frame
    self.captionTransform = self.captionTextView.transform;
    self.captionCenter = self.captionTextView.center;
    
    // Editing UI
    NSDictionary *userInfo = [notification userInfo];
    NSValue *aValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardRect = [aValue CGRectValue];
    self.captionTextView.transform = CGAffineTransformIdentity;
    CGFloat width = self.view.frame.size.width;
    CGSize size = [self.captionTextView sizeThatFits:CGSizeMake(width, 1000)];
    self.captionTextView.frame = CGRectMake(self.view.frame.size.width/2 - size.width/2, keyboardRect.origin.y - size.height, size.width, size.height);
}

// Caption transformed UI
- (void)keyboardWillHide:(NSNotification *)notification {
    self.captionTextView.transform = self.captionTransform;
    self.captionTextView.center = self.captionCenter;
}

// Close keyboard when caption moved
- (void)gestureOnCaptionDetected {
    if ([self.captionTextView isFirstResponder]) {
        self.captionTransform = self.captionTextView.transform;
        self.captionCenter = self.captionTextView.center;
        [self.captionTextView resignFirstResponder];
    }
}

//
- (AVMutableVideoComposition *)addCaptionToVideo:(AVAsset *)asset {
    AVMutableVideoCompositionInstruction *mainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, asset.duration);
    AVAssetTrack *videoAssetTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    AVMutableVideoCompositionLayerInstruction *videolayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoAssetTrack];
    
    UIImageOrientation videoAssetOrientation_  = UIImageOrientationUp;
    BOOL isVideoAssetPortrait_  = NO;
    CGAffineTransform videoTransform = videoAssetTrack.preferredTransform;
    if (videoTransform.a == 0 && videoTransform.b == 1.0 && videoTransform.c == -1.0 && videoTransform.d == 0) {
        videoAssetOrientation_ = UIImageOrientationRight;
        isVideoAssetPortrait_ = YES;
    }
    if (videoTransform.a == 0 && videoTransform.b == -1.0 && videoTransform.c == 1.0 && videoTransform.d == 0) {
        videoAssetOrientation_ =  UIImageOrientationLeft;
        isVideoAssetPortrait_ = YES;
    }
    if (videoTransform.a == 1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == 1.0) {
        videoAssetOrientation_ =  UIImageOrientationUp;
    }
    if (videoTransform.a == -1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == -1.0) {
        videoAssetOrientation_ = UIImageOrientationDown;
    }
    
    // todo bt mirror front video
//    BOOL isFront = self.recorder.device == AVCaptureDevicePositionFront;
//    if (isFront) {
//        CGAffineTransform t = CGAffineTransformMakeScale(-1.0f, 1.0f);
//        t = CGAffineTransformTranslate(t, -videoAssetTrack.naturalSize.width, 0);
//        t = CGAffineTransformRotate(t, (DEGREES_TO_RADIANS(90.0)));
//        t = CGAffineTransformTranslate(t, 0.0f, -videoAssetTrack.naturalSize.width);
//        [videolayerInstruction setTransform:t atTime:kCMTimeZero];
//    }
    //
    
    mainInstruction.layerInstructions = [NSArray arrayWithObjects:videolayerInstruction,nil];
    AVMutableVideoComposition *mainCompositionInst = [AVMutableVideoComposition videoComposition];
    CGSize naturalSize;
    if(isVideoAssetPortrait_){
        naturalSize = CGSizeMake(videoAssetTrack.naturalSize.height, videoAssetTrack.naturalSize.width);
    } else {
        naturalSize = videoAssetTrack.naturalSize;
    }
    float renderWidth, renderHeight;
    renderWidth = naturalSize.width;
    renderHeight = naturalSize.height;
    mainCompositionInst.renderSize = CGSizeMake(renderWidth, renderHeight);
    
    [videolayerInstruction setTransform:videoAssetTrack.preferredTransform atTime:kCMTimeZero];
    [videolayerInstruction setOpacity:0.0 atTime:asset.duration];
    mainInstruction.layerInstructions = [NSArray arrayWithObjects:videolayerInstruction,nil];
    mainCompositionInst.renderSize = naturalSize;
    mainCompositionInst.instructions = [NSArray arrayWithObject:mainInstruction];
    mainCompositionInst.frameDuration = CMTimeMake(1, 30);
    
    [self applyVideoEffectsToComposition:mainCompositionInst size:naturalSize];
    return mainCompositionInst;
}

// Screenschot caption
- (UIImage *)getImageFromCaption
{
    UIView *containerView = [[UIView alloc] initWithFrame:self.view.frame];
    containerView.backgroundColor = [UIColor clearColor];
    UIView *superView = self.captionTextView.superview;
    NSInteger index = [superView.subviews indexOfObject:self.captionTextView];
    [superView insertSubview:containerView belowSubview:self.captionTextView];
    [containerView addSubview:self.captionTextView];
    
    UIGraphicsBeginImageContextWithOptions(containerView.bounds.size, NO, 0.0);
    [containerView.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage * img = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    [superView insertSubview:self.captionTextView atIndex:index];
    [containerView removeFromSuperview];
    return img;
}

// Add caption image to video composition
- (void)applyVideoEffectsToComposition:(AVMutableVideoComposition *)composition size:(CGSize)size
{
    // 1 - set up the overlay
    CALayer *overlayLayer = [CALayer layer];
    UIImage *overlayImage =[self getImageFromCaption];
    
    [overlayLayer setContents:(id)[overlayImage CGImage]];
    overlayLayer.frame = CGRectMake(0, 0, size.width, size.height);
    [overlayLayer setMasksToBounds:YES];
    
    // 2 - set up the parent layer
    CALayer *parentLayer = [CALayer layer];
    CALayer *videoLayer = [CALayer layer];
    parentLayer.frame = CGRectMake(0, 0, size.width, size.height);
    videoLayer.frame = CGRectMake(0, 0, size.width, size.height);
    [parentLayer addSublayer:videoLayer];
    [parentLayer addSublayer:overlayLayer];
    
    // 3 - apply magic
    composition.animationTool = [AVVideoCompositionCoreAnimationTool
                                 videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
}

// --------------------------------------------
#pragma mark - Saving / Sharing
// --------------------------------------------
//- (void)saveVideoToCameraRoll {
//    //
//    [MBProgressHUD showHUDAddedTo:self.view animated:NO];
//    
//    // Recompute with all videos
//    _videoIndex = 0;
//    [self createCompositionFromVideoPosts];
//
//    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:self.friendVideoComposition presetName:AVAssetExportPresetHighestQuality];
//    NSString *exportVideoPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/FinishedVideo.m4v"];
//    NSURL *exportURL = [NSURL fileURLWithPath:exportVideoPath];
//    [[NSFileManager defaultManager] removeItemAtPath:exportVideoPath error:nil];
//    exportSession.outputURL = exportURL;
//    exportSession.outputFileType = AVFileTypeMPEG4;
//    [exportSession exportAsynchronouslyWithCompletionHandler:^{
//        switch (exportSession.status) {
//            case AVAssetExportSessionStatusCompleted: {
//                ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
//                [library writeVideoAtPathToSavedPhotosAlbum:exportURL
//                                            completionBlock:^(NSURL *assetURL, NSError *error) {
//                                                NSLog (@"SAVE SUCCESS");
//                                                dispatch_async(dispatch_get_main_queue(), ^{
//                                                    [MBProgressHUD hideAllHUDsForView:self.view animated:NO];
//                                                });
//                                            }];
//                NSLog (@"SUCCESS");
//                break;
//            }
//            default: {
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    [MBProgressHUD hideAllHUDsForView:self.view animated:NO];
//                });
//                NSLog (@"FAIL");
//            }
//        };
//    }]; 
//
//}

@end
