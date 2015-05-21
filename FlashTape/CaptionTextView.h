//
//  CaptionTextView.h
//  FlashTape
//
//  Created by Baptiste Truchot on 5/19/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//

@import Foundation;
@import UIKit;

@protocol CaptionTextViewProtocol;

@interface CaptionTextView : UITextView <UIGestureRecognizerDelegate>

@property (weak, nonatomic) id<CaptionTextViewProtocol> captionDelegate;

@end

@protocol CaptionTextViewProtocol <NSObject>

- (void)gestureOnCaptionDetected;

@end


