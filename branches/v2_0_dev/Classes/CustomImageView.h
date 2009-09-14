//
//  CustomImageView.h
//  Tweetero
//
//  Created by Sergey Shkrabak on 9/14/09.
//  Copyright 2009 Codeminders. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CustomImageView : UIView
{
    UIImage *image;
}

@property (nonatomic, retain) UIImage *image;

@end