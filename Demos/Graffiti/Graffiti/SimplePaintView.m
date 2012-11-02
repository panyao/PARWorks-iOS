//
//  SimplePaintView.m
//  SimplePaint
//
//  Created by Ben Gotow on 10/12/12.
//  Copyright (c) 2012 Ben Gotow. All rights reserved.
//

#import "SimplePaintView.h"
#import <QuartzCore/QuartzCore.h>

#define NO_PREVIOUS -1

@implementation SimplePaintView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)awakeFromNib
{
    [self setup];
}

- (void)setup
{
    _camera.zoom = 1;
    _pending.zoom = 1;
    _previousLocationInView.x = NO_PREVIOUS;
    [[self layer] setDrawsAsynchronously: YES];
}

- (void)setImage:(UIImage*)img
{
    _sourceImage = [img CGImage];
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef c = UIGraphicsGetCurrentContext();
    
    if (_brushLayer == nil)
        _brushLayer = CGLayerCreateWithContext(c, CGSizeMake(rect.size.width * [[UIScreen mainScreen] scale], rect.size.height * [[UIScreen mainScreen] scale]), NULL);
    
    CGSize size = [self bounds].size;
    CGContextTranslateCTM(c, -size.width / 2, -size.height / 2);
    CGContextScaleCTM(c, _camera.zoom * _pending.zoom, _camera.zoom * _pending.zoom);
    CGContextTranslateCTM(c, _camera.x + _pending.x, _camera.y + _pending.y);
    CGContextTranslateCTM(c, size.width / 2, size.height / 2);
    
    if (_sourceImage)
        CGContextDrawImage(c, self.bounds, _sourceImage);
    CGContextDrawLayerInRect(c, self.bounds, _brushLayer);
}

- (IBAction)zoomed:(UIPinchGestureRecognizer*)recognizer
{
    _pending.zoom = [recognizer scale];
    
    if ([recognizer state] == UIGestureRecognizerStateEnded) {
        _camera.zoom *= _pending.zoom;
        _pending.zoom = 1;
    }

    [self setNeedsDisplay];
}

- (IBAction)panned:(UIPanGestureRecognizer*)recognizer
{
    CGPoint t = [recognizer translationInView: self];
    _pending.x = t.x;
    _pending.y = t.y;
    
    if ([recognizer state] == UIGestureRecognizerStateEnded) {
        _camera.x += _pending.x;
        _camera.y += _pending.y;
        _pending.x = 0;
        _pending.y = 0;
    }
    
    [self setNeedsDisplay];
}

static float f = 0;

- (void)strokedToPoint:(CGPoint)point
{
    CGContextRef c = CGLayerGetContext(_brushLayer);
    
    // Step 1: Determine the point onscreen  we are currently touching,
    // compute the brush radius.
    int steps = 1;
    float radius = 32 / [[UIScreen mainScreen] scale];
    CGPoint center = point;
    center.x *= [[UIScreen mainScreen] scale];
    center.y *= [[UIScreen mainScreen] scale];
    
    // Step 2: Find out how far the brush has travelled since our last touch event
    CGPoint diff = CGPointMake(center.x - _previousLocationInView.x, center.y - _previousLocationInView.y);
    
    // If this is not the first touch event, let's compute a number of stamps to make
    // between the old touch point and the new touch point
    if (_previousLocationInView.x != NO_PREVIOUS)
        steps = ceilf(sqrtf(powf(diff.y, 2) + powf(diff.x, 2))) / 6;
    
    CGPoint step = CGPointMake(diff.x / steps, diff.y / steps);
    CGRect dirtyRect = CGRectZero;
//    float a = 1.0 - sqrtf((float)steps) * 0.125;
    
    // Step 3: Draw a stamp at each step along the way from the old touch point to the
    // new touch point
    for (int s = 0; s < steps; s ++) {
        _previousLocationInView.x += step.x;
        _previousLocationInView.y += step.y;
        
        CGRect r = CGRectMake(_previousLocationInView.x - radius, _previousLocationInView.y - radius, radius * 2, radius * 2);
        CGContextSetRGBFillColor(c, 1, 1, 1, 1);
        CGContextSaveGState(c);
        CGContextClipToMask(c, r, [[UIImage imageNamed: @"brush_1_texture.png"] CGImage]);
        CGContextFillRect(c, r);
        CGContextRestoreGState(c);
        
        dirtyRect = (s == 0) ? r : CGRectUnion(dirtyRect, r);
    }
    
    // Step 4: If this is the last touch event, reset our previous location
//    if ([recognizer state] == UIGestureRecognizerStateEnded)
//        _previousLocationInView.x = NO_PREVIOUS;
    [self setNeedsDisplayInRect: self.bounds];
}


- (IBAction)stroked:(UIPanGestureRecognizer*)recognizer
{
    f += 0.01;
    
    CGContextRef c = CGLayerGetContext(_brushLayer);
    
    // Step 1: Determine the point onscreen  we are currently touching,
    // compute the brush radius.
    int steps = 1;
    float radius = 32 / [[UIScreen mainScreen] scale];
    CGPoint center = [recognizer locationInView: self];
    center.x *= [[UIScreen mainScreen] scale];
    center.y *= [[UIScreen mainScreen] scale];
    
    // Step 2: Find out how far the brush has travelled since our last touch event
    CGPoint diff = CGPointMake(center.x - _previousLocationInView.x, center.y - _previousLocationInView.y);

    // If this is not the first touch event, let's compute a number of stamps to make
    // between the old touch point and the new touch point
    if (_previousLocationInView.x != NO_PREVIOUS)
        steps = ceilf(sqrtf(powf(diff.y, 2) + powf(diff.x, 2))) / 6;

    CGPoint step = CGPointMake(diff.x / steps, diff.y / steps);
    CGRect dirtyRect = CGRectZero;
    float a = 1.0 - sqrtf((float)steps) * 0.125;
    
    // Step 3: Draw a stamp at each step along the way from the old touch point to the
    // new touch point
    for (int s = 0; s < steps; s ++) {
        _previousLocationInView.x += step.x;
        _previousLocationInView.y += step.y;

        CGRect r = CGRectMake(_previousLocationInView.x - radius, _previousLocationInView.y - radius, radius * 2, radius * 2);
        CGContextSetRGBFillColor(c, 1-f, f, 0, a);
        CGContextSaveGState(c);
        CGContextClipToMask(c, r, [[UIImage imageNamed: @"brush_1_texture.png"] CGImage]);
        CGContextFillRect(c, r);
        CGContextRestoreGState(c);
        
        dirtyRect = (s == 0) ? r : CGRectUnion(dirtyRect, r);
    }
    
    // Step 4: If this is the last touch event, reset our previous location
    if ([recognizer state] == UIGestureRecognizerStateEnded)
        _previousLocationInView.x = NO_PREVIOUS;
    
    [self setNeedsDisplayInRect: self.bounds];
}

@end
