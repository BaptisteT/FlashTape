//
//  InternalNotifView.h
//  FlashTape
//
//  Created by Baptiste Truchot on 6/28/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface InternalNotifView : UIView

- (void)initWithType:(NSString *)type frame:(CGRect)frame userId:(NSString *)userId alert:(NSString *)alert;

@end
