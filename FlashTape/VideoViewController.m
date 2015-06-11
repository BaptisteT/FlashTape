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
@property (nonatomic) NSDictionary *contactDictionnary;
@property (strong, nonatomic) NSMutableArray *friends;

// Playing
@property (strong, nonatomic) NSMutableArray *allVideosArray;
@property (strong, nonatomic) NSArray *videosToPlayArray;
@property (weak, nonatomic) IBOutlet SCVideoPlayerView *friendVideoView;
@property (strong, nonatomic) NSMutableArray *videoPlayingObservedTimesArray;
@property (strong, nonatomic) NSMutableArray *compositionTimerObserverArray;
@property (weak, nonatomic) IBOutlet UIButton *replayButton;
@property (strong, nonatomic) NSTimer *downloadingStateTimer;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIView *metadataView;
@property (strong, nonatomic) UIView *playingProgressView;
@property (strong, nonatomic) UILongPressGestureRecognizer *playingProgressViewLongPressGesture;
@property (strong, nonatomic) AVAudioPlayer *whiteNoisePlayer;
@property (strong, nonatomic) UITapGestureRecognizer *videoTapGestureRecogniser;
@property (strong, nonatomic) NSArray *metadataColorArray;

// Recording
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
@property (weak, nonatomic) IBOutlet UILabel *unreadMessagesCountLabel;

@end

@implementation VideoViewController {
    BOOL _isExporting;
    BOOL _longPressRunning;
    BOOL _recordingRunning;
    BOOL _cancelRecording;
    int _metadataColorIndex;
}

// --------------------------------------------
#pragma mark - Life Cycle
// --------------------------------------------

- (void)viewDidLoad {
    [super viewDidLoad];

    [[UIApplication sharedApplication] setStatusBarHidden:YES];

    // Logic
    _isExporting = NO;
    _longPressRunning = NO;
    _recordingRunning = NO;
    _cancelRecording = NO;
    _metadataColorIndex = 0;
    self.isSendingCount = 0;
    self.unreadMessagesCountLabel.hidden = YES;
    
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
    
    // Create the recorder
    self.recorder = [SCRecorder recorder];
    _recorder.delegate = self;
    _recorder.device = AVCaptureDevicePositionBack;
     _recorder.autoSetVideoOrientation = NO;
    _recorder.maxRecordDuration = CMTimeMakeWithSeconds(kRecordSessionMaxDuration + kVideoEndCutDuration, 600);
    SCRecordSession *session = [SCRecordSession recordSession];
    session.fileType = AVFileTypeMPEG4;
    _recorder.session = session;
    
    // Preset
    _recorder.captureSessionPreset = [SCRecorderTools bestCaptureSessionPresetCompatibleWithAllDevices];
    _recorder.audioConfiguration.preset = SCPresetLowQuality;
    _recorder.videoConfiguration.preset = SCPresetMediumQuality;
    
    // Start running the flow of buffers
    if (![self.recorder startRunning]) {
        NSLog(@"Something wrong there: %@", self.recorder.error);
    }
    
    // Recording progress bar
    self.recordingProgressBar = [[UIView alloc] init];
    self.recordingProgressBar.backgroundColor = [UIColor whiteColor];
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
    self.unreadMessagesCountLabel.layer.cornerRadius = self.unreadMessagesCountLabel.frame.size.height / 2;
    self.unreadMessagesCountLabel.layer.borderWidth = 1;
    self.unreadMessagesCountLabel.layer.borderColor = [ColorUtils purple].CGColor;
    self.unreadMessagesCountLabel.textColor = [ColorUtils purple];
    self.unreadMessagesCountLabel.hidden = YES;
    
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
    _friends = [NSMutableArray new];
    [DatastoreUtils getFriendsFromLocalDatastoreAndExecuteSuccess:^(NSArray *friends) {
        [self setObjectsFromFriendsArray:friends]; // retrieve video in different number of friends
        
        // Get local videos
        self.allVideosArray = [NSMutableArray arrayWithArray:[DatastoreUtils getVideoLocallyFromUsers:self.friends]];
    } failure:nil];
    
    // Friend array
    self.failedVideoPostArray = [NSMutableArray new];
    
    // Start with camera
    [self setCameraMode];
    
    // Load address book, friends & video (if the result is different from cashing)
    self.contactDictionnary = [AddressbookUtils getContactDictionnary];
    self.addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    [self parseContactsAndFindFriends];
    
    // Retrieve unread messages
    [self retrieveUnreadMessages];
    
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
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(retrieveVideo)
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
}

- (void)willResignActive {
    [self setPlayingMode:NO];
    [self setCameraMode];
}

- (void)willBecomeActiveCallback {
    [self retrieveVideo];
    [self retrieveUnreadMessages];
    [self parseContactsAndFindFriends];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSString * segueName = segue.identifier;
    if ([segueName isEqualToString: @"Friends From Video"]) {
        [self hideUIElementOnCamera:YES];
        ((FriendsViewController *) [segue destinationViewController]).delegate = self;
        ((FriendsViewController *) [segue destinationViewController]).friends = self.friends;
    }
}

-(void)routeChangeCallback:(NSNotification*)notification {
    if ([self isPlayingMode]) {
        // To avoid pause when plug / unplug headset
        [self.friendVideoView.player play];
    }
}

- (void)navigateToFriends {
    [self.captionTextView resignFirstResponder];
    [self performSegueWithIdentifier:@"Friends From Video" sender:nil];
}

// --------------------------------------------
#pragma mark - Actions
// --------------------------------------------
- (void)handleLongPressGesture:(UILongPressGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateBegan) {
        if ([gesture locationInView:self.cameraView].y < 60) {
            return; // don't start if we press above
        }
        if (!_isExporting) {
            _longPressRunning = YES;
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
        [self showMetaData:NO];
        [self.friendVideoView.player pause];
        [self.whiteNoisePlayer pause];
        [self.friendVideoView.player seekToTime:time];
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        [self.friendVideoView.player seekToTime:time];
    } else {
        // Set metadata
        CMTime observedTime;
        for (NSValue *observedValue in [self.videoPlayingObservedTimesArray reverseObjectEnumerator]) {
            [observedValue getValue:&observedTime];
            if (CMTIME_COMPARE_INLINE(time, >, observedTime)) {
                [self setPlayingMetaDataForVideoPost:self.videosToPlayArray[[self.videoPlayingObservedTimesArray indexOfObject:observedValue]]];
                break;
            }
        }
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
        [TrackingUtils trackReplayButtonClicked];
    }
}

- (IBAction)flipCameraButtonClicked:(id)sender {
    self.recorder.device = self.recorder.device == AVCaptureDevicePositionBack ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack;
    [GeneralUtils saveLastVideoSelfieModePref:(self.recorder.device == AVCaptureDevicePositionFront)];
}

- (IBAction)friendsButtonClicked:(id)sender {
    [self navigateToFriends];
}

- (IBAction)captionButtonClicked:(id)sender {
    self.longPressGestureRecogniser.minimumPressDuration = 0.5;
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
    int ii = 0;
    CMTime playerTime = self.friendVideoView.player.currentTime;
    CMTime gapPlayerTime = CMTimeAdd(playerTime, CMTimeMakeWithSeconds(0.02, 600));
    for (NSValue *observedValue in self.videoPlayingObservedTimesArray) {
        if (observedValue == self.videoPlayingObservedTimesArray.lastObject) {
            [self returnToCameraMode];
        } else {
            [observedValue getValue:&observedTime];
            if (CMTIME_COMPARE_INLINE(gapPlayerTime, <, observedTime)) {
                // Set metadata
                [self setPlayingMetaDataForVideoPost:self.videosToPlayArray[ii]];
                
                [self.friendVideoView.player seekToTime:observedTime toleranceBefore:CMTimeMake(100, 600) toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
                    CGFloat videoDuration = CMTimeGetSeconds(self.friendVideoView.player.currentItem.duration);
                    CGFloat currentTime = CMTimeGetSeconds(observedTime);
                    [self.playingProgressView.layer removeAllAnimations];
                    [self.playingProgressView setFrame:CGRectMake(0, 0, currentTime / videoDuration * self.metadataView.frame.size.width, self.metadataView.frame.size.height)];
                    [self animatePlayingProgressBar:videoDuration - currentTime];
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
- (void)retrieveVideo {
    [ApiManager getVideoFromFriends:self.friends
                             success:^(NSArray *posts) {
                                 [self setVideoArray:posts];
                             } failure:nil];
}

- (void)setVideoArray:(NSArray *)videoPostArray {
    self.allVideosArray = [NSMutableArray arrayWithArray:videoPostArray];
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
- (void)setObjectsFromFriendsArray:(NSArray *)friends {
    NSUInteger previousCount = _friends ? _friends.count : 0;
    [_friends removeAllObjects];
    [_friends addObjectsFromArray:friends];
    if ([_friends indexOfObject:[User currentUser]] != NSNotFound) {
        [_friends removeObjectAtIndex:[_friends indexOfObject:[User currentUser]]];
    }
    [_friends insertObject:[User currentUser] atIndex:0];
    
    if (previousCount != friends.count) {
        [self retrieveVideo];
    }
}

- (void)parseContactsAndFindFriends {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        ABAddressBookRequestAccessWithCompletion(self.addressBook, ^(bool granted, CFErrorRef error) {
            if (granted) {
                NSMutableDictionary *contactDictionnary = [AddressbookUtils getFormattedPhoneNumbersFromAddressBook:self.addressBook];
                [contactDictionnary setObject:[User currentUser].flashUsername forKey:[User currentUser].username];
                
                // fill following table
                [ApiManager fillFollowersTableWithUsers:[contactDictionnary allKeys]
                                                success:^(NSArray *friends) {
                                                    [self setObjectsFromFriendsArray:friends];
                                                } failure:nil];
                
                [contactDictionnary removeObjectForKey:[User currentUser].username];
                [AddressbookUtils saveContactDictionnary:contactDictionnary];
            }
        });
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
    if (![self.nameLabel.text isEqualToString:[NSString stringWithFormat:@" %@  ",post.user.flashUsername]]) {
        _metadataColorIndex ++;
        if (_metadataColorIndex >= self.metadataColorArray.count) {
            _metadataColorIndex = 0;
        }
    }
    
    self.nameLabel.text = [NSString stringWithFormat:@" %@  ",post.user.flashUsername];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm"];
    NSString *stringDate = [dateFormatter stringFromDate:post.recordedAt];
    self.timeLabel.text = stringDate;
    
    // Color
    self.nameLabel.backgroundColor = self.metadataColorArray[_metadataColorIndex];
    
    // Show metadata
    [self showMetaData:YES];
    
    // Update viewer ids
    [post addUniqueObject:[User currentUser].objectId forKey:@"viewerIdsArray"];
    
    // Track
    [TrackingUtils trackVideoSeen];
}

- (void)showMetaData:(BOOL)flag {
    self.nameLabel.hidden = !flag;
    self.timeLabel.hidden = !flag;
}

- (void)returnToCameraMode {
    [self setCameraMode];
    [ApiManager updateVideoPosts:self.videosToPlayArray];
}


// --------------------------------------------
#pragma mark - Recording
// --------------------------------------------

- (void)startRecording {
    _recordingRunning = YES;
    [self.recorder.session removeAllSegments];
    [self setRecordingMode];
    [self.recorder record];
}

- (void)recorder:(SCRecorder *)recorder didCompleteSession:(SCRecordSession *)recordSession {
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
        }];
    }];
}

// Export
- (void)exportRecordingAndExecuteSuccess:(void(^)(VideoPost *))successBlock
                                 failure:(void(^)())failureBlock
{
    SCRecordSession *recordSession = self.recorder.session;
    if (CMTimeGetSeconds(recordSession.segmentsDuration) < kRecordMinDuration) {
        if (CMTimeGetSeconds(recordSession.segmentsDuration) != 0) // to avoid pb segment not ready
            [GeneralUtils displayTopMessage:NSLocalizedString(@"video_too_short", nil) onView:self.view];
        if (failureBlock)
            failureBlock();
        NSLog(@"too short");
    } else {
        AVAsset *asset = recordSession.assetRepresentingSegments;
        SCAssetExportSession *exporter = [[SCAssetExportSession alloc] initWithAsset:asset];
        exporter.outputUrl = recordSession.outputUrl;
        exporter.outputFileType = AVFileTypeMPEG4;
        exporter.videoConfiguration.preset = SCPresetMediumQuality;
        exporter.audioConfiguration.preset = SCPresetMediumQuality;
        AVAssetTrack *videoAssetTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
        exporter.videoConfiguration.watermarkImage = [self getImageFromCaption];
        exporter.videoConfiguration.watermarkFrame = CGRectMake(0,0,videoAssetTrack.naturalSize.width,videoAssetTrack.naturalSize.height);

        [exporter exportAsynchronouslyWithCompletionHandler: ^{
            if (exporter.error == nil) {
                VideoPost *post = [VideoPost createPostWithRessourceUrl:recordSession.outputUrl];
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


// --------------------------------------------
#pragma mark - Sending
// --------------------------------------------
- (void)sendVideoPost:(VideoPost *)post
{
    self.isSendingCount ++;
    [ApiManager saveVideoPost:post
            andExecuteSuccess:^() {
                self.isSendingCount --;
                [self.allVideosArray addObject:post];
                [self.allVideosArray sortUsingComparator:^NSComparisonResult(VideoPost *obj1, VideoPost *obj2) {
                    return [obj1.recordedAt compare:obj2.recordedAt];
                }];
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


// ------------------------------
#pragma mark Message
// ------------------------------
- (void)retrieveUnreadMessages {
    [ApiManager retrieveUnreadMessagesAndExecuteSuccess:^(NSArray *messagesArray) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"retrieve_message_locally"
                                                            object:nil
                                                          userInfo:nil];
        [self setMessagesLabel:messagesArray.count];
    } failure:nil];
}

- (void)setMessagesLabel:(NSInteger)count {
    if (count > 0) {
        [self.friendListButton setTitle:[NSString stringWithFormat:@"%lu",(long)count] forState:UIControlStateNormal];
        [self.friendListButton setBackgroundImage:nil forState:UIControlStateNormal];
    } else {
        [self.friendListButton setBackgroundImage:[UIImage imageNamed:@"friends_button"] forState:UIControlStateNormal];
        [self.friendListButton setTitle:nil forState:UIControlStateNormal];

    }
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
    [self setPlayingMode:NO];
    [self endPreviewMode];
    
    [self hideUIElementOnCamera:YES];
    
    // Show caption on camera
    self.captionTextView.hidden = (self.captionTextView.text.length == 0);
    
    // Start UI + progress bar anim
    self.recordingProgressContainer.hidden = NO;
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
    } else {
        // Replay or new state
        NSMutableArray *unseenVideos = [self unseenVideosArray];
        NSInteger unseenCount = unseenVideos.count;
        NSString *buttonTitle;
        if (unseenCount == 0) {
            self.replayButton.backgroundColor = [ColorUtils black];
            buttonTitle = [NSString stringWithFormat:NSLocalizedString(@"replay_label", nil)];
        } else {
            self.replayButton.backgroundColor = [ColorUtils purple];
            buttonTitle = [NSString stringWithFormat:@"%lu %@",(long)unseenCount,unseenCount < 2 ? NSLocalizedString(@"new_video_label", nil) : NSLocalizedString(@"new_videos_label", nil)];
        }
        [self.replayButton setTitle:buttonTitle forState:UIControlStateNormal];
        self.replayButton.hidden = NO;
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
        self.unreadMessagesCountLabel.hidden = YES;
        self.replayButton.hidden = YES;
        self.recordTutoLabel.hidden = YES;
        self.captionTextView.hidden = YES;
    } else {
        self.unreadMessagesCountLabel.hidden = [self.unreadMessagesCountLabel.text isEqualToString:@"0"];
        [self setReplayButtonUI];
        self.captionTextView.hidden = (self.captionTextView.text.length == 0);
        self.recordTutoLabel.hidden = !(self.captionTextView.text.length == 0);
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
- (void)handleTapToCloseCaption {
    [self.captionTextView resignFirstResponder];
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


@end
