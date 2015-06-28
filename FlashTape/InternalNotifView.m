//
//  InternalNotifView.m
//  FlashTape
//
//  Created by Baptiste Truchot on 6/28/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//

#import "InternalNotifView.h"

#import "ConstantUtils.h"

@interface InternalNotifView()

@property (strong, nonatomic) NSTimer *expirationTimer;
@property (strong, nonatomic) NSString *userId;
@property (weak, nonatomic) IBOutlet UILabel *notifLabel;

@end

@implementation InternalNotifView

- (void)initWithType:(NSString *)type frame:(CGRect)frame userId:(NSString *)userId alert:(NSString *)alert
{
    self.frame = frame;
    self.userId = userId;
    self.notifLabel.text = alert;
    self.notifLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.notifLabel.numberOfLines = 0;
    
    self.expirationTimer = [NSTimer scheduledTimerWithTimeInterval:kInternalNotifDuration target:self selector:@selector(notifExpired) userInfo:nil repeats:NO];
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(notifClicked)];
    [self addGestureRecognizer:tapGesture];
    
    UISwipeGestureRecognizer *swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(notifExpired)];
    swipeGesture.direction = UISwipeGestureRecognizerDirectionUp;
    [self addGestureRecognizer:swipeGesture];
}

// Navigate to chat
- (void)notifClicked {
    // notification
    [[NSNotificationCenter defaultCenter] postNotificationName:@"new_message_clicked"
                                                        object:nil
                                                      userInfo:nil];
    [self removeFromSuperview];
}

// Remove notif
- (void)notifExpired {
    [UIView animateWithDuration:kNotifAnimationDuration
                     animations:^(){
                         self.frame = CGRectMake(0, - kInternalNotifHeight, self.frame.size.width, kInternalNotifHeight);
                     } completion:^(BOOL completed) {
                         [self removeFromSuperview];
                     }];
}

@end
