//
//  SimplePaintView.h
//  SimplePaint
//
//  Created by Ben Gotow on 10/12/12.
//  Copyright (c) 2012 Ben Gotow. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef struct Transforms {
    float x;
    float y;
    float zoom;
} Transforms;

@interface SimplePaintView : UIView
{
    Transforms _camera;
    Transforms _pending;
    
    CGImageRef _brushStamp;
    CGLayerRef _brushLayer;
    
    CGImageRef  _sourceImage;
    
    CGPoint _previousLocationInView;
}

- (IBAction)zoomed:(UIGestureRecognizer*)recognizer;
- (IBAction)panned:(UIGestureRecognizer*)recognizer;
- (IBAction)stroked:(UIGestureRecognizer*)recognizer;

- (void)strokedToPoint:(CGPoint)point;

@end
