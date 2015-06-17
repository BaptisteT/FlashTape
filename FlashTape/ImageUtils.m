//
//  ImageUtils.m
//  FlashTape
//
//  Created by Baptiste Truchot on 6/17/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//

#import "ImageUtils.h"

@implementation ImageUtils

+ (CAShapeLayer *)createGradientCircleLayerWithFrame:(CGRect)frame
                                         borderWidth:(NSInteger)borderWidth
                                               Color:(UIColor *)color
                                        subDivisions:(NSInteger)nbSubDivisions
{
    CGPoint center = CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame));
    CGFloat red, green, blue, alpha, subAlpha = 0, startAngle = 0, endAngle = DEGREES_TO_RADIANS(360)/nbSubDivisions;
    [color getRed:&red green:&green blue:&blue alpha:&alpha];
    
    CAShapeLayer *containingLayer = [CAShapeLayer new];
    containingLayer.frame = frame;
    
    for (int i=0; i<nbSubDivisions; i++) {
        CAShapeLayer *subLayer = [CAShapeLayer new];
        subLayer.frame = frame;
        subLayer.fillColor = [UIColor clearColor].CGColor;
        subLayer.lineWidth = borderWidth;
        subLayer.strokeColor = [UIColor colorWithRed:red green:green blue:blue alpha:subAlpha].CGColor;
        
        subLayer.path = [UIBezierPath bezierPathWithArcCenter:center
                                                       radius:frame.size.width/2 + 4
                                                   startAngle:startAngle
                                                     endAngle:endAngle
                                                    clockwise:YES].CGPath;
        [containingLayer addSublayer:subLayer];
        
        // Prepare next subdiv
        subAlpha += alpha / nbSubDivisions;
        startAngle = endAngle;
        endAngle += DEGREES_TO_RADIANS(180)/nbSubDivisions;
    }
    return containingLayer;
}

@end
