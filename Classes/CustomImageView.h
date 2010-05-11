//
//  CustomImageView.h
//  Tweetero
//
//  Created by Sergey Shkrabak on 9/14/09.
//  Copyright 2009 Codeminders. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    CIDefaultFrameType,
    CIRoudrectFrameType
} CustomImageViewFrameType;

@interface CustomImageView : UIView
{
    UIImage *image;
    int frameType;
}

@property (nonatomic, retain) UIImage* image;
@property (nonatomic) int frameType;

@end
