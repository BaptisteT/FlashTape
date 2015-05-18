//
//  UICustomLineLabel.m
//  UILineLableDemo
//
//  Created by myanycam on 2014/2/25.
//  Copyright (c) 2014年 myanycam. All rights reserved.
//

#import "UICustomLineLabel.h"

@implementation UICustomLineLabel

- (void)dealloc{
    
    self.lineColor = nil;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/


- (void)drawTextInRect:(CGRect)rect{
    [super drawTextInRect:rect];
    
    CGSize textSize = [[self text] sizeWithAttributes:@{NSFontAttributeName: [self font]}];
    CGFloat strikeWidth = textSize.width;
    CGFloat strikeHeight = self.lineHeight;
    CGRect lineRect;
    CGFloat origin_x;
    CGFloat origin_y = 0;
    
    if ([self textAlignment] == NSTextAlignmentRight) {
        
        origin_x = rect.size.width - strikeWidth;
        
    } else if ([self textAlignment] == NSTextAlignmentCenter) {
        
        origin_x = (rect.size.width - strikeWidth)/2 ;
        
    } else {
        
        origin_x = 0;
    }
    
    
    if (self.lineType == LineTypeUp) {
        
        origin_y =  2;
    }
    
    if (self.lineType == LineTypeMiddle) {
        
        origin_y =  rect.size.height/2;
    }
    
    if (self.lineType == LineTypeDown) {
        
        origin_y = rect.size.height - strikeHeight;
    }
    
    lineRect = CGRectMake(origin_x , origin_y, strikeWidth, strikeHeight);
    
    if (self.lineType != LineTypeNone) {
        
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGFloat R, G, B, A;
        UIColor *uiColor = self.lineColor;
        CGColorRef color = [uiColor CGColor];
        int numComponents = (int)CGColorGetNumberOfComponents(color);
        
        if( numComponents == 4)
        {
            const CGFloat *components = CGColorGetComponents(color);
            R = components[0];
            G = components[1];
            B = components[2];
            A = components[3];
            
            CGContextSetRGBFillColor(context, R, G, B, 1.0);

        }
        
        CGContextFillRect(context, lineRect);
    }
}




@end
