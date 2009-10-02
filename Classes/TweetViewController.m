//
//  TweetViewController.m
//  Tweetero
//
//  Created by Sergey Shkrabak on 9/12/09.
//  Copyright 2009 Codeminders. All rights reserved.
//

#import "TweetViewController.h"
#import "ImageLoader.h"
#import "TwitEditorController.h"
#import "NewMessageController.h"
#import "WebViewController.h"
#import "ImageViewController.h"
#import "UserInfo.h"
#import "TweetterAppDelegate.h"
#import "CustomImageView.h"
#import "UserInfoView.h"
#include "util.h"
#import "LoginController.h"
#import "MGTwitterEngine.h"
#import <MediaPlayer/MediaPlayer.h>
#import "TweetPlayer.h"
/*
const int kHeadTagAvatar = 1;
const int kHeadTagUserName = 2;
const int kHeadTagScreenName = 3;
const int kHeadTagLocation = 4;
*/

@interface TweetViewController (Private)

- (void)createHeadView;
- (void)updateViewTitle;
- (void)activeCurrentMessage;
- (void)updateSegmentButtonState;
- (UITableViewCell*)createCellWithSection:(TVSectionIndex)section forIndex:(NSInteger)index;
- (NSString*)formatDate:(NSDate*)date;
- (void)implementOperationIfPossible;
- (void)copyImagesToYFrog;
- (NSString*)makeHTMLMessage;

@end

@implementation TweetViewController (Private)

- (void)createHeadView
{
    _headView = [[UserInfoView alloc] init];
    _headView.delegate = self;
    _headView.buttons = UserInfoButtonDetail;
}

- (void)updateViewTitle
{
    self.title = [NSString stringWithFormat:NSLocalizedString(@"%i of %i", @""), _currentMessageIndex + 1, _count];
}

- (void)activeCurrentMessage
{
    if (_store)
    {
        if (_message)
            [_message release];
        
        _message = [[_store messageData:_currentMessageIndex] retain];
        
        if (_imagesLinks)
            [_imagesLinks release];
        if (_connectionsDelegates)
            [_connectionsDelegates release];
        
        _imagesLinks = [[NSMutableDictionary alloc] initWithCapacity:1];
		_connectionsDelegates = [[NSMutableArray alloc] initWithCapacity:1];
        [_webView loadHTMLString:[self makeHTMLMessage] baseURL:nil];
        
        // Check for direct message
        NSNumber *isDirectMessage = [_message objectForKey:@"DirectMessage"];
		_isDirectMessage = isDirectMessage && [isDirectMessage boolValue];
        
        // Update user data
        NSDictionary *userData = [_message objectForKey:@"user"];
        UIImage *avatarImage = [[ImageLoader sharedLoader] imageWithURL:[userData objectForKey:@"profile_image_url"]];

        _headView.avatar = avatarImage;
        _headView.username = [userData objectForKey:@"name"];
        _headView.screenname = [NSString stringWithFormat:@"@%@", [[userData objectForKey:@"screen_name"] lowercaseString]];
        _headView.location = [userData objectForKey:@"location"];
        
        // Reload content table
        [contentTable reloadData];
    }
}

- (void)updateSegmentButtonState
{
    [tweetNavigate setEnabled:(_currentMessageIndex != 0) forSegmentAtIndex:TVSegmentButtonUp];
    [tweetNavigate setEnabled:(_currentMessageIndex != (_count - 1)) forSegmentAtIndex:TVSegmentButtonDown];
}

- (UITableViewCell*)createCellWithSection:(TVSectionIndex)section forIndex:(NSInteger)index
{
    static NSString *CellIdentifier = @"TweetViewCellIdentifier";
    
    UITableViewCell *cell = [[[UITableViewCell alloc] initWithStyle: UITableViewCellStyleDefault 
                                                    reuseIdentifier: CellIdentifier] autorelease];
    
    NSArray *content = [_sections objectForKey:[NSNumber numberWithInt:section]];
    UILabel *textLabel = [cell textLabel];
    
    switch (section)
    {
        // Message cell
        case TVSectionMessage:
        {
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            // Create text view for message
            UITextView *messageView = [[[UITextView alloc] init] autorelease];
            messageView.frame = CGRectMake(5, 0, 290, 85);
            messageView.editable = NO;
            messageView.scrollEnabled = YES;
            messageView.font = [UIFont systemFontOfSize:16.];
            if (!isNullable([_message objectForKey:@"text"]))
                messageView.text = [_message objectForKey:@"text"];
            else
                messageView.text = nil;
            messageView.backgroundColor = [UIColor clearColor];
            //[cell.contentView addSubview:messageView];
            
            _webView.frame = CGRectMake(15, 5, 280, 85);
            _webView.backgroundColor = [UIColor clearColor];
            _webView.scalesPageToFit = NO;
            [cell.contentView addSubview:_webView];
            
            // Create label for date
            NSDate *theDate = [_message objectForKey:@"created_at"];
            NSString *msgSource = [_message objectForKey:@"source"];
            
            if (!isNullable(theDate) && !isNullable(msgSource))
            {
                NSString *formatedDate = [self formatDate:theDate];
                NSString *link = getLinkWithTag(msgSource);
                if (link)
                    msgSource = link;
                UILabel *infoLabel = [[[UILabel alloc] init] autorelease];
                infoLabel.frame = CGRectMake(15, 85, 200, 40);
                infoLabel.numberOfLines = 2;
                infoLabel.font = [UIFont systemFontOfSize:13.];
                infoLabel.backgroundColor = [UIColor clearColor];
                infoLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@\nfrom %@", @""), formatedDate, msgSource];
                infoLabel.textColor = [UIColor grayColor];
                [cell.contentView addSubview:infoLabel];
            }
            break;
        }
        // Actions cell
        case TVSectionGeneralActions:
        {
            //UIImageView *celImage = [cell imageView];
            //celImage.image = [UIImage imageNamed:@"Reply.png"];
            textLabel.text = [content objectAtIndex:index];
            if (index == 1)
                textLabel.textColor = _isDirectMessage ? [UIColor grayColor] : [UIColor blackColor];

            break;
        }
        // Delete cell
        case TVSectionDelete:
        {
            textLabel.text = [content objectAtIndex:index];
            break;
        }
    }
    return cell;
}

- (NSString*)formatDate:(NSDate*)date
{
    NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
    NSCalendar *calendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
    
	NSCalendarUnit unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit;
	NSDateComponents *nowComponents = [calendar components:unitFlags fromDate:[NSDate date]];
	NSDateComponents *yesterdayComponents = [calendar components:unitFlags fromDate:[NSDate dateWithTimeIntervalSinceNow:-60*60*24]];
	NSDateComponents *createdAtComponents = [calendar components:unitFlags fromDate:date];
	NSString *formatedDate = nil;
    
	if([nowComponents year] == [createdAtComponents year] &&
       [nowComponents month] == [createdAtComponents month] &&
       [nowComponents day] == [createdAtComponents day])
	{
		[dateFormatter setDateStyle:NSDateFormatterNoStyle];
		[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
		formatedDate = [dateFormatter stringFromDate:date];
	}
	else if([yesterdayComponents year] == [createdAtComponents year] &&
            [yesterdayComponents month] == [createdAtComponents month] &&
            [yesterdayComponents day] == [createdAtComponents day])
	{
		[dateFormatter setDateStyle:NSDateFormatterNoStyle];
		[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
		formatedDate = [NSString stringWithFormat:@"Yesterday, %@", [dateFormatter stringFromDate:date]];
	}
	else
	{
		[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
		[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
		formatedDate = [dateFormatter stringFromDate:date];
	}
    return formatedDate;
}

- (void)implementOperationIfPossible
{
	if([_connectionsDelegates count])
		return;
	if(_suspendedOperation == TVNoMVOperations)
		return;
    
    
	if(self._progressSheet)
	{
		[self._progressSheet dismissWithClickedButtonIndex:0 animated:YES];
		self._progressSheet = nil;
	}
	
	NSString* body = nil;
	if(_suspendedOperation == TVForward || _suspendedOperation == TVRetwit)
	{
		body = [_message objectForKey:@"text"];
        if (!isNullable(body))
        {
            NSEnumerator *en = [[_imagesLinks allKeys] objectEnumerator];
            NSString *link;
            NSString* yFrogLink = nil;
            while(link = [en nextObject])
                if((yFrogLink = [_imagesLinks objectForKey:link]) && ![yFrogLink isEqual:[NSNull null]])
                    body = [body stringByReplacingOccurrencesOfString:link withString:yFrogLink];
        }
	}
	
	if(_suspendedOperation == TVForward)
	{
        NSString *subject = NSLocalizedString(@"Mail Subject: Forwarding of a twit", @"");

        Class mailClass = NSClassFromString(@"MFMailComposeViewController");
        if ([mailClass canSendMail])
        {
            MFMailComposeViewController *mail = [[MFMailComposeViewController alloc] init];
            NSString *mailBody = [NSString stringWithFormat:@"<%@>", body];
            
            mail.mailComposeDelegate = self;
            [mail setMessageBody:mailBody isHTML:NO];
            [mail setSubject:subject];
            
            [self presentModalViewController:mail animated:YES];
            [mail release];
        }
        else
        {
            BOOL success = NO;
            
            NSString *mailto = [NSString stringWithFormat:@"mailto:?&subject=%@&body=%%26lt%%3B%@%%26gt%%3B", 
                                                [subject stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding], 
                                                [body stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
            
            success = [[UIApplication sharedApplication] openURL:[NSURL URLWithString:mailto]];
            if(!success)
            {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"Failed!", @"") 
                                                                message: NSLocalizedString(@"Failed to send a mail.", @"")
                                                               delegate: nil 
                                                      cancelButtonTitle: NSLocalizedString(@"OK", @"")
                                                      otherButtonTitles: nil];
                [alert show];	
                [alert release];
            }
		}
	}	
	else if(_suspendedOperation == TVRetwit)
	{
		TwitEditorController *msgView = [[TwitEditorController alloc] init];
		[self.navigationController pushViewController:msgView animated:YES];
		[msgView setRetwit:body whose:[[_message objectForKey:@"user"] objectForKey:@"screen_name"]];
		[msgView release];
	}
	_suspendedOperation = TVNoMVOperations;
}

- (void)copyImagesToYFrog
{
	NSEnumerator *enumerator = [_imagesLinks keyEnumerator];
	id obj;
	BOOL canOperate = YES;
	while (obj = [enumerator nextObject]) 
	{
		if([_imagesLinks objectForKey:obj] == [NSNull null])
		{
			canOperate = NO;
			ImageDownoader * downloader = [[ImageDownoader alloc] init];
			[_connectionsDelegates addObject:downloader];
			[downloader getImageFromURL:obj imageType:nonYFrog delegate:self];
			[downloader release];
		}
	}
	if(canOperate)
		[self implementOperationIfPossible];
	else
		self._progressSheet = ShowActionSheet(NSLocalizedString(@"Copying images to yFrog server...", @""), self, NSLocalizedString(@"Cancel", @""), self.view);
}

- (NSString*)makeHTMLMessage
{
	NSString *text = [_message objectForKey:@"text"];
	NSString *html;
	
    if (isNullable(text))
        return nil;
    
	NSArray *lines = [text componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
	NSString *line;
	_newLineCounter = [lines count];
	NSMutableArray *filteredLines = [[NSMutableArray alloc] initWithCapacity:_newLineCounter];
	NSEnumerator *en = [lines objectEnumerator];
	while(line = [en nextObject])
	{
		NSArray *words = [line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
		NSEnumerator *en = [words objectEnumerator];
		NSString *word;
		NSMutableArray *filteredWords = [[NSMutableArray alloc] initWithCapacity:[words count]];
		while(word = [en nextObject])
		{
			if([word hasPrefix:@"http://"] || [word hasPrefix:@"https://"] || [word hasPrefix:@"www"])
			{
				if([word hasPrefix:@"www"])
					word = [@"http://" stringByAppendingString:word];
                
				NSString *yFrogURL = ValidateYFrogLink(word);
                
				if(yFrogURL == nil)
				{
					if([word hasSuffix:@".jpg"] ||
                       [word hasSuffix:@".bmp"] ||
                       [word hasSuffix:@".jpeg"] ||
                       [word hasSuffix:@".tif"] ||
                       [word hasSuffix:@".tiff"] ||
                       [word hasSuffix:@".png"] ||
                       [word hasSuffix:@".gif"]
                       )
					{
						[_imagesLinks setObject:[NSNull null] forKey:word];
					}
					word = [NSString  stringWithFormat:@" <a href=%@>%@</a> ", word, word];
				}
				else
				{
					[_imagesLinks setObject:word forKey:word];
                    if (isVideoLink(yFrogURL))
                    {
                        NSString *videoSrc = [yFrogURL stringByAppendingString:@":iphone"];
                        word = [NSString stringWithFormat:@"<br><video poster=\"%@.th.jpg\" src=\"%@\"></video>", yFrogURL, videoSrc];
                    }
                    else
                    {
                        word = [NSString  stringWithFormat:@"<br><a href=%@><img src=%@.th.jpg></a><br>", yFrogURL, yFrogURL];
                    }
					_newLineCounter += 6;
				}
			}
			else if([word hasPrefix:@"@"] && [word length] > 1)
			{
				word = [NSString  stringWithFormat:@" <a href=user://%@>%@</a> ", [word substringFromIndex:1], word];
			}
			
			[filteredWords addObject:word];
		}
		
		[filteredLines addObject:[filteredWords componentsJoinedByString:@" "]];
		[filteredWords release];
	}
	
	NSString *htmlTemplate = @"<html></script></head><body style=\"width:%d; overflow:visible; padding:0; margin:0\"><big>%@</big></body></html>";
	html = [NSString stringWithFormat:htmlTemplate, (int)_webView.frame.size.width - 10, [filteredLines componentsJoinedByString:@"<br>"]];
	[filteredLines release];
	return html;
}

@end

@implementation TweetViewController

@synthesize _progressSheet;

- (id)initWithStore:(id <TweetViewDelegate>)store messageIndex:(int)index
{
    if (self = [super initWithNibName:@"TweetView" bundle:nil])
    {
        _store = [(id)store retain];
        _headView = nil;
        _count = [_store messageCount];
        _currentMessageIndex = (index >= _count || index < 0) ? 0 : index;
        _sections = [[NSMutableDictionary alloc] init];
        _twitter = [[MGTwitterEngine alloc] initWithDelegate:self];
        _defaultTintColor = [tweetNavigate.tintColor retain];
		_imagesLinks = nil;//[[NSMutableDictionary alloc] initWithCapacity:1];
		_connectionsDelegates = nil; //[[NSMutableArray alloc] initWithCapacity:1]; // See activeCurrentMessage for detail
		_suspendedOperation =  TVNoMVOperations;
        _webView = [[UIWebView alloc] init];
        _webView.delegate = self;
        
        NSMutableArray *sectionContent = nil;
        
        // Message
        sectionContent = [NSMutableArray arrayWithObject:NSLocalizedString(@"Message", @"")];
        [_sections setObject:sectionContent forKey:[NSNumber numberWithInt:TVSectionMessage]];
        // Action
        sectionContent = [NSMutableArray array];
        [sectionContent addObject:NSLocalizedString(@"Reply", @"")];
        [sectionContent addObject:NSLocalizedString(@"Favorite", @"")];
        [sectionContent addObject:NSLocalizedString(@"Forward", @"")];
        [_sections setObject:sectionContent forKey:[NSNumber numberWithInt:TVSectionGeneralActions]];
        // Delete action
        sectionContent = [NSMutableArray arrayWithObject:NSLocalizedString(@"Delete", @"")];
        [_sections setObject:sectionContent forKey:[NSNumber numberWithInt:TVSectionDelete]];
        
        [self createHeadView];
        [self activeCurrentMessage];
    }
    return self;    
}

- (id)initWithStore:(id <TweetViewDelegate>)store
{
    return [self initWithStore:store messageIndex:0];
}

- (void)dealloc
{
    _webView.delegate = nil;
    if (_webView.loading)
    {
        [_webView stopLoading];
        [TweetterAppDelegate decreaseNetworkActivityIndicator];
    }
    
	int connectionsCount = [_twitter numberOfConnections];
	[_twitter closeAllConnections];
	[_twitter removeDelegate];
	[_twitter release];
	while (connectionsCount-- > 0)
		[TweetterAppDelegate decreaseNetworkActivityIndicator];
    
    [_defaultTintColor release];
    if (_headView)
        [_headView release];
    [(id)_store release];
    [_sections release];
    [_message release];
    if (_imagesLinks)
        [_imagesLinks release];
    if (_connectionsDelegates)
        [_connectionsDelegates release];
    [super dealloc];
}

- (void)viewDidLoad 
{
    [super viewDidLoad];
    
	for (id view in _webView.subviews) 
	{
		if ([view respondsToSelector:@selector(setAllowsRubberBanding:)]) 
			[view performSelector:@selector(setAllowsRubberBanding:) withObject:NO]; 
	}
    
    tweetNavigate.frame = CGRectMake(0, 0, 80, 30);
    UIBarButtonItem *navigateBarItem = [[[UIBarButtonItem alloc] initWithCustomView:tweetNavigate] autorelease];
    self.navigationItem.rightBarButtonItem = navigateBarItem;
    
    [self updateViewTitle];
    [self updateSegmentButtonState];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	if (self.navigationController.navigationBar.barStyle == UIBarStyleBlackTranslucent ||
        self.navigationController.navigationBar.barStyle == UIBarStyleBlackOpaque) 
    {
		tweetNavigate.tintColor = [UIColor darkGrayColor];
    }
	else
    {
		tweetNavigate.tintColor = _defaultTintColor;
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning 
{
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

#pragma mark Actions
/** UISegmentControl action. Navigate for tweet messages.
 */
- (IBAction)tweetNavigate:(id)sender
{
    int index = [sender selectedSegmentIndex];
    
    switch (index)
    {
        // Press up button. Move to previouse message.
        case TVSegmentButtonUp:
            if (_currentMessageIndex > 0)
                _currentMessageIndex--;
            break;
            
        // Press down button. Move to next message.
        case TVSegmentButtonDown:
            if (_currentMessageIndex < (_count - 1))
                _currentMessageIndex++;
            break;
    }
    [self activeCurrentMessage];
    [self updateViewTitle];
    [self updateSegmentButtonState];
}

- (IBAction)replyTwit
{
	if (_isDirectMessage)
	{
		NewMessageController *msgView = [[NewMessageController alloc] init];
		[self.navigationController pushViewController:msgView animated:YES];
		[msgView setUser:[[_message objectForKey:@"sender"] objectForKey:@"screen_name"]];
		[msgView release];
	}
	else
	{
		TwitEditorController *msgView = [[TwitEditorController alloc] init];
		[self.navigationController pushViewController:msgView animated:YES];
		[msgView setReplyToMessage:_message];
		[msgView release];
	}
}

- (IBAction)favoriteTwit
{
    NSString *updateId = [_message objectForKey:@"id"];
	[TweetterAppDelegate increaseNetworkActivityIndicator];
    [_twitter markUpdate:[updateId intValue] asFavorite:YES];
}

- (IBAction)forwardTwit
{
    _suspendedOperation = TVForward;
    [self copyImagesToYFrog];
}

- (IBAction)deleteTwit
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"Do you wish to delete this tweet?", @"") 
                                                    message: NSLocalizedString(@"This operation cannot be undone", @"")
												   delegate: self 
                                          cancelButtonTitle: NSLocalizedString(@"Cancel", @"") 
                                          otherButtonTitles: NSLocalizedString(@"OK", @""), nil];
	[alert show];
	[alert release];
}

-(void)movieFinishedCallback:(NSNotification*)aNotification
{
    /*
    MPMoviePlayerController* theMovie = [aNotification object];
    
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: MPMoviePlayerPlaybackDidFinishNotification
                                                  object: theMovie];
    // Release the movie instance created in playMovieAtURL:
    [theMovie release];
     */
}

- (void)playMovie:(NSString*)movieURL
{
    /*
	MPMoviePlayerController* theMovie = [[TweetPlayer alloc] initWithContentURL:
                                         [NSURL URLWithString:[movieURL stringByAppendingString:@":iphone"]]];
	theMovie.scalingMode = MPMovieScalingModeAspectFit;
	theMovie.movieControlMode = MPMovieControlModeDefault;
    
	// Register for the playback finished notification.
	[[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(movieFinishedCallback:)
                                                 name: MPMoviePlayerPlaybackDidFinishNotification
                                               object: theMovie];
    
	// Movie playback is asynchronous, so this method returns immediately.
	[theMovie play];
     */
}

#pragma mark ImageDownoader Delegate
- (void)receivedImage:(UIImage*)image sender:(ImageDownoader*)sender
{
	[_connectionsDelegates removeObject:sender];
	if(image)
	{
		ImageUploader * uploader = [[ImageUploader alloc] init];
		[_connectionsDelegates addObject:uploader];
		[uploader postImage:image delegate:self userData:sender.origURL];
		[uploader release];
	}
	[self implementOperationIfPossible];
}

#pragma mark ImageUploader Delegate
- (void)uploadedImage:(NSString*)yFrogURL sender:(ImageUploader*)sender
{
	[_connectionsDelegates removeObject:sender];
	if(yFrogURL)
		[_imagesLinks setObject:yFrogURL forKey:sender.userData];
	[self implementOperationIfPossible];
}

- (void)uploadedDataSize:(NSInteger)size
{
}

- (void)uploadedProccess:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten
{
}

#pragma mark UserInfoView Delegate
- (void)userDetailPressed
{
    UserInfo *infoView = [[UserInfo alloc] initWithUserName:[[_message objectForKey:@"user"] objectForKey:@"screen_name"]];
	[self.navigationController pushViewController:infoView animated:YES];
	[infoView release];
}

#pragma mark MFMailComposeViewController Delegate
- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{    
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark UIWebView Delegate
- (void)webViewDidStartLoad:(UIWebView *)webView
{
	// starting the load, show the activity indicator in the status bar
	[TweetterAppDelegate increaseNetworkActivityIndicator];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
	if([[[request URL] absoluteString] isEqualToString:@"about:blank"])
		return YES;
    
	NSString *url = [[request URL] absoluteString];
	NSString *yFrogURL = ValidateYFrogLink(url);
	if(yFrogURL)
	{
		if(isVideoLink(yFrogURL))
		{
			[self playMovie:yFrogURL];
		}
		else
		{
			ImageViewController *imgViewCtrl = [[ImageViewController alloc] initWithYFrogURL:yFrogURL];
			imgViewCtrl.originalMessage = _message;
			[self.navigationController pushViewController:imgViewCtrl animated:YES];
			[imgViewCtrl release];
		}
	}
	else if([url hasPrefix:@"user://"])
	{
		NSString *user = [[url substringFromIndex:7] stringByTrimmingCharactersInSet:[NSCharacterSet punctuationCharacterSet]];
		UserInfo *infoView = [[UserInfo alloc] initWithUserName:user];
		[self.navigationController pushViewController:infoView animated:YES];
		[infoView release];
	}
	else
	{
		UIViewController *webViewCtrl = [[WebViewController alloc] initWithRequest:request];
		[self.navigationController pushViewController:webViewCtrl animated:YES];
		[webViewCtrl release];
	}
	
	return NO;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
	[TweetterAppDelegate decreaseNetworkActivityIndicator];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
	[TweetterAppDelegate decreaseNetworkActivityIndicator];
}

#pragma mark UIActionSheet Delegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	_suspendedOperation = TVNoMVOperations;
	id obj;
	NSEnumerator *enumerator = [_connectionsDelegates objectEnumerator];
	while (obj = [enumerator nextObject]) 
		[obj cancel];
}

#pragma mark UIAlertView Delegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if(buttonIndex > 0)
	{
		[TweetterAppDelegate increaseNetworkActivityIndicator];
		[_twitter deleteUpdate:[[_message objectForKey:@"id"] intValue]];
	}
}

#pragma mark UITableView DataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [_sections count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *content = [_sections objectForKey:[NSNumber numberWithInt:section]];
    NSInteger rows = 0;
    
    if (content)
        rows = [content count];
    
    return rows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self createCellWithSection:indexPath.section forIndex:indexPath.row];
    
    return cell;
}

#pragma mark UITableView Delegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == TVSectionMessage)
        return 135.;
    return 40.;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == TVSectionMessage)
        return 60.;
    return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (section == TVSectionMessage)
        return _headView;
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == TVSectionGeneralActions)
    {
        switch (indexPath.row)
        {
            // Reply
            case 0: 
                [self replyTwit];
                break;

            // Favorite
            case 1: 
                if (!_isDirectMessage)
                    [self favoriteTwit];
                break;
                
            // Forward
            case 2: 
                [self forwardTwit];
                break; 
        }
    }
    else if (indexPath.section == TVSectionDelete)
    {
        [self deleteTwit];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark MGTweeterEngine Delegate
- (void)requestSucceeded:(NSString *)connectionIdentifier
{
	[[NSNotificationCenter defaultCenter] postNotificationName: @"TwittsUpdated" object: nil];
	[TweetterAppDelegate decreaseNetworkActivityIndicator];
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)requestFailed:(NSString *)connectionIdentifier withError:(NSError *)error
{
	[TweetterAppDelegate decreaseNetworkActivityIndicator];
    if ([error code] == 401)
        [AccountController showAccountController:self.navigationController];
}

@end
