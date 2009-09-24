//
//  TweetViewController.h
//  Tweetero
//
//  Created by Sergey Shkrabak on 9/12/09.
//  Copyright 2009 Codeminders. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "yFrogImageDownoader.h"
#import "yFrogImageUploader.h"
#import "MGConnectionWrap.h"
#import "UserInfoView.h"

// Content table sections indexes
typedef enum {
    TVSectionMessage = 0,
    TVSectionGeneralActions,
    TVSectionDelete
} TVSectionIndex;

// Segment button indexes
typedef enum {
    TVSegmentButtonDown = 0,
    TVSegmentButtonUp
} TVSegmentButton;

typedef enum {
	TVNoMVOperations,
	TVRetwit,
	TVForward
} TVMessageViewSuspendedOperations;


@protocol TweetViewDelegate
// Must return count of tweets on my account
- (int)messageCount;

// Must return dictionary with message data
- (NSDictionary *)messageData:(int)index;
@end

@class MGTwitterEngine;

@interface TweetViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, 
                                                   UIActionSheetDelegate, UIAlertViewDelegate,
                                                   ImageUploaderDelegate, ImageDownoaderDelegate,
                                                   UIWebViewDelegate, UserInfoViewDelegate>
{
    IBOutlet UISegmentedControl         *tweetNavigate;
    IBOutlet UITableView                *contentTable;
	UIActionSheet                       *_progressSheet;    
    UserInfoView                        *_headView;
    UIWebView                           *_webView;
    NSDictionary                        *_message;
    NSMutableDictionary                 *_sections;
    NSMutableDictionary                 *_imagesLinks;
	NSMutableArray                      *_connectionsDelegates;
    UIColor                             *_defaultTintColor;
    TVMessageViewSuspendedOperations    _suspendedOperation;
	BOOL                                _isDirectMessage;
	int                                 _newLineCounter;
    int                                 _count;
    int                                 _currentMessageIndex;
    id <TweetViewDelegate>              _store;
    MGTwitterEngine                     *_twitter;
}

@property (nonatomic, retain) UIActionSheet *_progressSheet;

- (id)initWithStore:(id <TweetViewDelegate>)store messageIndex:(int)index;
- (id)initWithStore:(id <TweetViewDelegate>)store;

// Actions
- (IBAction)tweetNavigate:(id)sender;
//- (IBAction)nameSelected;
- (IBAction)replyTwit;
- (IBAction)favoriteTwit;
- (IBAction)forwardTwit;
- (IBAction)deleteTwit;

- (void)receivedImage:(UIImage*)image sender:(ImageDownoader*)sender;
- (void)uploadedImage:(NSString*)yFrogURL sender:(ImageUploader*)sender;
- (void)movieFinishedCallback:(NSNotification*)aNotification;
- (void)playMovie:(NSString*)movieURL;

@end
