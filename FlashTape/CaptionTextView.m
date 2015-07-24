//
//  CaptionTextView.m
//  FlashTape
//
//  Created by Baptiste Truchot on 5/19/15.
//  Copyright (c) 2015 Mindie. All rights reserved.
//

#import "CaptionTextView.h"

@interface CaptionTextView()

@property (nonatomic, strong) UIPinchGestureRecognizer *pinchRecognizer;
@property (nonatomic, strong) UIRotationGestureRecognizer *rotationRecognizer;
@property (nonatomic, strong) UIPanGestureRecognizer *panningRecognizer;
@property (nonatomic, strong) NSMutableSet *activeRecognizers;
@property(nonatomic) CGAffineTransform referenceTransform;

@end


@implementation CaptionTextView

// -------------------
// Life Cycle
// ------------------
- (id)initWithFrame:(CGRect)frame {
     if (self = [super initWithFrame:frame])
     {
         // Add gesture recognisers
         self.pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
         self.rotationRecognizer = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
         self.panningRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanningGesture:)];
         
         [self addGestureRecognizer:self.pinchRecognizer];
         [self addGestureRecognizer:self.rotationRecognizer];
         [self addGestureRecognizer:self.panningRecognizer];
         
         self.pinchRecognizer.delegate = self;
         self.rotationRecognizer.delegate = self;
         self.panningRecognizer.delegate = self;
         self.activeRecognizers = [NSMutableSet set];
         
         // User interaction
         self.userInteractionEnabled = YES;
         self.multipleTouchEnabled = YES;
         self.exclusiveTouch = YES;
         self.clipsToBounds = NO;
         self.layer.masksToBounds = NO;
         
         // UI
         self.scrollEnabled = NO;
         self.bounces = NO;
         self.font = [UIFont fontWithName:@"NHaasGroteskDSPro-75Bd" size:50.0];
         self.tintColor = [UIColor whiteColor];
         self.textColor = [UIColor whiteColor];
         self.textAlignment = NSTextAlignmentCenter;
         self.backgroundColor = [UIColor clearColor];
         self.autocorrectionType = UITextAutocorrectionTypeNo;
     }
    return self;
}

// -------------------
// Gesture handling
// ------------------

- (void)handleGesture:(UIGestureRecognizer *)recognizer
{
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan:
            if (self.activeRecognizers.count == 0)
                self.referenceTransform = self.transform;
            [self.activeRecognizers addObject:recognizer];
            break;
            
        case UIGestureRecognizerStateChanged: {
            CGAffineTransform transform = self.referenceTransform;
            CGAffineTransform scaleTransform = self.referenceTransform;
            for (UIGestureRecognizer *recognizer in self.activeRecognizers) {
                transform = [self applyRecognizer:recognizer toTransform:transform];
                if ([recognizer isKindOfClass:[UIPinchGestureRecognizer class]]) {
                    scaleTransform = [self applyRecognizer:recognizer toTransform:scaleTransform];
                }
            }
            self.transform = transform;
            break;
        }
            
            
        case UIGestureRecognizerStateEnded:
            self.referenceTransform = [self applyRecognizer:recognizer toTransform:self.referenceTransform];
            [self.activeRecognizers removeObject:recognizer];
            break;
            
        default:
            break;
    }
}

- (void)handlePanningGesture:(UIPanGestureRecognizer *)recognizer
{
    static CGPoint initialCenter;
    if (recognizer.state == UIGestureRecognizerStateBegan)
    {
        initialCenter = recognizer.view.center;
    }
    CGPoint translation = [recognizer translationInView:recognizer.view.superview];
    recognizer.view.center = CGPointMake(initialCenter.x + translation.x,
                                         initialCenter.y + translation.y);
}

- (CGAffineTransform)applyRecognizer:(UIGestureRecognizer *)recognizer toTransform:(CGAffineTransform)transform
{
    if ([recognizer respondsToSelector:@selector(rotation)]) {
        return CGAffineTransformRotate(transform, [(UIRotationGestureRecognizer *)recognizer rotation]);
    } else if ([recognizer respondsToSelector:@selector(scale)]) {
        CGFloat scale = [(UIPinchGestureRecognizer *)recognizer scale];
        return CGAffineTransformScale(transform, scale, scale);
    }
    else
        return transform;
}

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    // if the gesture recognizers's view isn't one of our views, don't allow simultaneous recognition
    if (gestureRecognizer.view != self && otherGestureRecognizer.view != self)
        return NO;
    // if the gesture recognizers are on different views, don't allow simultaneous recognition
    if (gestureRecognizer.view != otherGestureRecognizer.view)
        return NO;
    if (![gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]] && ![gestureRecognizer isKindOfClass:[UIRotationGestureRecognizer class]] && ![gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]])
        return NO;
    if (![otherGestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]] && ![otherGestureRecognizer isKindOfClass:[UIRotationGestureRecognizer class]] && ![otherGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]])
        return NO;
    return YES;
}


@end
