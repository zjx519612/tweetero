//
//  UserInfoView.m
//  Tweetero
//
//  Created by Sergey Shkrabak on 9/24/09.
//  Copyright 2009 Codeminders. All rights reserved.
//

#import "UserInfoView.h"
#import "CustomImageView.h"

const int kHeadTagAvatar = 1;
const int kHeadTagUserName = 2;
const int kHeadTagScreenName = 3;
const int kHeadTagLocation = 4;

@interface UserInfoView (Private)

- (void)createViewControls;
- (void)updateView;

@end


@implementation UserInfoView

@synthesize username;
@synthesize screenname;
@synthesize location;
@synthesize avatar;
@synthesize follow;
@synthesize buttons;
@synthesize delegate;

- (id)initWithFrame:(CGRect)frame 
{
    if (self = [super initWithFrame:frame]) 
    {
        [self createViewControls];
        self.delegate = nil;
        self.follow = NO;
    }
    return self;
}

- (void)drawRect:(CGRect)rect 
{
    [super drawRect:rect];
}

- (void)dealloc 
{
    [username release];
    [screenname release];
    [location release];
    [avatar release];
    if (self.delegate)
    {
        //[(id)self.delegate release];
        self.delegate = nil;
    }
    [detailButton release];
    [super dealloc];
}

#pragma mark Property implementation
- (void)setUsername:(NSString *)name
{
    UILabel *label = (UILabel*)[self viewWithTag:kHeadTagUserName];
    
    if (self.username)
        [username release];
    username = [[NSString alloc] initWithString:name];
    
    label.text = self.username;
    [self updateView];
}

- (void)setScreenname:(NSString *)name
{
    UILabel *label = (UILabel*)[self viewWithTag:kHeadTagScreenName];
    
    if (self.screenname)
        [screenname release];
    screenname = [[NSString alloc] initWithString:name];
    
    label.text = self.screenname;
    [self updateView];
}

- (void)setLocation:(NSString *)newLocation
{
    UILabel *label = (UILabel*)[self viewWithTag:kHeadTagLocation];
    
    if (self.location)
        [location release];
    location = [[NSString alloc] initWithString:newLocation];
    
    label.text = self.location;
    [self updateView];
}

- (void)setAvatar:(UIImage *)image
{
    CustomImageView *avatarView = (CustomImageView*)[self viewWithTag:kHeadTagAvatar];
    
    if (self.avatar)
        [avatar release];
    avatar = [image retain];
    
    avatarView.image = avatar;
    avatarView.frame = CGRectMake(15, 5, avatar.size.width, avatar.size.height);
    [self updateView];
}

- (void)setButtons:(int)button
{
    buttons = button;
    if (buttons & UserInfoButtonDetail)
        [self addSubview:detailButton];
    else
        [detailButton removeFromSuperview];
}

#pragma mark Actions
- (IBAction)detailPressed
{
    if (self.delegate)
    {
        if ([(id)self.delegate respondsToSelector:@selector(userDetailPressed)])
            [(id)self.delegate performSelector:@selector(userDetailPressed)];
    }
}

- (IBAction)followPressed
{
    if (self.delegate)
    {
        if ([(id)self.delegate respondsToSelector:@selector(userFollowPressed)])
            [(id)self.delegate performSelector:@selector(userFollowPressed)];
    }
}

@end

@implementation UserInfoView (Private)

- (void)createViewControls
{
    self.backgroundColor = [UIColor clearColor];
    
    // Load avatar image
    CustomImageView *avatarView = [[CustomImageView alloc] initWithFrame:CGRectMake(15, 5, 10, 10)];
    avatarView.tag = kHeadTagAvatar;
    [self addSubview:avatarView];
    [avatarView release];
    
    UILabel *label = nil;
    
    // User name label
    label = [[UILabel alloc] initWithFrame:CGRectMake(70, 3, 100, 20)];
    label.tag = kHeadTagUserName;
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont boldSystemFontOfSize:13];
    [self addSubview:label];
    [label release];
    
    // User screen_name
    label = [[UILabel alloc] initWithFrame:CGRectMake(70, 20, 100, 20)];
    label.tag = kHeadTagScreenName;
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont boldSystemFontOfSize:12];
    [self addSubview:label];
    [label release];
    
    // User location
    label = [[UILabel alloc] initWithFrame:CGRectMake(70, 35, 100, 20)];
    label.tag = kHeadTagLocation;
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont systemFontOfSize:12];
    [self addSubview:label];
    [label release];
    
    // Detail button
    detailButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    detailButton.frame = CGRectMake(290, 27, 10, 10);
    [detailButton addTarget:self action:@selector(detailPressed) forControlEvents:UIControlEventTouchUpInside];
}

- (void)updateView
{
    [self setNeedsDisplay];
}

@end
