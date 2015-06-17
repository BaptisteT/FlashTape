//
//  ImageUtils.h
//  FlashTape
//
//  Created by Baptiste Truchot on 6/17/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//
@import Foundation;
@import UIKit;

#define DEGREES_TO_RADIANS(x) (x)/180.0*M_PI
#define RADIANS_TO_DEGREES(x) (x)/M_PI*180.0

@interface ImageUtils : NSObject

+ (CAShapeLayer *)createGradientCircleLayerWithFrame:(CGRect)frame
                                         borderWidth:(NSInteger)borderWidth
                                               Color:(UIColor *)color
                                        subDivisions:(NSInteger)nbSubDivisions;
@end
