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

#import "CaptionTextView.h"
#import "FriendsViewController.h"
#import "InviteContactViewController.h"
#import "VideoViewController.h"

#import "AddressbookUtils.h"
#import "ConstantUtils.h"
#import "ColorUtils.h"
#import "GeneralUtils.h"
#import "InviteUtils.h"
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
@property (strong, nonatomic) UILongPressGestureRecognizer *longPressGestureRecogniser;
@property (weak, nonatomic) IBOutlet UIView *cameraView;
@property (strong, nonatomic) UIView *recordingProgressBar;
@property (weak, nonatomic) IBOutlet UICustomLineLabel *recordTutoLabel;
@property (weak, nonatomic) IBOutlet UIButton *cameraSwitchButton;
@property (weak, nonatomic) IBOutlet UIButton *friendListButton;
@property (strong, nonatomic) SCFilter *filter;

// Caption
@property (weak, nonatomic) IBOutlet UIButton *captionButton;
@property (strong, nonatomic) CaptionTextView *captionTextView;
@property (nonatomic) CGAffineTransform captionTransform;
@property (nonatomic) CGPoint captionCenter;
@property (strong, nonatomic) UITapGestureRecognizer *closeCaptionTapGestureRecogniser;

// Mood
@property (weak, nonatomic) IBOutlet UIView *emojiView;
@property (weak, nonatomic) IBOutlet UILabel *moodLabel;
@property (weak, nonatomic) IBOutlet UILabel *previewMoodLabel;

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

// Messages
@property (nonatomic) NSInteger messageCount;
@property (nonatomic) NSInteger unreadVideoCount;

// Invite
@property (nonatomic) NSMutableArray *potentialContactsToInvite;

// Tuto
@property (weak, nonatomic) IBOutlet UILabel *firstFlashTutoLabel;
@property (weak, nonatomic) IBOutlet UIImageView *firstFlashTutoArrow;

// Black splash
@property (strong, nonatomic) UIView *cameraBlackOverlay;

@end

@implementation VideoViewController {
    BOOL _isExporting;
    BOOL _longPressRunning;
    BOOL _recordingRunning;
    BOOL _cancelRecording;
    int _metadataColorIndex;
    NSDate *_longPressStartDate;
    BOOL _createTutoAdminMessages;
    BOOL _emojiViewInitialized;
}

// --------------------------------------------
#pragma mark - Life Cycle
// --------------------------------------------

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Logic
    _createTutoAdminMessages = NO;
    _isExporting = NO;
    _longPressRunning = NO;
    _recordingRunning = NO;
    _cancelRecording = NO;
    _emojiViewInitialized = NO;
    _metadataColorIndex = 0;
    self.isSendingCount = 0;
    self.unreadVideoCount = 0;
    self.friendVideoView.hidden = YES;
    self.potentialContactsToInvite = nil;
    self.allVideosArray = [NSMutableArray new]; 
    
    self.metadataColorArray = [NSArray arrayWithObjects:[ColorUtils pink], [ColorUtils purple], [ColorUtils blue], [ColorUtils green], [ColorUtils orange], nil];
    
    // Audio session
    AVAudioSession* audioSession = [AVAudioSession sharedInstance];
    BOOL success; NSError* error;
    success = [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord
                            withOptions:AVAudioSessionCategoryOptionMixWithOthers | AVAudioSessionCategoryOptionDefaultToSpeaker
                                  error:&error];
    if (!success)
        NSLog(@"AVAudioSession error setting category:%@",error);
    [audioSession setActive:YES error:nil];
    
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
    self.closeCaptionTapGestureRecogniser = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapToCloseCaption)];
    [self.cameraView addGestureRecognizer:self.closeCaptionTapGestureRecogniser];
    
    // Mood
    self.moodLabel.hidden = YES;
    self.emojiView.hidden = YES;
    
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
    if (![GeneralUtils isiPhone4]) {
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
    if ([User currentUser].score >= kMaxScoreBeforeHidingImportantTutos) {
        [self.recordTutoLabel removeFromSuperview];
        [self.releaseToSendTuto removeFromSuperview];
    } else {
        self.recordTutoLabel.text = NSLocalizedString(@"hold_ro_record_label", nil);
        self.recordTutoLabel.lineType = LineTypeDown;
        self.recordTutoLabel.lineHeight = 4.0f;
    }
    self.replayButton.hidden = YES;
    self.messageCount = 0;
    
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
    if (!self.avoidParsingContact) {
        [self parseContactsAndFindFriends];
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
        } failureBlock:nil];
    }
    self.firstFlashTutoArrow.hidden = YES;
    self.firstFlashTutoLabel.hidden = YES;
    self.firstFlashTutoLabel.text = NSLocalizedString(@"first_flash_tuto_label", nil);
    
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
    
    // Tracking
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        [TrackingUtils setPeopleProperties:@{PROPERTY_ALLOW_MICRO: [NSNumber numberWithBool:granted]}];
    }];
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
        [TrackingUtils setPeopleProperties:@{PROPERTY_ALLOW_CAMERA: [NSNumber numberWithBool:granted]}];
    }];
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
    
    // Emoji view
    [self initEmojiView];
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
    [self resignCaptionFirstResponderAndHideIfEmpty];
}

- (void)didBecomeActiveCallback {
    self.cameraBlackOverlay.hidden = YES;
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
    [self resignCaptionFirstResponderAndHideIfEmpty];
    [self performSegueWithIdentifier:@"Friends From Video" sender:nil];
}

// --------------------------------------------
#pragma mark - Actions
// --------------------------------------------
- (void)handleLongPressGesture:(UILongPressGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateBegan) {
        if ([gesture locationInView:self.cameraView].y < 60 || [self cameraOrMicroAccessDenied]) {
            return; // don't start if we press above
        }
        if (!_isExporting) {
            _longPressRunning = YES;
            [self startRecording];
            _longPressStartDate = [NSDate date];
        }
        [self resignCaptionFirstResponderAndHideIfEmpty];
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        if ([self isPreviewMode]) {
            BOOL cancelMode = CGRectContainsPoint(self.cancelAreaView.frame, [gesture locationInView:self.previewView]);
            self.cancelAreaView.hidden = cancelMode;
            self.releaseToSendTuto.hidden = cancelMode || self.captionTextView.text.length != 0;
            self.captionTextView.hidden = cancelMode || self.captionTextView.text.length == 0;
            self.cancelConfirmView.hidden = !cancelMode;
        }
    } else {
        if (_longPressRunning) {
            _longPressRunning = NO;
            _cancelRecording = [self isPreviewMode] && CGRectContainsPoint(self.cancelAreaView.frame, [gesture locationInView:self.previewView]);
            [self terminateSessionAndExport];
            [self setCameraMode];
        }
    }
}

- (void)handleLongPressGestureOnMetaDataView:(UILongPressGestureRecognizer *)gesture {
    float widthRatio = (float)[gesture locationInView:self.metadataView].x / self.metadataView.frame.size.width;
    [self.playingProgressView.layer removeAllAnimations];
    CMTime time = CMTimeMakeWithSeconds(CMTimeGetSeconds(self.friendVideoView.player.itemDuration) * widthRatio, self.friendVideoView.player.itemDuration.timescale);
    [self.playingProgressView setFrame:CGRectMake(0, 0, widthRatio * self.metadataView.frame.size.width, self.metadataView.frame.size.height)];
    if (gesture.state == UIGestureRecognizerStateBegan) {
        [TrackingUtils trackEvent:EVENT_PLAYING_SLIDE properties:nil];
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
            
            self.slideHereTutoLabel.hidden = [User currentUser].score > kMaxScoreBeforeHidingOtherTutos;
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

- (IBAction)captionButtonClicked:(id)sender
{
    // todo bt
    // show mood
    // if mood hide it
    if (!self.moodLabel.hidden) {
        self.moodLabel.hidden = YES;
    } else {
        [self hideUIElementOnCamera:YES];
        self.emojiView.hidden = NO;
    }
    
    // text view
//    [self textViewDidChange:self.captionTextView];
//    self.longPressGestureRecogniser.minimumPressDuration = 0.5;
//    [self.captionTextView becomeFirstResponder];
//    self.captionTextView.hidden = NO;
//    self.recordTutoLabel.hidden = YES;
    
    [TrackingUtils trackEvent:EVENT_CAPTION_CLICKED properties:nil];
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
        
        // todo BT v1.2 add to device
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
    if (previousCount != self.followingRelations.count) {
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
                                                     success:nil
                                                     failure:nil];
            [AddressbookUtils saveContactDictionnary:contactDictionnary];
            
            // Current user real name
            NSString *abName = contactDictionnary[[User currentUser].username];
            if (abName && abName.length > 0 && (![User currentUser].addressbookName || [User currentUser].addressbookName.length == 0)) {
                [ApiManager saveAddressbookName:contactDictionnary[[User currentUser].username]];
            }
        } else if ([User currentUser].score != kUserInitialScore) {
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"contact_access_error_title",nil)
                                        message:NSLocalizedString(@"contact_access_error_message",nil)
                                       delegate:self
                              cancelButtonTitle:NSLocalizedString(@"later_button",nil)
                              otherButtonTitles:NSLocalizedString(@"ok_button",nil), nil] show];
        }
        
        // todo BT v1.2 add to user
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
    [self terminateSessionAndExport];
}

- (void)playPreviewWithAsset:(AVAsset *)asset {
    [self.previewView.player setItemByAsset:asset];
    [self setPreviewMode];
    [self.previewView.player play];
}


- (void)terminateSessionAndExport
{
    // Logic to avoid double case
    if (_isExporting) {
        return;
    } else if (!_recordingRunning){
        if (!_longPressRunning && self.postToSend && !_cancelRecording) {
            [self sendVideoPost:self.postToSend];
            self.postToSend = nil;
        }
        return;
    }
    _isExporting = YES;
    _recordingRunning = NO;
    [self.recordingMaxDurationTimer invalidate];
    
    // Pause and export
    [self endRecordingMode];
    [self.recorder pause: ^{
        // Preview UI
        if (_longPressRunning) {
            [self playPreviewWithAsset:self.recorder.session.assetRepresentingSegments];
        }

        [self exportRecordingAndExecuteSuccess:^(VideoPost *post) {
            _isExporting = NO;
            if (_longPressRunning) {
                self.postToSend = post;
            } else if (!_cancelRecording) {
               [self sendVideoPost:post];
            }
        } failure:^{
            _isExporting = NO;
            [self setCameraMode];
            
            // If record too short => open caption
            // todo BT
//            if ([User currentUser].score > kMaxScoreBeforeHidingImportantTutos && [[NSDate date] timeIntervalSinceDate:_longPressStartDate] < kCaptionTapMaxDuration) {
//                [self captionButtonClicked:nil];
//            }
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
        
        // todo BT
        NSDictionary *properties = @{@"length":[NSNumber numberWithFloat:CMTimeGetSeconds(recordSession.duration)], @"selfie": [NSNumber numberWithBool:(self.recorder.device == AVCaptureDevicePositionFront)], @"caption": [NSNumber numberWithBool:(self.captionTextView.text.length > 0)]};
        post.videoProperties = properties;
        
        AVAsset *asset = recordSession.assetRepresentingSegments;
        SCAssetExportSession *exporter = [[SCAssetExportSession alloc] initWithAsset:asset];
        exporter.outputUrl = post.localUrl;
        exporter.outputFileType = AVFileTypeMPEG4;
        
        // todo BT
//        if (self.captionTextView.text.length > 0) {
//            AVAssetTrack *videoAssetTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
//            exporter.videoConfiguration.watermarkImage = [self getImageFromCaption];
//            exporter.videoConfiguration.watermarkFrame = CGRectMake(0,0,videoAssetTrack.naturalSize.width,videoAssetTrack.naturalSize.height);
//        }
        if (!self.moodLabel.hidden) {
            AVAssetTrack *videoAssetTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
            exporter.videoConfiguration.watermarkImage = [self getImageFromMood];
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

- (BOOL)cameraOrMicroAccessDenied {
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if(authStatus == AVAuthorizationStatusDenied) {
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
    [ApiManager saveVideoPost:post
            andExecuteSuccess:^() {
                [DatastoreUtils unpinVideoAsUnsend:post];
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
                    [self startFirstFlashTutoAnim];
                } else if ([GeneralUtils shouldPresentRateAlert:[User currentUser].score]) {
                    // Rating alert
                    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"rating_alert_title",nil)
                                                message:NSLocalizedString(@"rating_alert_message",nil)
                                               delegate:self cancelButtonTitle:NSLocalizedString(@"later_button",nil)
                                      otherButtonTitles:NSLocalizedString(@"no_thanks_button_title", nil),NSLocalizedString(@"rate_button_title", nil), nil] show];
                }
            } failure:^(NSError *error, BOOL addToFailArray) {
                self.isSendingCount --;
                if (addToFailArray) {
                    [self.failedVideoPostArray addObject:post];
                } else {
                    [DatastoreUtils unpinVideoAsUnsend:post];
                }
                [self setReplayButtonUI];
            }];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.captionTextView.text = @"";
        self.captionTextView.hidden = YES;
        self.moodLabel.hidden = YES;
        
        // 1st flash
        if (userScore == kUserInitialScore) {
            self.recordTutoLabel.hidden = YES;
            self.firstFlashTutoLabel.hidden = NO;
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
        // sending anim
        if (_isSendingCount > 0) {
            [self.sendingHud show:YES];
        } else {
            [self.sendingHud hide:YES];
        }
    });
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
        [self stopFirstFlashTutoAnim];
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
    [self stopFirstFlashTutoAnim];
    [self setPlayingMode:NO];
    [self endPreviewMode];
    
    [self hideUIElementOnCamera:YES];
    
    // Show caption on camera
    self.captionTextView.hidden = (self.captionTextView.text.length == 0);
    
    // 1st flash
    if ([User currentUser].score < kMaxScoreBeforeHidingOtherTutos) {
        self.recordTutoLabel.text = NSLocalizedString(@"keep_holding_label", nil);
        self.recordTutoLabel.hidden = NO;
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

- (void)endPreviewMode {
    [self.cameraView insertSubview:self.captionTextView belowSubview:self.replayButton];
    self.previewView.hidden = YES;
    [self.previewView.player pause];
}

- (void)setPreviewMode {
    [self setPlayingMode:NO];
    
    self.previewMoodLabel.hidden = self.moodLabel.hidden;
    self.previewMoodLabel.text = self.moodLabel.text;
    
    self.cancelConfirmView.hidden = YES;
    self.cancelAreaView.hidden = NO;
    self.previewView.hidden = NO;
    if (self.captionTextView.text.length != 0) {
        self.releaseToSendTuto.hidden = YES;
        [self.previewView insertSubview:self.captionTextView belowSubview:self.cancelConfirmView];
    } else {
        self.releaseToSendTuto.hidden = NO;
    }
}


- (void)startFirstFlashTutoAnim {
    self.firstFlashTutoArrow.hidden = NO;
    self.firstFlashTutoLabel.hidden = NO;
    CGRect initialFrame = self.firstFlashTutoArrow.frame;
    [UIView animateWithDuration:0.5f
                          delay:0.0f
                        options:UIViewAnimationOptionRepeat | UIViewAnimationOptionAutoreverse
                     animations:^{
                         [self.firstFlashTutoArrow setFrame:CGRectMake(initialFrame.origin.x, initialFrame.origin.y - 30, initialFrame.size.width, initialFrame.size.height)];
                     }
                     completion:nil];
}

- (void)stopFirstFlashTutoAnim {
    [self.firstFlashTutoArrow.layer removeAllAnimations];
    self.firstFlashTutoArrow.hidden = YES;
    self.firstFlashTutoLabel.hidden = YES;
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
    } else if (self.allVideosArray.count == 0) {
        // No button state
        self.replayButton.hidden = YES;
        self.unreadVideoCount = 0;
    } else {
        // Replay or new state
        NSMutableArray *unseenVideos = [self unseenVideosArray];
        self.unreadVideoCount = unseenVideos.count;
        NSString *buttonTitle;
        if (self.unreadVideoCount == 0) {
            self.replayButton.backgroundColor = [ColorUtils black];
            buttonTitle = [NSString stringWithFormat:NSLocalizedString(@"replay_label", nil)];
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
        self.captionTextView.hidden = YES;
    } else {
        self.replayButton.alpha = 1;
        [self setReplayButtonUI];
        self.captionTextView.hidden = NO;
        self.recordTutoLabel.text = NSLocalizedString(@"hold_ro_record_label", nil);
        self.recordTutoLabel.hidden = self.captionTextView.text.length != 0 || [self.captionTextView isFirstResponder] || !self.firstFlashTutoLabel.hidden;
    }
    self.cameraSwitchButton.hidden = flag;
    self.friendListButton.hidden = flag;
    self.captionButton.hidden = flag;
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

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    // Disallow recognition of tap gestures in the segmented control.
    if ((touch.view == self.replayButton || touch.view == self.cameraSwitchButton) || touch.view == self.friendListButton || touch.view == self.captionButton || touch.view == self.captionTextView) {
        return NO;
    }
    return YES;
}

// --------------------------------------------
#pragma mark - Caption
// --------------------------------------------
- (void)initEmojiView {
    if (_emojiViewInitialized) {
        return;
    }
    _emojiViewInitialized = YES;
    CGFloat width = self.emojiView.frame.size.width;
    CGFloat height = self.emojiView.frame.size.height;
    
    // assumption : horizontal margin = 1/3 of side
    NSInteger numberOfColumns = 4;
    CGFloat buttonSize = 3. / (4. * numberOfColumns + 1.) * width;
    CGFloat horizontalMargin = 1. / 3. * buttonSize;
    
    NSInteger numberOfRows = floor(height / (buttonSize * 4. / 3.));
    CGFloat verticalMargin = (height - numberOfRows * buttonSize) / (numberOfRows + 1.);
    
    // Get gray image for background
    UIGraphicsBeginImageContext(CGSizeMake(buttonSize, buttonSize));
    CGContextSetFillColorWithColor(UIGraphicsGetCurrentContext(), [UIColor lightGrayColor].CGColor);
    CGContextFillRect(UIGraphicsGetCurrentContext(), CGRectMake(0,0,buttonSize,buttonSize));
    UIImage *colorImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    for (int row = 0; row < numberOfRows; row ++) {
        for (int column = 0; column < numberOfColumns; column ++) {
            CGRect frame = CGRectMake(horizontalMargin + column * (buttonSize + horizontalMargin), verticalMargin + row * (verticalMargin + buttonSize), buttonSize, buttonSize);
            UIButton *button = [[UIButton alloc] initWithFrame:frame];
            [button setTitle:getEmojiAtIndex(row + column * numberOfRows) forState:UIControlStateNormal];
            button.titleLabel.numberOfLines = 1;
            button.titleLabel.font = [UIFont systemFontOfSize:100];
            button.titleLabel.adjustsFontSizeToFitWidth = YES;
            [button.titleLabel setTextAlignment: NSTextAlignmentCenter];
            button.contentEdgeInsets = UIEdgeInsetsMake(-buttonSize/2.75, 0.0, 0.0, 0.0);
            [button setBackgroundImage:colorImage forState:UIControlStateHighlighted];
            [button addTarget:self action:@selector(emojiClicked:) forControlEvents:UIControlEventTouchUpInside];
            [self.emojiView addSubview:button];
        }
    }
}

- (void)emojiClicked:(UIButton *)sender {
    [self hideUIElementOnCamera:NO];
    self.emojiView.hidden = YES;
    self.moodLabel.text = sender.titleLabel.text;
    self.moodLabel.hidden = NO;
}

- (void)handleTapToCloseCaption {
    [self resignCaptionFirstResponderAndHideIfEmpty];
    self.longPressGestureRecogniser.minimumPressDuration = 0;
}

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
        [self resignCaptionFirstResponderAndHideIfEmpty];
        return NO;
    }
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
    CGSize size = [self.captionTextView sizeThatFits:CGSizeMake(self.view.frame.size.width, 1000)];
    CGRect previousFrame = self.captionTextView.frame;
    self.captionTextView.frame = CGRectMake(0, previousFrame.origin.y + previousFrame.size.height - size.height, self.view.frame.size.width, size.height);
}

- (void)resignCaptionFirstResponderAndHideIfEmpty {
    [self.captionTextView resignFirstResponder];
    self.captionTextView.hidden = self.captionTextView.text.length == 0;
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
    CGFloat width = self.view.frame.size.width;
    CGSize size = [self.captionTextView sizeThatFits:CGSizeMake(width, 1000)];
    [self.captionTextView setTransform:CGAffineTransformIdentity];
    self.captionTextView.frame = CGRectMake(0, keyboardRect.origin.y - size.height, width, size.height);
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

// Screenschot mood
- (UIImage *)getImageFromMood
{
    UIView *containerView = [[UIView alloc] initWithFrame:self.view.frame];
    containerView.backgroundColor = [UIColor clearColor];
    UIView *superView = self.moodLabel.superview;
    NSInteger index = [superView.subviews indexOfObject:self.moodLabel];
    [superView insertSubview:containerView belowSubview:self.moodLabel];
    [containerView addSubview:self.moodLabel];
    
    UIGraphicsBeginImageContextWithOptions(containerView.bounds.size, NO, 0.0);
    [containerView.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage * img = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    [superView insertSubview:self.moodLabel atIndex:index];
    [containerView removeFromSuperview];
    return img;
}


// ----------------------------------------------------------
#pragma mark AlertView
// ----------------------------------------------------------
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([alertView.message isEqualToString:NSLocalizedString(@"camera_access_error_message", nil)]) {
        [GeneralUtils openSettings];
    } else if ([alertView.title isEqualToString:NSLocalizedString(@"contact_access_error_title", nil)]) {
        if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"ok_button", nil)]) {
            [GeneralUtils openSettings];
        }
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
