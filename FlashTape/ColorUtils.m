//
//  ColorUtils.m
//  FlashTape
//
//  Created by Baptiste Truchot on 5/6/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//

#import "ColorUtils.h"

@implementation ColorUtils

+ (UIColor *)navigationBarColor {
    return [UIColor colorWithRed:255./255. green:129./255. blue:0 alpha:1.0];
}

+ (UIColor *)black {
    return [UIColor colorWithRed:15./255. green:15./255. blue:15./255. alpha:1];
}

+ (UIColor *)transparentOrange {
    return [UIColor colorWithRed:1 green:129./255. blue:0 alpha:0.5];
}

+ (UIColor *)transparentRed {
    return [UIColor colorWithRed:1 green:0. blue:0 alpha:0.5];
}

+ (UIColor *)transparentGreen {
    return [UIColor colorWithRed:0 green:1. blue:0 alpha:0.5];
}

+ (UIColor *)purple {
    return [UIColor colorWithRed:145./255 green:77./255. blue:255./255. alpha:1];
}

+ (UIColor *)pink {
    return [UIColor colorWithRed:255./255 green:57./255. blue:99./255. alpha:1];
}

+ (UIColor *)blue {
    return [UIColor colorWithRed:57./255 green:183./255. blue:255./255. alpha:1];
}

+ (UIColor *)green {
    return [UIColor colorWithRed:57./255 green:255./255. blue:178./255. alpha:1];
}

+ (UIColor *)orange {
    return [UIColor colorWithRed:255./255 green:118./255. blue:57./255. alpha:1];
}


@end
