//
//  GeneralUtils.h
//  FlashTape
//
//  Created by Baptiste Truchot on 4/27/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//

@import Foundation;
@import UIKit;

@interface GeneralUtils : NSObject

+ (void)saveLastVideoSeenDate:(NSDate *)date;

+ (NSDate *)getLastVideoSeenDate;

+ (UIImage *)generateThumbImage:(NSURL *)url;

@end
