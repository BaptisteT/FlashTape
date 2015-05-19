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

#import "AddressbookUtils.h"
#import "ConstantUtils.h"
#import "ColorUtils.h"
#import "GeneralUtils.h"
#import "NSDate+DateTools.h"
#import "TrackingUtils.h"

@interface VideoViewController ()

// Contacts
@property (nonatomic) ABAddressBookRef addressBook;
@property (strong, nonatomic) NSDictionary *contactDictionnary;

// Playing
@property (strong, nonatomic) NSMutableArray *videoPostArray;
@property (weak, nonatomic) IBOutlet SCVideoPlayerView *friendVideoView;
@property (strong, nonatomic) AVMutableComposition *friendVideoComposition;
@property (strong, nonatomic) NSMutableArray *observedTimesArray;
@property (strong, nonatomic) NSMutableArray *compositionTimerObserverArray;

@property (weak, nonatomic) IBOutlet UIButton *replayButton;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIView *metadataView;
@property (strong, nonatomic) UIView *playingProgressView;
@property (strong, nonatomic) UILongPressGestureRecognizer *playingProgressViewLongPressGesture;
@property (strong, nonatomic) AVAudioPlayer *whiteNoisePlayer;

// Recording
@property (weak, nonatomic) IBOutlet UIView *recordingProgressContainer;
@property (strong, nonatomic) SCRecorder *recorder;
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
    
    _videoIndex = 0;
    _isExporting = NO;
    _longPressRunning = NO;
    self.isSendingCount = 0;
    
    // Init gesture
    self.longPressGestureRecogniser = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGesture:)];
    self.longPressGestureRecogniser.delegate = self;
    [self.view addGestureRecognizer:self.longPressGestureRecogniser];
    
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
    _recorder.device = AVCaptureDevicePositionFront;
    _recorder.maxRecordDuration = CMTimeMakeWithSeconds(kRecordSessionMaxDuration + kVideoEndCutDuration, 600);
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
    self.friendVideoView.player.loopEnabled = NO;
    self.friendVideoView.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    // White noise player
    NSString *soundPath = [[NSBundle mainBundle] pathForResource:@"whiteNoise" ofType:@".wav"];
    NSURL *soundURL = [NSURL fileURLWithPath:soundPath];
    self.whiteNoisePlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:soundURL error:nil];
    self.whiteNoisePlayer.volume = 0.001;
    self.whiteNoisePlayer.numberOfLoops = -1;
    
    // Metadata
    [self.view bringSubviewToFront:self.metadataView];
    self.playingProgressView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, self.metadataView.frame.size.height)];
    self.playingProgressView.backgroundColor = [ColorUtils transparentOrange];
    self.playingProgressView.userInteractionEnabled = NO;
    [self.metadataView insertSubview:self.playingProgressView atIndex:0];
    self.playingProgressViewLongPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGestureOnMetaDataView:)];
    self.playingProgressViewLongPressGesture.minimumPressDuration = 0;
    [self.metadataView addGestureRecognizer:self.playingProgressViewLongPressGesture];
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
    // Add current user to contacts array
    NSMutableArray *contactArray = [NSMutableArray new];//[NSMutableArray arrayWithArray:[self.contactDictionnary allKeys]];
    [contactArray addObject:[User currentUser].username];
    
    // Get video
    [ApiManager getVideoFromContacts:contactArray
                             success:^(NSArray *posts) {
                                 self.videoPostArray = [NSMutableArray arrayWithArray:posts];
                                 [self setReplayButtonUI];
                             } failure:^(NSError *error) {
                                 // todo BT handle error
                                 // display already downloaded video ? fron last 24h
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
        
        [UIView animateWithDuration:CMTimeGetSeconds(self.friendVideoComposition.duration) * (1 - widthRatio)
                              delay:0
                            options:UIViewAnimationOptionCurveLinear
                         animations:^{
                             [self.playingProgressView setFrame:CGRectMake(0, 0, self.metadataView.frame.size.width, self.metadataView.frame.size.height)];
                         } completion:nil];
    }
}

- (IBAction)replayButtonClicked:(id)sender {
    if (self.failedVideoPostArray.count > 0) {
        [self sendFailedVideo];
    } else {
        [self prepareToPlayVideos];
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
- (void)prepareToPlayVideos {
    [self createCompositionFromVideoPosts];
    
    // Case where video not yet downloaded
    if (self.videoPostArray.count == 0 || !self.friendVideoComposition) return;
    if (self.friendVideoComposition.duration.value <= 0) {
        [self.replayButton setTitle:[NSString stringWithFormat:@"%@ (%lu%%)",NSLocalizedString(@"downloading_label", nil),(long)((VideoPost *)self.videoPostArray[_videoIndex]).downloadProgress] forState:UIControlStateNormal];
        [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(setReplayButtonUI) userInfo:nil repeats:NO];
        return;
    }
    
    // Set item
    [self.friendVideoView.player setItemByAsset:self.friendVideoComposition];
    [self.friendVideoView.player seekToTime:kCMTimeZero];
    
    // Time observer
    if (self.compositionTimerObserverArray) {
        for (id observer in self.compositionTimerObserverArray) {
            [self.friendVideoView.player removeTimeObserver:observer];
        }
    }
    self.compositionTimerObserverArray = [NSMutableArray new];
    for (int ii = 0; ii < self.observedTimesArray.count; ii++) {
        [self.compositionTimerObserverArray addObject:[self.friendVideoView.player addBoundaryTimeObserverForTimes:[NSArray arrayWithObject:self.observedTimesArray[ii]] queue:dispatch_get_main_queue() usingBlock:^{
            [TrackingUtils trackVideoSeen];

            if (_videoIndex + ii >= self.videoPostArray.count) return;
            
            // Save item date
            [GeneralUtils saveLastVideoSeenDate:((VideoPost *)self.videoPostArray[_videoIndex + ii]).createdAt];
       
            // update metadata & last seen date
            if (ii < self.observedTimesArray.count - 1 && self.videoPostArray.count > _videoIndex + ii + 1) {
                [self setPlayingMetaDataForVideoPost:self.videoPostArray[_videoIndex + ii + 1]];
            } else {
                [self setCameraMode];
            }
        }]];
    }
    
    if (self.friendVideoView.player.status == AVPlayerStatusReadyToPlay) {
        [self playVideos];
    } else {
        [self.friendVideoView.player addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:NULL];
    }
}

- (void)playVideos {
    [self.friendVideoView.player play];
    // UI
    [self setPlayingMode:YES];
    [self setPlayingMetaDataForVideoPost:self.videoPostArray[_videoIndex]];
    [self.playingProgressView setFrame:CGRectMake(0, 0, 0, self.metadataView.frame.size.height)];
    [UIView animateWithDuration:CMTimeGetSeconds(self.friendVideoComposition.duration)
                          delay:0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         [self.playingProgressView setFrame:CGRectMake(0, 0, self.metadataView.frame.size.width, self.metadataView.frame.size.height)];
                     } completion:nil];
}

// and then we implement the observation callback
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    AVPlayer *player = (AVPlayer *)object;
    if(object==self.friendVideoView.player) {
        if(player.status==AVPlayerStatusFailed) {
            NSLog(@"player status failure");
        } else if(player.status==AVPlayerStatusReadyToPlay) {
            NSLog(@"ready to play");
            [self playVideos];
            [self.friendVideoView.player removeObserver:self forKeyPath:@"status"];
        } else if(player.status==AVPlayerStatusUnknown) {
            NSLog(@"player status unknown");
        }
    } else if(object==self.previewView.player) {
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

- (void)createCompositionFromVideoPosts
{
    self.friendVideoComposition = [AVMutableComposition new];
    self.observedTimesArray = [NSMutableArray new];
    for (NSInteger kk = _videoIndex; kk < self.videoPostArray.count; kk++) {
        VideoPost *post = self.videoPostArray[kk];
        if (post.localUrl) {
            [self insertVideoAtTheEndOfTheComposition:post];
        } else {
            return;
        }
    }
}

- (void)insertVideoAtTheEndOfTheComposition:(VideoPost *)videoPost {
    if (videoPost.localUrl) {
        AVURLAsset* sourceAsset = [AVURLAsset assetWithURL:videoPost.videoLocalURL];
        CMTimeRange assetTimeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(CMTimeGetSeconds(sourceAsset.duration) - kVideoEndCutDuration, sourceAsset.duration.timescale));
        NSError *editError;
        [self.friendVideoComposition insertTimeRange:assetTimeRange
                                             ofAsset:sourceAsset
                                              atTime:[self friendCompositionEndCMTime]
                                               error:&editError];
        if (editError) {
            // todo BT handle error
            NSLog(@"%@",editError.description);
        }
        [self.observedTimesArray addObject:[NSValue valueWithCMTime:[self friendCompositionEndCMTime]]];
    }
}

- (CMTime)friendCompositionEndCMTime {
    return CMTimeMakeWithSeconds(CMTimeGetSeconds(self.friendVideoComposition.duration),self.friendVideoComposition.duration.timescale);
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
        ////////////
        // 2 - Create AVMutableComposition object. This object will hold your AVMutableCompositionTrack instances.
        AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];

//        // 3 - Video track
        AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                            preferredTrackID:kCMPersistentTrackID_Invalid];
        [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero,recordSession.assetRepresentingSegments.duration)
                            ofTrack:[[recordSession.assetRepresentingSegments tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0]
                             atTime:kCMTimeZero error:nil];
        
        // 3.1 - Create AVMutableVideoCompositionInstruction
        AVMutableVideoCompositionInstruction *mainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, recordSession.assetRepresentingSegments.duration);
        
        // 3.2 - Create an AVMutableVideoCompositionLayerInstruction for the video track and fix the orientation.
        AVMutableVideoCompositionLayerInstruction *videolayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
        AVAssetTrack *videoAssetTrack = [[recordSession.assetRepresentingSegments tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
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
        [videolayerInstruction setTransform:videoAssetTrack.preferredTransform atTime:kCMTimeZero];
        [videolayerInstruction setOpacity:0.0 atTime:recordSession.assetRepresentingSegments.duration];
        
        // 3.3 - Add instructions
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
        mainCompositionInst.instructions = [NSArray arrayWithObject:mainInstruction];
        mainCompositionInst.frameDuration = CMTimeMake(1, 30);
        
        [self applyVideoEffectsToComposition:mainCompositionInst size:naturalSize];
        
        ///////////
        AVAsset *asset = recordSession.assetRepresentingSegments;
        AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:asset
                                                                          presetName:AVAssetExportPresetMediumQuality];
        [GeneralUtils removeFile:recordSession.outputUrl];
        exporter.outputURL = recordSession.outputUrl;
        exporter.outputFileType = AVFileTypeMPEG4;
        exporter.shouldOptimizeForNetworkUse = YES;
        exporter.videoComposition = mainCompositionInst;

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

- (void)applyVideoEffectsToComposition:(AVMutableVideoComposition *)composition size:(CGSize)size
{
    // 1 - Set up the text layer
    CATextLayer *subtitle1Text = [[CATextLayer alloc] init];
    [subtitle1Text setFont:@"Helvetica-Bold"];
    [subtitle1Text setFontSize:36];
    [subtitle1Text setFrame:CGRectMake(0, 0, size.width, 200)];
    [subtitle1Text setString:@"yo yo caption"];
    [subtitle1Text setAlignmentMode:kCAAlignmentCenter];
    [subtitle1Text setForegroundColor:[[UIColor whiteColor] CGColor]];
    
    // 2 - The usual overlay
    CALayer *overlayLayer = [CALayer layer];
    [overlayLayer addSublayer:subtitle1Text];
    overlayLayer.frame = CGRectMake(0, 0, size.width, size.height);
    [overlayLayer setMasksToBounds:YES];

    CALayer *parentLayer = [CALayer layer];
    CALayer *videoLayer = [CALayer layer];
    parentLayer.frame = CGRectMake(0, 0, size.width, size.height);
    videoLayer.frame = CGRectMake(0, 0, size.width, size.height);
    [parentLayer addSublayer:videoLayer];
    [parentLayer addSublayer:overlayLayer];
    
    composition.animationTool = [AVVideoCompositionCoreAnimationTool
                                 videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
    
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
    // sending anim
//    if (_isSendingCount != 0 && isSendingCount == 0) {
//        [MBProgressHUD hideAllHUDsForView:self.sendingLoaderView animated:YES];
//    } else if (_isSendingCount == 0 && isSendingCount != 0) {
//        MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:self.sendingLoaderView];
//        hud.color = [UIColor clearColor];
//        hud.activityIndicatorColor = [ColorUtils orange];
//        [self.sendingLoaderView addSubview:hud];
//        [hud show:YES];
//    }
    _isSendingCount = isSendingCount;
}
// --------------------------------------------
#pragma mark - SCRecorderDelegate
// --------------------------------------------

- (void)recorder:(SCRecorder *)recorder didCompleteSession:(SCRecordSession *)recordSession {
    if (_isExporting) {
        return;
    }
    [self.previewView.player setItemByAsset:recordSession.assetRepresentingSegments];
    if (self.previewView.player.status == AVPlayerStatusReadyToPlay) {
        [self playPreview];
    } else {
        [self.previewView.player addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:NULL];
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
        self.longPressGestureRecogniser.minimumPressDuration = 0.5;
    } else {
        [self.whiteNoisePlayer pause];
        [self.friendVideoView.player pause];
        [self.friendVideoView.player seekToTime:kCMTimeZero];
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
