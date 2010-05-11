//
//  CustomImageView.m
//  Tweetero
//
//  Created by Sergey Shkrabak on 9/14/09.
//  Copyright 2009 Codeminders. All rights reserved.
//

#import "CustomImageView.h"
#import "ImageLoader.h"
#import "util.h"

@implementation CustomImageView

@synthesize image;
@synthesize frameType;

- (id)initWithFrame:(CGRect)frame 
{
    if (self = [super initWithFrame:frame]) 
    {
        // Initialization code
        self.frameType = CIRoudrectFrameType;
        self.image = nil;
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    // Drawing code
    
    if (self.frameType == CIRoudrectFrameType)
    {
        float radius = 5.0f;

        CGContextRef context = UIGraphicsGetCurrentContext();
        
        CGContextBeginPath(context);
        CGContextMoveToPoint(context, CGRectGetMinX(rect) + radius, CGRectGetMinY(rect));
        CGContextAddArc(context, CGRectGetMaxX(rect) - radius, CGRectGetMinY(rect) + radius, radius, 3 * M_PI / 2, 0, 0);
        CGContextAddArc(context, CGRectGetMaxX(rect) - radius, CGRectGetMaxY(rect) - radius, radius, 0, M_PI / 2, 0);
        CGContextAddArc(context, CGRectGetMinX(rect) + radius, CGRectGetMaxY(rect) - radius, radius, M_PI / 2, M_PI, 0);
        CGContextAddArc(context, CGRectGetMinX(rect) + radius, CGRectGetMinY(rect) + radius, radius, M_PI, 3 * M_PI / 2, 0);
        CGContextClosePath(context);
        CGContextClip(context);
    }
    
    // Draw image
    if (self.image)
        [self.image drawAtPoint:CGPointMake(0, 0)];
}


- (void)dealloc 
{
    if (image)
        [image release];
    [super dealloc];
}

- (void)setImage:(UIImage *)theImage
{
    if (image)
        [image release];
    image = [theImage retain];
    [self setNeedsDisplay];
}

- (void)setFrameType:(int)ftype
{
    frameType = ftype;
    [self setNeedsDisplay];
}

@end
