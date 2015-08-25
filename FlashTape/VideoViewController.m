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
#import "ABContact.h"
#import "DatastoreUtils.h"
#import "Follow.h"
#import "VideoPost.h"

#import "ABAccessViewController.h"
#import "MoodTextView.h"
#import "EmojiViewController.h"
#import "FriendsViewController.h"
#import "InviteContactViewController.h"
#import "VideoViewController.h"

#import "AddressbookUtils.h"
#import "ConstantUtils.h"
#import "ColorUtils.h"
#import "DesignUtils.h"
#import "GeneralUtils.h"
#import "KeyboardUtils.h"
#import "InviteUtils.h"
#import "NotifUtils.h"
#import "NSDate+DateTools.h"
#import "TrackingUtils.h"
#import "VideoUtils.h"

// Degrees to radians
#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)

@interface VideoViewController ()

// Contacts
@property (nonatomic) ABAddressBookRef addressBook;
@property (strong, nonatomic) NSMutableOrderedSet *followingRelations;

// Playing
@property (strong, nonatomic) NSArray *tutoVideoArray;
@property (strong, nonatomic) NSMutableArray *allVideosArray;
@property (strong, nonatomic) NSArray *videosToPlayArray;
@property (weak, nonatomic) IBOutlet SCVideoPlayerView *friendVideoView;
@property (strong, nonatomic) NSMutableArray *videoPlayingObservedTimesArray;
@property (strong, nonatomic) NSMutableArray *compositionTimerObserverArray;
@property (weak, nonatomic) IBOutlet UIButton *replayButton;
@property (strong, nonatomic) NSTimer *downloadingStateTimer;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UIButton *nameButton;
@property (weak, nonatomic) IBOutlet UIView *metadataView;
@property (weak, nonatomic) IBOutlet UILabel *slideHereTutoLabel;
@property (strong, nonatomic) UIView *playingProgressView;
@property (strong, nonatomic) UILongPressGestureRecognizer *playingProgressViewLongPressGesture;
@property (strong, nonatomic) AVAudioPlayer *whiteNoisePlayer;
@property (strong, nonatomic) UITapGestureRecognizer *videoTapGestureRecogniser;
@property (strong, nonatomic) NSArray *metadataColorArray;

// Recording
@property (strong, nonatomic) NSTimer *recordingMaxDurationTimer;
@property (weak, nonatomic) IBOutlet UIView *recordingProgressContainer;
@property (strong, nonatomic) SCRecorder *recorder;
//@property (strong, nonatomic) UILongPressGestureRecognizer *longPressGestureRecogniser;
@property (weak, nonatomic) IBOutlet UIView *cameraView;
@property (strong, nonatomic) UIView *recordingProgressBar;
@property (weak, nonatomic) IBOutlet UICustomLineLabel *recordTutoLabel;
@property (weak, nonatomic) IBOutlet UIButton *cameraSwitchButton;
@property (weak, nonatomic) IBOutlet UIButton *friendListButton;
@property (strong, nonatomic) SCFilter *filter;

// Mood
@property (weak, nonatomic) IBOutlet UIView *moodsContainerView;
@property (strong, nonatomic) MoodTextView *inProgressMoodTextView;
@property (weak, nonatomic) IBOutlet UIButton *moodButton;
@property (strong, nonatomic) EmojiViewController *emojiController;
@property (weak, nonatomic) IBOutlet UIView *emojiView;
@property (weak, nonatomic) IBOutlet UIView *moodCreationContainerView;
@property (weak, nonatomic) IBOutlet UIView *moodButtonContainerView;
@property (weak, nonatomic) IBOutlet UIButton *emojiButton;
@property (weak, nonatomic) IBOutlet UIButton *captionButton;

// Preview Playing
@property (weak, nonatomic) IBOutlet SCVideoPlayerView *previewView;
@property (weak, nonatomic) IBOutlet UICustomLineLabel *tapToSendTuto;
@property (weak, nonatomic) IBOutlet UIView *cancelAreaView;
@property (weak, nonatomic) IBOutlet UILabel *cancelTutoLabel;
//@property (weak, nonatomic) IBOutlet UIView *cancelConfirmView;
//@property (weak, nonatomic) IBOutlet UICustomLineLabel *cancelConfirmTutoLabel;
@property (weak, nonatomic) IBOutlet UIImageView *moodPreviewImageView;

// Sending
@property (strong, nonatomic) VideoPost *postToSend; // preview post
@property (strong, nonatomic) NSMutableArray *failedVideoPostArray;
@property (nonatomic) NSInteger isSendingCount;
@property (nonatomic) NSInteger cumulatedProgress;
@property (weak, nonatomic) IBOutlet UIView *sendingBarContainerView;
@property (strong, nonatomic) UIView *sendingBarView;

// Messages
@property (nonatomic) NSInteger messageCount;
@property (nonatomic) NSInteger unreadVideoCount;

// Invite
@property (nonatomic) NSMutableArray *potentialContactsToInvite;

// Tuto
@property (weak, nonatomic) IBOutlet UILabel *replayTutoLabel;
@property (weak, nonatomic) IBOutlet UIImageView *replayTutoArrow;

// Black splash
@property (strong, nonatomic) UIView *cameraBlackOverlay;

@end

@implementation VideoViewController {
    BOOL _isExporting;
//    BOOL _longPressRunning;
    BOOL _recordingRunning;
//    BOOL _cancelRecording;
    int _metadataColorIndex;
    NSDate *_longPressStartDate;
    BOOL _createTutoAdminMessages;
}

// --------------------------------------------
#pragma mark - Life Cycle
// --------------------------------------------

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Logic
    _createTutoAdminMessages = NO;
    _isExporting = NO;
//    _longPressRunning = NO;
    _recordingRunning = NO;
//    _cancelRecording = NO;
    _metadataColorIndex = 0;
    self.isSendingCount = 0;
    self.unreadVideoCount = 0;
    self.friendVideoView.hidden = YES;
    self.potentialContactsToInvite = nil;
    self.allVideosArray = [NSMutableArray new]; 
    
    self.metadataColorArray = [NSArray arrayWithObjects:[ColorUtils pink], [ColorUtils purple], [ColorUtils blue], [ColorUtils green], [ColorUtils orange], nil];
    
    // Tuto
    self.replayTutoLabel.numberOfLines = 0;
    self.replayTutoArrow.hidden = YES;
    self.replayTutoLabel.hidden = YES;
    
    // Audio session
    AVAudioSession* audioSession = [AVAudioSession sharedInstance];
    BOOL success; NSError* error;
    success = [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord
                            withOptions:AVAudioSessionCategoryOptionMixWithOthers | AVAudioSessionCategoryOptionDefaultToSpeaker
                                  error:&error];
    if (!success)
        NSLog(@"AVAudioSession error setting category:%@",error);
    [audioSession setActive:YES error:nil];
    
    // Sending
    self.cumulatedProgress = 0;
    self.sendingBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, self.sendingBarContainerView.frame.size.height)];
    self.sendingBarView.backgroundColor = [UIColor whiteColor];
    [self.sendingBarContainerView addSubview:self.sendingBarView];
    self.sendingBarContainerView.hidden = YES;
    
    // Recording gesture
    UITapGestureRecognizer *recordingTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleRecordingTapGesture:)];
//    self.longPressGestureRecogniser = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGesture:)];
//    self.longPressGestureRecogniser.delegate = self;
//    self.longPressGestureRecogniser.minimumPressDuration = 0;
//    [self.cameraView addGestureRecognizer:self.longPressGestureRecogniser];
    [self.cameraView addGestureRecognizer:recordingTapGesture];
    
    // Mood
    self.moodCreationContainerView.hidden = YES;
    UITapGestureRecognizer *moodTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideMoodView)];
    [self.moodCreationContainerView addGestureRecognizer:moodTap];
    [self.emojiButton setTitle:NSLocalizedString(@"close_button", nil) forState:UIControlStateNormal];
    
    // Create the recorder
    self.recorder = [SCRecorder recorder];
    _recorder.delegate = self;
    _recorder.device = [User currentUser].score == kUserInitialScore ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack;
     _recorder.autoSetVideoOrientation = NO;
    _recorder.keepMirroringOnWrite = YES;
    SCRecordSession *session = [SCRecordSession recordSession];
    session.fileType = AVFileTypeMPEG4;
    _recorder.session = session;
    
    // Preset
    _recorder.captureSessionPreset = [SCRecorderTools bestCaptureSessionPresetCompatibleWithAllDevices];
    _recorder.audioConfiguration.preset = SCPresetMediumQuality;
    _recorder.videoConfiguration.preset = SCPresetHighestQuality;
    
    // Start running the flow of buffers
    if (![self.recorder startRunning]) {
        NSLog(@"Something wrong there: %@", self.recorder.error);
    }
    
    // Recording progress bar
    self.recordingProgressBar = [[UIView alloc] init];
    self.recordingProgressBar.backgroundColor = [UIColor colorWithRed:0 green:1 blue:0 alpha:0.1];
    [self.recordingProgressContainer addSubview:self.recordingProgressBar];
    self.recordingProgressContainer.hidden = YES;
    
    // Filter
    self.filter = [SCFilter filterWithCIFilterName:@"CIColorCube"];
    [self.filter setParameterValue:@64 forKey:@"inputCubeDimension"];
    [self.filter setParameterValue:UIImageJPEGRepresentation([UIImage imageNamed:@"green"],1) forKey:@"inputCubeData"];
    if (!IS_IPHONE_4_OR_LESS) {
        self.recorder.videoConfiguration.filter = self.filter;
    }
    
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
    [self.nameButton setTitle:@"" forState:UIControlStateNormal];
    self.timeLabel.text = @"";
    self.slideHereTutoLabel.text = NSLocalizedString(@"slide_here_label", nil);
    self.slideHereTutoLabel.hidden = YES;
    
     // Labels
//    if ([User currentUser].score >= kMaxScoreBeforeHidingImportantTutos) {
//        [self.recordTutoLabel removeFromSuperview];
//    }
    self.recordTutoLabel.text = NSLocalizedString(@"tap_to_record_label", nil);
    self.recordTutoLabel.lineType = LineTypeDown;
    self.recordTutoLabel.lineHeight = 4.0f;
    self.replayButton.hidden = YES;
    self.messageCount = 0;
    
    // Preview
    self.tapToSendTuto.text = NSLocalizedString(@"tap_to_send", nil);
    self.tapToSendTuto.lineType = LineTypeDown;
    self.tapToSendTuto.lineHeight = 4.0f;
    self.cancelTutoLabel.text = NSLocalizedString(@"tap_here_to_cancel", nil);
    self.previewView.player.loopEnabled = YES;
    self.previewView.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    self.previewView.hidden = YES;
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOnPreview:)];
    [self.previewView addGestureRecognizer:tapGesture];
    
    // Retrieve friends from local datastore
    _followingRelations = [NSMutableOrderedSet new];
    [self retrieveFollowingLocallyAndVideosRemotely];
    [ApiManager getRelationshipsRemotelyAndExecuteSuccess:^{
        [self retrieveFollowingLocallyAndVideosRemotely];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"retrieve_message_locally"
                                                            object:nil
                                                          userInfo:nil];
    } failure:nil];
    
    // Friend array
    self.failedVideoPostArray = [NSMutableArray new];
    [DatastoreUtils getUnsendVideosSuccess:^(NSArray *videos) {
        [self.failedVideoPostArray addObjectsFromArray:videos];
    } failure:nil];
    
    // Start with camera
    [self setCameraMode];
    
    // Load address book, friends & video (if the result is different from cashing)
    self.addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
        [self parseContactsAndFindFriends];
    } else if (!self.isSignup) {
        // show screen permission
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
        ABAccessViewController *abAccessVC = [storyboard instantiateViewControllerWithIdentifier:@"ABAccessVC"];
        abAccessVC.initialViewController = self;
        [self presentViewController:abAccessVC animated:NO completion:nil];
    }

    // Retrieve unread messages
    [self retrieveUnreadMessages];
    
    // tuto video
    if (self.isSignup) {
        [VideoPost createTutoVideoAndExecuteSuccess:^(NSArray *videoArray) {
            self.tutoVideoArray = videoArray;
            NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, videoArray.count)];
            [self.allVideosArray insertObjects:videoArray atIndexes:indexSet];
            [self setReplayButtonUI];
            _createTutoAdminMessages = YES;
            
            // show replay tuto
            self.replayTutoLabel.text = NSLocalizedString(@"new_flashes_tuto_label", nil);
            [self performSelector:@selector(startReplayTutoAnim) withObject:nil afterDelay:1];
        } failureBlock:nil];
    }
    
    // Callback
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(willBecomeActiveCallback)
                                                 name: UIApplicationWillEnterForegroundNotification
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(didBecomeActiveCallback)
                                                 name: UIApplicationDidBecomeActiveNotification
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
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(retrieveFollowingLocallyAndVideosRemotely)
                                                 name:@"retrieve_following"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(retrieveVideoRemotely)
                                                 name:@"retrieve_video"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(retrieveUnreadMessages)
                                                 name:@"retrieve_message"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(navigateToFriends)
                                                 name:@"new_message_clicked"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(resetNotifCount)
                                                 name:@"reset_notif_count"
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Disable iOS 7 back gesture
    [self.navigationController.navigationBar setHidden:YES];
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    self.navigationController.interactivePopGestureRecognizer.delegate = self;
    
    if (self.navigateDirectlyToFriends) {
        self.navigateDirectlyToFriends = NO;
        [self performSelector:@selector(navigateToFriends) withObject:nil afterDelay:0.1];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    // Camera
    self.recorder.previewView = self.cameraView;
    [self.emojiController viewDidLayoutSubviews];
}

- (void)willResignActive {
    [self setPlayingMode:NO];
    [self setCameraMode];
    
    // Hide camera view
    if (!self.cameraBlackOverlay) {
        self.cameraBlackOverlay = [[UIView alloc] initWithFrame:self.view.frame];
        self.cameraBlackOverlay.backgroundColor = [UIColor blackColor];
        [self.cameraView insertSubview:self.cameraBlackOverlay atIndex:0];
    }
    self.cameraBlackOverlay.hidden = NO;
    [self hideMoodView];
}

- (void)didBecomeActiveCallback {
    self.cameraBlackOverlay.hidden = YES;
    
    if (!self.recorder.captureSession.isRunning) {
        [self.recorder startRunning];
    }
}

- (void)willBecomeActiveCallback {
    self.cameraBlackOverlay.hidden = YES;
    [self retrieveVideoRemotely];
    [self retrieveUnreadMessages];
    [ApiManager getRelationshipsRemotelyAndExecuteSuccess:nil failure:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSString * segueName = segue.identifier;
    if ([segueName isEqualToString: @"Friends From Video"]) {
        [self hideUIElementOnCamera:YES];
        ((FriendsViewController *) [segue destinationViewController]).delegate = self;
        ((FriendsViewController *) [segue destinationViewController]).followingRelations = self.followingRelations;
        if (sender && [sender isKindOfClass:[NSString class]]) {
            ((FriendsViewController *) [segue destinationViewController]).friendUsername = sender;
        }
    } else if ([segueName isEqualToString: @"Invite From Video"]) {
        ((InviteContactViewController *) [segue destinationViewController]).contactArray = sender;
        ((InviteContactViewController *) [segue destinationViewController]).colorArray = self.metadataColorArray;
    } else if ([segueName isEqualToString: @"Emoji From Video"]) {
        self.emojiController = (EmojiViewController *) [segue destinationViewController];
        self.emojiController.delegate = self;
    }
}

- (void)routeChangeCallback:(NSNotification*)notification {
    if ([self isPlayingMode]) {
        // To avoid pause when plug / unplug headset
        [self.friendVideoView.player play];
    }
}

- (void)navigateToFriends {
    if ([self isPlayingMode])
        [self setCameraMode];
    [self performSegueWithIdentifier:@"Friends From Video" sender:nil];
}

// --------------------------------------------
#pragma mark - Actions
// --------------------------------------------
- (void)handleRecordingTapGesture:(UITapGestureRecognizer *)gesture {
    if ([self isRecordingMode]) {
        [self terminateSessionAndPreview];
    } else if (!_isExporting) {
        if ([gesture locationInView:self.cameraView].y < 60 || [self cameraOrMicroAccessDenied]) {
            return; // don't start if we press above
        }
        [self startRecording];
        _longPressStartDate = [NSDate date];
    }
}

- (void)handleLongPressGestureOnMetaDataView:(UILongPressGestureRecognizer *)gesture {
    float widthRatio = (float)[gesture locationInView:self.metadataView].x / self.metadataView.frame.size.width;
    [self.playingProgressView.layer removeAllAnimations];
    CMTime time = CMTimeMakeWithSeconds(CMTimeGetSeconds(self.friendVideoView.player.itemDuration) * widthRatio, self.friendVideoView.player.itemDuration.timescale);
    [self.playingProgressView setFrame:CGRectMake(0, 0, widthRatio * self.metadataView.frame.size.width, self.metadataView.frame.size.height)];
    if (gesture.state == UIGestureRecognizerStateBegan) {
        [TrackingUtils trackEvent:EVENT_PLAYING_SLIDE properties:nil];
        [GeneralUtils setSlideTutoPref];
        [self showMetaData:NO];
        [self.friendVideoView.player pause];
        [self.whiteNoisePlayer pause];
        [self.friendVideoView.player seekToTime:time];
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        [self.friendVideoView.player seekToTime:time];
    } else {
        [self.friendVideoView.player seekToTime:time completionHandler:^(BOOL finished) {
            [self.friendVideoView.player play];
        }];
        [self.whiteNoisePlayer play];
        [self animatePlayingProgressBar:CMTimeGetSeconds(self.friendVideoView.player.currentItem.duration) * (1 - widthRatio)];
    }
}

- (IBAction)replayButtonClicked:(id)sender {
    if (self.failedVideoPostArray.count > 0) {
        [self sendFailedVideo];
    } else {
        self.replayButton.enabled = NO;
        
        NSArray *unseenArray = [self unseenVideosArray];
        self.videosToPlayArray = unseenArray.count > 0 ? unseenArray : self.allVideosArray;
        [self createCompositionAndPlayVideos];
        if (unseenArray.count == 0) {
            [TrackingUtils trackEvent:EVENT_VIDEO_REPLAY properties:nil];
            
            self.slideHereTutoLabel.hidden = [GeneralUtils getSlideTutoPref];
        }
    }
}

- (IBAction)flipCameraButtonClicked:(id)sender {
    [TrackingUtils trackEvent:EVENT_CAMERA_FLIP_CLICKED properties:nil];
    self.recorder.device = self.recorder.device == AVCaptureDevicePositionBack ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack;
}

- (IBAction)friendsButtonClicked:(id)sender {
    [self navigateToFriends];
    [TrackingUtils trackEvent:EVENT_FRIEND_BUTTON_CLICKED properties:nil];
}

- (IBAction)moodButtonClicked:(id)sender
{
    // show
    [self showMoodView];

    // Tracking
    [TrackingUtils trackEvent:EVENT_MOOD_CLICKED properties:nil];
}

-(IBAction)backToCameraButtonClicked:(id)sender {
    [self returnToCameraMode];
}

- (void)handleTapOnVideo {
    if (![self isPlayingMode]) {
        return;
    }
    [TrackingUtils trackEvent:EVENT_PLAYING_TAP properties:nil];
    CMTime observedTime;
    int ii = 0;
    CMTime playerTime = self.friendVideoView.player.currentTime;
    CMTime gapPlayerTime = CMTimeAdd(playerTime, CMTimeMake(100, 600));
    for (NSValue *observedValue in self.videoPlayingObservedTimesArray) {
        if (observedValue == self.videoPlayingObservedTimesArray.lastObject) {
            [self returnToCameraMode];
        } else {
            [observedValue getValue:&observedTime];
            if (CMTIME_COMPARE_INLINE(gapPlayerTime, <, observedTime)) {
                // Set metadata
                [self setPlayingMetaDataForVideoPost:self.videosToPlayArray[ii]];
                
                [self.friendVideoView.player pause];
                [self.friendVideoView.player seekToTime:observedTime toleranceBefore:CMTimeMake(100, 600) toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
                    CGFloat videoDuration = CMTimeGetSeconds(self.friendVideoView.player.currentItem.duration);
                    CGFloat currentTime = CMTimeGetSeconds(observedTime);
                    [self.playingProgressView.layer removeAllAnimations];
                    [self.playingProgressView setFrame:CGRectMake(0, 0, currentTime / videoDuration * self.metadataView.frame.size.width, self.metadataView.frame.size.height)];
                    [self animatePlayingProgressBar:videoDuration - currentTime];
                    [self.friendVideoView.player play];
                }];
                return;
            }
        }
        ii++;
    }
}


// --------------------------------------------
#pragma mark - Feed
// --------------------------------------------
- (void)retrieveVideoRemotely {
    [ApiManager getVideoFromFriends:[self visibleUsersFromFollowingRelations]
                             success:^(NSArray *posts) {
                                 [self setVideoArray:posts];
                             } failure:nil];
}

- (void)setVideoArray:(NSArray *)videoPostArray {
    if (self.tutoVideoArray && self.tutoVideoArray.count > 0) {
        self.allVideosArray = [NSMutableArray arrayWithArray:self.tutoVideoArray];
    } else {
        self.allVideosArray = [NSMutableArray new];
    }
    [self.allVideosArray addObjectsFromArray:videoPostArray];
    [self setReplayButtonUI];
}

- (NSMutableArray *)unseenVideosArray {
    NSMutableArray *array = [NSMutableArray new];
    for (VideoPost *video in self.allVideosArray) {
        if (!video.viewerIdsArray || [video.viewerIdsArray indexOfObject:[User currentUser].objectId] == NSNotFound) {
            [array addObject:video];
        }
    }
    return array;
}

// --------------------------------------------
#pragma mark - Friends
// --------------------------------------------
- (void)retrieveFollowingLocallyAndVideosRemotely {
    [DatastoreUtils getFollowingRelationsLocallyAndExecuteSuccess:^(NSArray *followingRelations) {
        [self setObjectsFromFollowingRelationsArray:followingRelations];
        
        // todo BT v2 add to device
        [TrackingUtils setPeopleProperties:@{PROPERTY_FRIENDS_COUNT: [NSNumber numberWithInteger:followingRelations.count]}];
    } failure:nil];
}

- (void)setObjectsFromFollowingRelationsArray:(NSArray *)followingRelations {
    NSUInteger previousCount = self.followingRelations ? [self visibleUsersFromFollowingRelations].count - 1 : 0;
    
    // Same array, new relation (for pointer compat with chat controller)
    [self.followingRelations removeAllObjects];
    [self.followingRelations addObjectsFromArray:followingRelations];
    
    // Get local videos
    [DatastoreUtils getVideoLocallyFromUsers:[self visibleUsersFromFollowingRelations]
                                     success:^(NSArray *videos) {
                                         [self setVideoArray:videos];
                                     } failure:nil];
    
    // Retrieve video if different number of relations
    if (previousCount != self.followingRelations.count || previousCount == 0) {
        [self retrieveVideoRemotely];
    }
    // If friend controller, reload tableview
    [[NSNotificationCenter defaultCenter] postNotificationName:@"reload_friend_tableview"
                                                        object:nil
                                                      userInfo:nil];
}

// Users which are not muted / did not block current users
- (NSArray *)visibleUsersFromFollowingRelations {
    NSMutableArray *userArray = [NSMutableArray new];
    for (Follow *follow in self.followingRelations) {
        if (!follow.mute && !follow.blocked && follow.to) {
            [userArray addObject:follow.to];
        }
    }
    if (![userArray containsObject:[User currentUser]]) {
        [userArray addObject:[User currentUser]];
    }
    return userArray;
}

- (void)parseContactsAndFindFriends {
    ABAddressBookRequestAccessWithCompletion(self.addressBook, ^(bool granted, CFErrorRef error) {
        if (granted) {
            NSMutableDictionary *contactDictionnary = [AddressbookUtils getFormattedPhoneNumbersFromAddressBook:self.addressBook];
            [ApiManager findFlashUsersContainedInAddressBook:[contactDictionnary allKeys]
                                                     success:^(NSArray *flashers) {
                                                         // Fill Contacts
                                                         [ApiManager fillContactTableWithContacts:[contactDictionnary allKeys] aBFlasher:flashers success:nil failure:nil];
                                                     }
                                                     failure:nil];
            [AddressbookUtils saveContactDictionnary:contactDictionnary];
            
            // Current user real name
            NSString *abName = contactDictionnary[[User currentUser].username];
            if (abName && abName.length > 0 && (![User currentUser].addressbookName || [User currentUser].addressbookName.length == 0)) {
                [ApiManager saveAddressbookName:contactDictionnary[[User currentUser].username]];
            }
        }
        
        // todo BT v2 add to user
        [TrackingUtils setPeopleProperties:@{PROPERTY_ALLOW_CONTACT: [NSNumber numberWithBool:granted]}];
    });
}

// --------------------------------------------
#pragma mark - Playing
// --------------------------------------------
- (void)createCompositionAndPlayVideos {
    NSArray *videoArray = self.videosToPlayArray;
    self.videoPlayingObservedTimesArray = [NSMutableArray new];
    AVPlayerItem *pi = [VideoUtils createAVPlayerItemWithVideoPosts:videoArray
                       andFillObservedTimesArray:self.videoPlayingObservedTimesArray];
    
    // Case where video not yet downloaded
    if (!pi) return;
    if (pi.duration.value <= 0) {
        [self setReplayButtonDownloadingState];
        if (self.downloadingStateTimer) {
            [self.downloadingStateTimer invalidate];
        }
        self.downloadingStateTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(setReplayButtonDownloadingState) userInfo:nil repeats:YES];
        return;
    }

    // Set item
    [self.friendVideoView.player setItem:pi];
    
    // Time observer
    if (self.compositionTimerObserverArray) {
        for (id observer in self.compositionTimerObserverArray) {
            [self.friendVideoView.player removeTimeObserver:observer];
        }
    }
    self.compositionTimerObserverArray = [NSMutableArray new];
    for (int ii = 0; ii < self.videoPlayingObservedTimesArray.count; ii++) {
        [self.compositionTimerObserverArray addObject:[self.friendVideoView.player addBoundaryTimeObserverForTimes:[NSArray arrayWithObject:self.videoPlayingObservedTimesArray[ii]] queue:dispatch_get_main_queue() usingBlock:^{
            // update metadata
            if (ii < self.videoPlayingObservedTimesArray.count - 1 && ii < videoArray.count - 1) {
                [self setPlayingMetaDataForVideoPost:videoArray[ii + 1]];
            } else {
                [self returnToCameraMode];
            };
        }]];
    }
    
    // Play
    [self.friendVideoView.player seekToTime:kCMTimeZero completionHandler:^(BOOL finished) {
        [self.friendVideoView.player play];
        [self setPlayingMode:YES];
        [self setPlayingMetaDataForVideoPost:videoArray[0]];
        [self.playingProgressView setFrame:CGRectMake(0, 0, 0, self.metadataView.frame.size.height)];
        [self animatePlayingProgressBar:CMTimeGetSeconds(pi.duration)];
    }];
}

- (void)setPlayingMetaDataForVideoPost:(VideoPost *)post {
    NSString *newNameButtonTitle = [NSString stringWithFormat:@"%@",post.user.flashUsername];
    
    if (![self.nameButton.titleLabel.text isEqualToString:newNameButtonTitle]) {
        _metadataColorIndex ++;
        if (_metadataColorIndex >= self.metadataColorArray.count) {
            _metadataColorIndex = 0;
        }
    }
    
    [self.nameButton setTitle:newNameButtonTitle forState:UIControlStateNormal];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm"];
    NSString *stringDate = [dateFormatter stringFromDate:post.recordedAt];
    self.timeLabel.text = stringDate;
    
    // Color
    self.nameButton.backgroundColor = self.metadataColorArray[_metadataColorIndex];
    
    // Show metadata
    [self showMetaData:YES];
    
    // Update viewer ids
    [post addUniqueObject:[User currentUser].objectId forKey:@"viewerIdsArray"];
    
    // Update video seen
    if (!(post.user == [User currentUser])) {
        [InviteUtils incrementVideoSeenSinceLastInvitePresentedCount];
    }
    if (self.potentialContactsToInvite == nil && [InviteUtils shouldPresentInviteController]) {
        [InviteUtils pickContactsToPresent:MIN(self.videosToPlayArray.count,kMinInviteCount + arc4random_uniform(kMaxInviteCount - kMinInviteCount + 1))
                                   success:^(NSArray *contacts) {
                                       self.potentialContactsToInvite = [NSMutableArray arrayWithArray:contacts];
                                   } failure:nil];
    }
    
    // Track
    [TrackingUtils trackEvent:EVENT_VIDEO_SEEN properties:nil];
}

- (void)showMetaData:(BOOL)flag {
    self.nameButton.hidden = !flag;
    self.timeLabel.hidden = !flag;
}

- (void)returnToCameraMode {
    // Update posts viewer Ids
    [ApiManager updateVideoPosts:self.videosToPlayArray];
        
    // Invite
    if (self.potentialContactsToInvite != nil && self.potentialContactsToInvite.count > 0) {
        [self performSegueWithIdentifier:@"Invite From Video" sender:self.potentialContactsToInvite];
        self.potentialContactsToInvite = nil;
    }
    [self setCameraMode];
    
    // tuto admin messages
    if (_createTutoAdminMessages) {
        [ApiManager createAdminMessagesWithContent:@[NSLocalizedString(@"welcome_admin_message_1", nil),NSLocalizedString(@"welcome_admin_message_2", nil),NSLocalizedString(@"welcome_admin_message_3", nil)] success:^{
            _createTutoAdminMessages = NO;
            [self retrieveUnreadMessages];
        } failureBlock:nil];
    // 2nd replay : ask for notif
    } else if (![NotifUtils isRegisteredForRemoteNotification]) {
        [NotifUtils registerForRemoteNotif];
    }
}

- (IBAction)usernameButtonClicked:(id)sender {
    NSString *username = self.nameButton.titleLabel.text;
    if ([username isEqualToString:[User currentUser].flashUsername]) {
        return;
    } else {
        [self performSegueWithIdentifier:@"Friends From Video" sender:username];
        [self returnToCameraMode];
    }
}

// --------------------------------------------
#pragma mark - Recording
// --------------------------------------------

- (void)startRecording {
    if (!self.recorder.captureSession.isRunning) {
        [self.recorder startRunning];
    }

    _recordingRunning = YES;
    [self.recorder.session removeAllSegments];
    [self setRecordingMode];
    self.recordingMaxDurationTimer = [NSTimer scheduledTimerWithTimeInterval:kRecordSessionMaxDuration + kVideoEndCutDuration target:self selector:@selector(recordMaxDurationReached) userInfo:nil repeats:NO];
    [self.recorder record];
}

- (void)recordMaxDurationReached {
    [self terminateSessionAndPreview];
}

- (void)playPreviewWithAsset:(AVAsset *)asset {
    [self.previewView.player setItemByAsset:asset];
    [self setPreviewMode];
    [self.previewView.player play];
}


- (void)terminateSessionAndPreview
{
    // Logic to avoid double case
    if (_isExporting || !_recordingRunning) {
        return;
    }
    _isExporting = YES;
    _recordingRunning = NO;
    [self.recordingMaxDurationTimer invalidate];
    
    // Pause and export
    [self endRecordingMode];
    [self.recorder pause: ^{
        // Preview UI
        [self playPreviewWithAsset:self.recorder.session.assetRepresentingSegments];

        [self exportRecordingAndExecuteSuccess:^(VideoPost *post) {
            _isExporting = NO;
            self.postToSend = post;
        } failure:^{
            _isExporting = NO;
            [self setCameraMode];
        }];
    }];
}

// Export
- (void)exportRecordingAndExecuteSuccess:(void(^)(VideoPost *))successBlock
                                 failure:(void(^)())failureBlock
{
    SCRecordSession *recordSession = self.recorder.session;
    if (CMTimeGetSeconds(recordSession.segmentsDuration) < kRecordMinDuration) {
        if (failureBlock)
            failureBlock();
    } else {
        // Create and pin post
        VideoPost *post = [VideoPost createCurrentUserPost];
        
        // Tracking
        NSDictionary *properties = @{@"length":[NSNumber numberWithFloat:CMTimeGetSeconds(recordSession.duration)], @"selfie": [NSNumber numberWithBool:(self.recorder.device == AVCaptureDevicePositionFront)], @"moodCount": [NSNumber numberWithInteger:self.moodsContainerView.subviews.count]};
        post.videoProperties = [NSMutableDictionary dictionaryWithDictionary:properties];
        
        AVAsset *asset = recordSession.assetRepresentingSegments;
        SCAssetExportSession *exporter = [[SCAssetExportSession alloc] initWithAsset:asset];
        exporter.outputUrl = post.localUrl;
        exporter.outputFileType = AVFileTypeMPEG4;
        
        // Add mood
        if (![self moodIsEmpty]) {
            AVAssetTrack *videoAssetTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
            exporter.videoConfiguration.watermarkImage = self.moodPreviewImageView.image;
            exporter.videoConfiguration.watermarkFrame = CGRectMake(0,0,videoAssetTrack.naturalSize.width,videoAssetTrack.naturalSize.height);
        }

        [exporter exportAsynchronouslyWithCompletionHandler: ^{
            if (exporter.error == nil) {
                if (successBlock)
                    successBlock(post);
            } else {
                if (failureBlock)
                    failureBlock();
                NSLog(@"Export failed: %@", exporter.error);
            }
        }];
    }
}

- (void)tapOnPreview:(UITapGestureRecognizer *)gesture {
    if (!CGRectContainsPoint(self.cancelAreaView.frame, [gesture locationInView:self.previewView])) {
        [self sendVideoPost:self.postToSend];
    }
    [self setCameraMode];
}

- (BOOL)cameraOrMicroAccessDenied {
    AVAuthorizationStatus videoAuthStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    AVAuthorizationStatus audioAuthStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    
    // Tracking
    [TrackingUtils setPeopleProperties:@{PROPERTY_ALLOW_CAMERA: [NSNumber numberWithBool:(videoAuthStatus == AVAuthorizationStatusAuthorized)], PROPERTY_ALLOW_MICRO: [NSNumber numberWithBool:(audioAuthStatus == AVAuthorizationStatusAuthorized)]}];
    
    // If denial, send back to settings
    if(videoAuthStatus == AVAuthorizationStatusDenied || audioAuthStatus == AVAuthorizationStatusDenied) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"camera_access_error_title", nil)
                                    message:NSLocalizedString(@"camera_access_error_message", nil)
                                   delegate:self
                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                          otherButtonTitles:nil] show];
        return YES;
    }
    
    return NO;
}


// --------------------------------------------
#pragma mark - Sending
// --------------------------------------------
- (void)sendVideoPost:(VideoPost *)post
{
    NSInteger userScore = [User currentUser].score;
    [DatastoreUtils pinVideoAsUnsend:post];
    self.isSendingCount ++;
    
    // Send video
    __block int previousProgress = 0;
    [ApiManager saveVideoPost:post
            andExecuteSuccess:^() {
                [DatastoreUtils unpinVideoAsUnsend:post];
                self.cumulatedProgress -= previousProgress;
                self.isSendingCount --;
                [self.allVideosArray addObject:post];
                [self.allVideosArray sortUsingComparator:^NSComparisonResult(VideoPost *obj1, VideoPost *obj2) {
                    return [obj1.recordedAt compare:obj2.recordedAt];
                }];
                if (![self isPlayingMode])
                    [self setReplayButtonUI];
                // Track
                [TrackingUtils trackEvent:EVENT_VIDEO_SENT properties:post.videoProperties];
                
                // Event based on score
                if (userScore == kUserInitialScore) {
                    // first tuto
                    [self startReplayTutoAnim];
                } else if ([GeneralUtils shouldPresentRateAlert:[User currentUser].score]) {
                    // Rating alert
                    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"rating_alert_title",nil)
                                                message:NSLocalizedString(@"rating_alert_message",nil)
                                               delegate:self cancelButtonTitle:NSLocalizedString(@"later_button",nil)
                                      otherButtonTitles:NSLocalizedString(@"no_thanks_button_title", nil),NSLocalizedString(@"rate_button_title", nil), nil] show];
                }
            } failure:^(NSError *error, BOOL addToFailArray) {
                self.cumulatedProgress -= previousProgress;
                self.isSendingCount --;
                if (addToFailArray) {
                    [self.failedVideoPostArray addObject:post];
                } else {
                    [DatastoreUtils unpinVideoAsUnsend:post];
                }
                [self setReplayButtonUI];
            } completionBlock:^(int progress) {
                [self incrementSendingProgressBy:progress - previousProgress duration:3];
                previousProgress = progress;
            }];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // Hide textview
        for (UIView *view in self.moodsContainerView.subviews) {
            [view removeFromSuperview];
        }
        
        // 1st flash
        if (userScore == kUserInitialScore) {
            self.recordTutoLabel.hidden = YES;
            self.replayTutoLabel.text = NSLocalizedString(@"first_flash_tuto_label", nil);
            self.replayTutoLabel.hidden = NO;
        }
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
        __weak __typeof__(self) weakSelf = self;
        if (_isSendingCount == 0) {
            [self setSendingBarWidthTo:self.sendingBarContainerView.frame.size.width
                              duration:0.5
                            completion:^(BOOL completed) {
                                weakSelf.sendingBarContainerView.hidden = YES;
                                [weakSelf setSendingBarWidthTo:0 duration:0 completion:nil];
            }];
            self.cumulatedProgress = 0;
        } else {
            self.sendingBarContainerView.hidden = NO;
            [self incrementSendingProgressBy:0 duration:0];
        }
    });
}

- (void)setSendingBarWidthTo:(CGFloat)width
                    duration:(float)duration
                  completion:(void(^)(BOOL completed))completionBlock
{
    CGRect frame = self.sendingBarView.frame;
    self.sendingBarView.frame = frame;
    frame.size.width = width;
    
    [UIView animateWithDuration:duration
                          delay:0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         [self.sendingBarView setFrame:frame];
                     } completion:completionBlock];
}

- (void)incrementSendingProgressBy:(NSInteger)progress duration:(float)duration {
    self.cumulatedProgress += progress;
    [self setSendingBarWidthTo:(self.cumulatedProgress * self.sendingBarContainerView.frame.size.width / (float)_isSendingCount / 110.)
                      duration:duration
                    completion:nil];
}


// ------------------------------
#pragma mark Message
// ------------------------------
- (void)retrieveUnreadMessages {
    [ApiManager retrieveUnreadMessagesAndExecuteSuccess:^(NSArray *messagesArray) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"retrieve_message_locally"
                                                            object:nil
                                                          userInfo:nil];
        [self setMessageCount:messagesArray.count];
    } failure:nil];
}


- (void)setMessageCount:(NSInteger)messageCount {
    _messageCount = messageCount;
    [self resetNotifCount];
}

- (void)setNotificationCount:(NSInteger)notifCount {
    if (notifCount > 0) {
        [self.friendListButton setTitle:[NSString stringWithFormat:@"%lu",(long)notifCount] forState:UIControlStateNormal];
        [self.friendListButton setBackgroundImage:nil forState:UIControlStateNormal];
    } else {
        [self.friendListButton setBackgroundImage:[UIImage imageNamed:@"friends_button"] forState:UIControlStateNormal];
        [self.friendListButton setTitle:nil forState:UIControlStateNormal];
    }
    
    // Update Badge
    [ApiManager updateBadge:notifCount + self.unreadVideoCount];
}

- (void)resetNotifCount {
    NSInteger notifCount = self.messageCount + [GeneralUtils getNewAddressbookFlasherCount] + [GeneralUtils getNewUnfollowedFollowerCount];
    [self setNotificationCount:notifCount];
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
    
- (void)endRecordingMode {
    self.recordingProgressContainer.hidden = YES;
    [self.recordingProgressBar.layer removeAllAnimations];
    self.recordingProgressBar.frame = CGRectMake(0,0, 0, self.recordingProgressContainer.frame.size.height);
}
    
- (void)setPlayingMode:(BOOL)flag
{
    self.friendVideoView.hidden = !flag;
    if (flag) {
        [self stopReplayFlashTutoAnim];
        [self.whiteNoisePlayer play];
        [self endPreviewMode];
    } else {
        [self.playingProgressView.layer removeAllAnimations];
        [self.whiteNoisePlayer pause];
        [self.friendVideoView.player pause];
    }
}

- (void)setCameraMode
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setPlayingMode:NO];
        [self endPreviewMode];
        [self endRecordingMode];
        [self hideUIElementOnCamera:NO];
        [self setReplayButtonUI];
    });
}

- (void)setRecordingMode {
    [self stopReplayFlashTutoAnim];
    [self setPlayingMode:NO];
    [self endPreviewMode];
    
    [self hideUIElementOnCamera:YES];
    
//    self.recordTutoLabel.text = NSLocalizedString(@"recording_label", nil);
//    self.recordTutoLabel.hidden = NO;
    
    // 1st flash
    if (![self moodIsEmpty]) {
        self.moodsContainerView.hidden = NO;
        self.moodPreviewImageView.image = [self getImageFromMood]; 
    }
    
    // Start UI + progress bar anim
    self.recordingProgressContainer.hidden = NO;
    self.recordingProgressBar.frame = CGRectMake(0,0, 0, self.recordingProgressContainer.frame.size.height);
    [UIView animateWithDuration:kRecordSessionMaxDuration + kVideoEndCutDuration
                          delay:0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         [self.recordingProgressBar setFrame:CGRectMake(0,0,self.recordingProgressContainer.frame.size.width, self.recordingProgressContainer.frame.size.height)];
                     } completion:nil];
}

- (void)endPreviewMode
{
    self.previewView.hidden = YES;
    [self.previewView.player pause];
}

- (void)setPreviewMode {
    [self setPlayingMode:NO];
//    self.cancelConfirmView.hidden = YES;
    self.cancelAreaView.hidden = NO;
    self.previewView.hidden = NO;
    if (![self moodIsEmpty]) {
//        self.releaseToSendTuto.hidden = YES;
        self.moodPreviewImageView.hidden = NO;
    } else {
        self.moodPreviewImageView.hidden = YES;
//        self.releaseToSendTuto.hidden = NO;
    }
    self.tapToSendTuto.hidden = NO;
}


- (void)startReplayTutoAnim {
    self.recordTutoLabel.hidden = YES;
    self.replayTutoArrow.hidden = NO;
    self.replayTutoLabel.hidden = NO;
    CGRect initialFrame = self.replayTutoArrow.frame;
    initialFrame.origin.y = self.replayButton.frame.origin.y - 10 - initialFrame.size.height;
    self.replayTutoArrow.frame = initialFrame;
    [UIView animateWithDuration:0.5f
                          delay:0.0f
                        options:UIViewAnimationOptionRepeat | UIViewAnimationOptionAutoreverse
                     animations:^{
                         [self.replayTutoArrow setFrame:CGRectMake(initialFrame.origin.x, initialFrame.origin.y - 30, initialFrame.size.width, initialFrame.size.height)];
                     }
                     completion:nil];
}

- (void)stopReplayFlashTutoAnim {
    [self.replayTutoArrow.layer removeAllAnimations];
    self.replayTutoArrow.hidden = YES;
    self.replayTutoLabel.hidden = YES;
}

- (void)setReplayButtonUI {
    [self.downloadingStateTimer invalidate];
    self.replayButton.enabled = YES;

    if (self.failedVideoPostArray.count > 0) {
        // failed video state
        self.replayButton.backgroundColor = [ColorUtils transparentRed];
        NSString *title = self.failedVideoPostArray.count > 1 ? [NSString stringWithFormat: NSLocalizedString(@"videos_sending_failed", nil), self.failedVideoPostArray.count] : NSLocalizedString(@"video_sending_failed", nil);
        [self.replayButton setTitle:title forState:UIControlStateNormal];
        self.replayButton.hidden = NO;
    } else {
        NSString *buttonTitle;
        
        if (self.allVideosArray.count == 0) {
            buttonTitle = NSLocalizedString(@"no_video_label", nil);
        } else {
            // Replay or new state
            NSMutableArray *unseenVideos = [self unseenVideosArray];
            self.unreadVideoCount = unseenVideos.count;
            if (self.unreadVideoCount == 0) {
                self.replayButton.backgroundColor = [ColorUtils black];
                if ([User currentUser].score > kMaxScoreBeforeHidingImportantTutos) {
                    buttonTitle = NSLocalizedString(@"replay_label", nil);
                } else {
                    buttonTitle = [NSString stringWithFormat:self.allVideosArray.count < 2 ? NSLocalizedString(@"replay_flash_label", nil) : NSLocalizedString(@"replay_flashes_label", nil),self.allVideosArray.count];
                }
            } else {
                self.replayButton.backgroundColor = [ColorUtils purple];
                BOOL videoFromCurrentUserOnly = YES;
                for (VideoPost *post in unseenVideos) {
                    if (post.user != [User currentUser]) {
                        videoFromCurrentUserOnly = NO;
                        break;
                    }
                }
                if (videoFromCurrentUserOnly) {
                    buttonTitle = [NSString stringWithFormat:@"%lu %@",(long)self.unreadVideoCount,self.unreadVideoCount < 2 ? NSLocalizedString(@"video_sent_label", nil) : NSLocalizedString(@"videos_sent_label", nil)];
                } else {
                    buttonTitle = [NSString stringWithFormat:@"%lu %@",(long)self.unreadVideoCount,self.unreadVideoCount < 2 ? NSLocalizedString(@"new_video_label", nil) : NSLocalizedString(@"new_videos_label", nil)];
                }
            }
        }
        [self.replayButton setTitle:buttonTitle forState:UIControlStateNormal];
        self.replayButton.hidden = NO;
        
        // Update Badge
        [ApiManager updateBadge:self.messageCount + self.unreadVideoCount];
    }
}

- (void)setReplayButtonDownloadingState {
    self.replayButton.enabled = YES;
    if (self.videosToPlayArray && self.videosToPlayArray.count > 0) {
        NSInteger progress = ((VideoPost *)self.videosToPlayArray[0]).downloadProgress;
        if (progress == 100) {
            [self setReplayButtonUI];
        } else {
            [self.replayButton setTitle:[NSString stringWithFormat:@"%@ (%lu%%)",NSLocalizedString(@"downloading_label", nil),(long)((VideoPost *)self.videosToPlayArray[0]).downloadProgress] forState:UIControlStateNormal];
        }
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
        self.replayButton.alpha = 0;
        self.replayButton.hidden = YES;
        self.recordTutoLabel.hidden = YES;
        self.moodsContainerView.hidden = YES;
    } else {
        self.replayButton.alpha = 1;
        [self setReplayButtonUI];
        self.moodsContainerView.hidden = NO;
        self.recordTutoLabel.hidden = NO;
    }
    self.cameraSwitchButton.hidden = flag;
    self.friendListButton.hidden = flag;
    self.moodButton.hidden = flag;
}

- (void)playOneFriendVideos:(NSArray *)videoArray {
    self.videosToPlayArray = videoArray;
    [self createCompositionAndPlayVideos];
}

- (void)removeVideoFromVideosArray:(VideoPost *)video {
    [self.allVideosArray removeObject:video];
}


// --------------------------------------------
#pragma mark - Details
// --------------------------------------------

- (BOOL)prefersStatusBarHidden {
    return YES;
}

//- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
//{
//    // Disallow recognition of tap gestures in the segmented control.
//    if ((touch.view == self.replayButton || touch.view == self.cameraSwitchButton) || touch.view == self.friendListButton || touch.view == self.moodButton || [touch.view isKindOfClass:[MoodTextView class]]) {
//        return NO;
//    }
//    return YES;
//}

// --------------------------------------------
#pragma mark - Mood
// --------------------------------------------
- (void)initMoodTextView {
    self.inProgressMoodTextView = [[MoodTextView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height/2, self.view.frame.size.width, 0)];
    [self.moodsContainerView addSubview:self.inProgressMoodTextView];
}

- (BOOL)moodIsEmpty {
    return self.moodsContainerView.subviews.count == 0;
}

- (void)emojiClicked:(NSString *)emoji {
    self.inProgressMoodTextView.text = emoji;
    self.inProgressMoodTextView.font = [UIFont fontWithName:@"NHaasGroteskDSPro-75Bd" size:250.0];
    [self textViewDidChange:self.inProgressMoodTextView];
    [self hideMoodView];
}

// Show mood
- (void)showMoodView
{
    [self initMoodTextView];
    [self.emojiController resetFrame];
    [self hideUIElementOnCamera:YES];
    self.moodCreationContainerView.hidden = NO;
    if (self.emojiView.hidden) {
        // caption mode => keyboard
        [self.inProgressMoodTextView becomeFirstResponder];
    }
}

// hide mood
- (void)hideMoodView {
    if (self.inProgressMoodTextView) {
        [self.inProgressMoodTextView resignFirstResponder];
        if (self.inProgressMoodTextView.text.length == 0) {
            [self.inProgressMoodTextView removeFromSuperview];
        }
        self.inProgressMoodTextView = nil;
    }
    [self hideUIElementOnCamera:NO];
    self.moodCreationContainerView.hidden = YES;
}

// Emoji button
- (IBAction)emojiButtonClicked:(id)sender {
    if (!self.emojiView.hidden) {
        [self hideMoodView];
    } else {
        [self.inProgressMoodTextView resignFirstResponder];
        self.emojiView.hidden = NO;
        self.inProgressMoodTextView.hidden = YES;
        
        self.captionButton.backgroundColor = [UIColor lightGrayColor];
        [self.captionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.captionButton setTitle:@"Aa" forState:UIControlStateNormal];
        
        self.emojiButton.backgroundColor = [UIColor whiteColor];
        [self.emojiButton setTitle:NSLocalizedString(@"close_button", nil) forState:UIControlStateNormal];
        self.captionButton.titleLabel.textColor = [UIColor lightGrayColor];
    }
}

// Caption button
- (IBAction)captionButtonClicked:(id)sender {
    if (self.emojiView.hidden) {
        [self hideMoodView];
    } else {
        self.inProgressMoodTextView.font = [UIFont fontWithName:@"NHaasGroteskDSPro-75Bd" size:50.0];
        [self.inProgressMoodTextView becomeFirstResponder];
        self.inProgressMoodTextView.hidden = NO;
        self.emojiView.hidden = YES;
        
        self.captionButton.backgroundColor = [UIColor whiteColor];
        [self.captionButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        [self.captionButton setTitle:NSLocalizedString(@"close_button", nil) forState:UIControlStateNormal];
        
        self.emojiButton.backgroundColor = [UIColor clearColor];
        [self.emojiButton setTitle:@"😀" forState:UIControlStateNormal];
    }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        [self hideMoodView];
        return NO;
    }
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
    CGSize size = [textView sizeThatFits:CGSizeMake(self.view.frame.size.width, 1000)];
    CGRect previousFrame = textView.frame;
    textView.frame = CGRectMake(0, previousFrame.origin.y + previousFrame.size.height - size.height, self.view.frame.size.width, size.height);
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    return !self.moodCreationContainerView.hidden;
}


// ----------------------------------------------------------
#pragma mark Keyboard
// ----------------------------------------------------------
// Caption editing UI
- (void)keyboardWillShow:(NSNotification *)notification {
    self.moodsContainerView.hidden = NO;
    
    // Move button
    [KeyboardUtils pushUpTopView:self.moodButtonContainerView whenKeyboardWillShowNotification:notification];
    
    // Editing UI
    NSDictionary *userInfo = [notification userInfo];
    NSValue *aValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardRect = [aValue CGRectValue];
    CGFloat width = self.view.frame.size.width;
    CGSize size = [self.inProgressMoodTextView sizeThatFits:CGSizeMake(width, 1000)];
    self.inProgressMoodTextView.frame = CGRectMake(0, keyboardRect.origin.y - self.moodButtonContainerView.frame.size.height - size.height, width, size.height);
}


// Caption transformed UI
- (void)keyboardWillHide:(NSNotification *)notification {
    // Move button
    [KeyboardUtils pushUpTopView:self.moodButtonContainerView whenKeyboardWillShowNotification:notification];
}

// Screenschot caption
- (UIImage *)getImageFromMood
{
    UIGraphicsBeginImageContextWithOptions(self.moodsContainerView.bounds.size, NO, 0.0);
    [self.moodsContainerView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage * img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}



// ----------------------------------------------------------
#pragma mark AlertView
// ----------------------------------------------------------
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([alertView.title isEqualToString:NSLocalizedString(@"camera_access_error_title", nil)]) {
        [GeneralUtils openSettings];
    } else if ([alertView.title isEqualToString:NSLocalizedString(@"rating_alert_title", nil)]) {
        if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"rate_button_title", nil)]) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:kAppStoreLink]];
            [GeneralUtils setRatingAlertAccepted];
        } else if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"no_thanks_button_title", nil)]) {
            [GeneralUtils setRatingAlertAccepted];
        }
    }
}

@end
