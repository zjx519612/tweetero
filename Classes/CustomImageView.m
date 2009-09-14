//
//  CustomImageView.m
//  Tweetero
//
//  Created by Sergey Shkrabak on 9/14/09.
//  Copyright 2009 Codeminders. All rights reserved.
//

#import "CustomImageView.h"

@implementation CustomImageView

@synthesize image;

- (id)initWithFrame:(CGRect)frame 
{
    if (self = [super initWithFrame:frame]) 
    {
        // Initialization code
        self.image = nil;
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    // Drawing code
    float radius = 5.0f;

    CGContextRef context = UIGraphicsGetCurrentContext();
    //rect = CGRectInset(rect, 1.0f, 1.0f);
    
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, CGRectGetMinX(rect) + radius, CGRectGetMinY(rect));
    CGContextAddArc(context, CGRectGetMaxX(rect) - radius, CGRectGetMinY(rect) + radius, radius, 3 * M_PI / 2, 0, 0);
    CGContextAddArc(context, CGRectGetMaxX(rect) - radius, CGRectGetMaxY(rect) - radius, radius, 0, M_PI / 2, 0);
    CGContextAddArc(context, CGRectGetMinX(rect) + radius, CGRectGetMaxY(rect) - radius, radius, M_PI / 2, M_PI, 0);
    CGContextAddArc(context, CGRectGetMinX(rect) + radius, CGRectGetMinY(rect) + radius, radius, M_PI, 3 * M_PI / 2, 0);
    CGContextClosePath(context);
    CGContextClip(context);
    
    // Draw image
    if (self.image)
        [self.image drawAtPoint:CGPointMake(0, 0)];
}


- (void)dealloc 
{
    [image autorelease];
    [super dealloc];
}

- (void)setImage:(UIImage *)theImage
{
    [image autorelease];
    image = [theImage retain];
    [self setNeedsDisplay];
}

@end
