// Copyright (c) 2009 Imageshack Corp.
// All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
// 1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
// 3. The name of the author may not be used to endorse or promote products
//    derived from this software without specific prior written permission.
// 
// THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
// IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
// OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
// IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
// NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
// THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
// 

#import "TwitEditorController.h"
#import "LoginController.h"
#import "MGTwitterEngine.h"
#import "TweetterAppDelegate.h"
#import "LocationManager.h"
#include "util.h"
#import "TweetQueue.h"
#import "TweetPlayer.h"
#import "ImageViewController.h"
#import "MGTwitterEngineFactory.h"
#import "AccountManager.h"
#import "Logger.h"

#define DEBUG_VIDEO_UPLOAD                      0
#if DEBUG_VIDEO_UPLOAD
#   define DEBUG_VIDEO_FILE_NAME                @"youtube"
#   define DEBUG_VIDEO_FILE_EXT                 @"mov"
#endif

#define DEBUG_IMAGE_UPLOAD                      0
#if DEBUG_IMAGE_UPLOAD
#   define DEBUG_IMAGE_FILE_NAME                @"test"
#   define DEBUG_IMAGE_FILE_EXT                 @"jpg"
#endif


#define SEND_SEGMENT_CNTRL_WIDTH                130
#define FIRST_SEND_SEGMENT_WIDTH                66

#define IMAGES_SEGMENT_CONTROLLER_TAG           487
#define SEND_TWIT_SEGMENT_CONTROLLER_TAG        42

#define PROGRESS_ACTION_SHEET_TAG               214
#define PHOTO_Q_SHEET_TAG                       436
#define PROCESSING_PHOTO_SHEET_TAG              3

#define PHOTO_ENABLE_SERVICES_ALERT_TAG         666
#define PHOTO_DO_CANCEL_ALERT_TAG               13
#define TIMER_ALERT_TAG                         987
#define WAIT_RESPONSE_TIME                      60

#define K_UI_TYPE_MOVIE                         @"public.movie"
#define K_UI_TYPE_IMAGE                         @"public.image"

#define DEBUG_ENTRY_POINTS                      1
#if DEBUG_ENTRY_POINTS
#   define LogClassNameAndSelector()            NSLog(@"%@: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd))
#   define LogBeginOfSelector()                 NSLog(@"%@: -> %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd))
#   define LogEndOfSelector()                   NSLog(@"%@: <- %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd))
#else
#   define LogClassNameAndSelector()
#   define LogBeginOfSelector()
#   define LogEndOfSelector()
#endif

@implementation ImagePickerController

@synthesize twitEditor;

- (void)viewDidDisappear:(BOOL)animated
{
    LogBeginOfSelector();
	[super viewDidDisappear:NO];
    LogEndOfSelector();
}

- (void)dealloc
{
    LogBeginOfSelector();
	YFLog(@"Image picker - DEALLOC");
    LogEndOfSelector();
	[super dealloc];
}

@end

@implementation TwitEditorController

@synthesize progressSheet;
@synthesize currentMediaYFrogURL;
@synthesize connectionDelegate;
@synthesize _message;
@synthesize pickedVideo;
@synthesize pickedPhoto;
@synthesize previewImage;
@synthesize pickedPhotoData;
@synthesize location;
@synthesize pickImage;
@synthesize cancelButton;
@synthesize navItem;
@synthesize image;
@synthesize messageText;
@synthesize charsCount;
@synthesize progress;
@synthesize progressStatus;
@synthesize postImageSegmentedControl;
@synthesize imagesSegmentedControl;
@synthesize locationSegmentedControl;
@synthesize sendResponseTimer;

- (void)setCharsCount
{
    LogBeginOfSelector();
	charsCount.text = [NSString stringWithFormat:@"%d", MAX_SYMBOLS_COUNT_IN_TEXT_VIEW - [messageText.text length]];
    LogEndOfSelector();
}

- (void)setNavigatorButtons
{
    LogBeginOfSelector();
	if(self.navigationItem.leftBarButtonItem != cancelButton)
	{
		[[self navigationItem] setLeftBarButtonItem:cancelButton animated:YES];
		if([self.navigationController.viewControllers count] == 1)
			cancelButton.title = NSLocalizedString(@"Clear", @"");
		else
			cancelButton.title = NSLocalizedString(@"Cancel", @"");
	}	
		
	if([self mediaIsPicked] || [[messageText.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length])
	{
		if(self.navigationItem.rightBarButtonItem != segmentBarItem)
			self.navigationItem.rightBarButtonItem = segmentBarItem;
		
	}
	else
	{
		if(self.navigationItem.rightBarButtonItem)
			[[self navigationItem] setRightBarButtonItem:nil animated:YES];
	}
    LogEndOfSelector();
}

- (void)setMessageTextText:(NSString*)newText
{
    LogBeginOfSelector();
	messageText.text = newText;
	[self setCharsCount];
	[self setNavigatorButtons];
    LogEndOfSelector();
}

- (NSRange)locationRange
{
    LogBeginOfSelector();
	if (nil == self.location)
	{
        LogEndOfSelector();
		return NSMakeRange(0, 0);
	}
    LogEndOfSelector();
	return [messageText.text rangeOfString:self.location];
}

- (NSRange)urlPlaceHolderRange
{
    LogBeginOfSelector();
	NSRange urlPlaceHolderRange = [messageText.text rangeOfString:photoURLPlaceholderMask];
	if(urlPlaceHolderRange.location == NSNotFound)
		urlPlaceHolderRange = [messageText.text rangeOfString:videoURLPlaceholderMask];
    LogEndOfSelector();
	return urlPlaceHolderRange;
}

- (NSString*)currentMediaURLPlaceholder
{
    LogBeginOfSelector();
	if(pickedVideo) {
        LogEndOfSelector();
        return videoURLPlaceholderMask;
    }
	if(pickedPhoto) {
        LogEndOfSelector();
        return photoURLPlaceholderMask;
    }
    LogEndOfSelector();
	return nil;
}

- (void)setURLPlaceholder
{
    LogBeginOfSelector();
	NSRange photoPlaceHolderRange = [messageText.text rangeOfString:photoURLPlaceholderMask];
	NSRange videoPlaceHolderRange = [messageText.text rangeOfString:videoURLPlaceholderMask];
	NSRange selectedRange = messageText.selectedRange;
	if(selectedRange.location == NSNotFound)
		selectedRange.location = messageText.text.length;

	if([self mediaIsPicked])
	{
		if(photoPlaceHolderRange.location == NSNotFound && pickedPhoto)
		{
			NSString *newText = messageText.text;
			if(videoPlaceHolderRange.location != NSNotFound)
			{
				if(selectedRange.location >= videoPlaceHolderRange.location && selectedRange.location < videoPlaceHolderRange.location + videoPlaceHolderRange.length)
				{
					selectedRange.location = videoPlaceHolderRange.location;
					selectedRange.length = 0;
				}
				newText = [newText stringByReplacingCharactersInRange:videoPlaceHolderRange withString:@""];
			}
			if(![newText hasSuffix:@"\n"])
				newText = [newText stringByAppendingString:@"\n"];
			[self setMessageTextText:[newText stringByAppendingString:photoURLPlaceholderMask]];
		}
		if(videoPlaceHolderRange.location == NSNotFound && pickedVideo)
		{
			NSString *newText = messageText.text;
			if(photoPlaceHolderRange.location != NSNotFound)
			{
				if(selectedRange.location >= photoPlaceHolderRange.location && selectedRange.location < photoPlaceHolderRange.location + photoPlaceHolderRange.length)
				{
					selectedRange.location = photoPlaceHolderRange.location;
					selectedRange.length = 0;
				}
				newText = [newText stringByReplacingCharactersInRange:photoPlaceHolderRange withString:@""];
			}
			if(![newText hasSuffix:@"\n"])
				newText = [newText stringByAppendingString:@"\n"];
			[self setMessageTextText:[newText stringByAppendingString:videoURLPlaceholderMask]];
		}
	}
	else
	{
		if(photoPlaceHolderRange.location != NSNotFound)
		{
			if(selectedRange.location >= photoPlaceHolderRange.location && selectedRange.location < photoPlaceHolderRange.location + photoPlaceHolderRange.length)
			{
				selectedRange.location = photoPlaceHolderRange.location;
				selectedRange.length = 0;
			}
			[self setMessageTextText:[messageText.text stringByReplacingCharactersInRange:photoPlaceHolderRange withString:@""]];
		}
		if(videoPlaceHolderRange.location != NSNotFound)
		{
			if(selectedRange.location >= videoPlaceHolderRange.location && selectedRange.location < videoPlaceHolderRange.location + videoPlaceHolderRange.length)
			{
				selectedRange.location = videoPlaceHolderRange.location;
				selectedRange.length = 0;
			}
			[self setMessageTextText:[messageText.text stringByReplacingCharactersInRange:videoPlaceHolderRange withString:@""]];
		}
	}
	messageText.selectedRange = selectedRange;
    LogEndOfSelector();
}

- (void)initData
{
    LogBeginOfSelector();
    _twitter = [[MGTwitterEngineFactory createTwitterEngineForCurrentUser:self] retain];
    savedTextAfterMemoryWarning = nil;
	inTextEditingMode = NO;
	suspendedOperation = noTEOperations;
	//photoURLPlaceholderMask = [NSLocalizedString(@"YFrog image URL placeholder", @"") retain];
	//videoURLPlaceholderMask = [NSLocalizedString(@"YFrog video URL placeholder", @"") retain];
	photoURLPlaceholderMask = [[NSString stringWithFormat:@"%@ ",  NSLocalizedString(@"YFrog image URL placeholder", @"")] retain];
	videoURLPlaceholderMask = [[NSString stringWithFormat:@"%@ ", NSLocalizedString(@"YFrog video URL placeholder", @"")] retain];
	messageTextWillIgnoreNextViewAppearing = NO;
	twitWasChangedManually = NO;
	_queueIndex = -1;
    _canShowCamera = NO;
    timerFairedAlert = nil;
    sendResponseTimer = nil;
    [self progressClear];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setQueueTitle) name:@"QueueChanged" object:nil];
    LogEndOfSelector();
}

- (id)initWithNibName:(NSString *)nibName bundle:(NSBundle *)nibBundle
{
    LogBeginOfSelector();
	self = [super initWithNibName:nibName bundle:nibBundle];
	if(self) {
        [self initData];
    }
    LogEndOfSelector();
	return self;
}

- (id)init
{
    LogBeginOfSelector();
    LogEndOfSelector();
	return [self initWithNibName:@"PostImage" bundle:nil];
}

- (id)initInCameraMode
{
    LogBeginOfSelector();
    if ((self = [self init]))
    {
        _canShowCamera = YES;
    }
    LogEndOfSelector();
    return self;
}

-(void)dismissProgressSheetIfExist
{
    LogBeginOfSelector();
	if(self.progressSheet)
	{
		[self.progressSheet dismissWithClickedButtonIndex:0 animated:YES];
		self.progressSheet = nil;
	}
    LogEndOfSelector();
}

- (void)dealloc 
{
    LogBeginOfSelector();
    YFLog(@"tweetEditor - DEALLOC");
    if (timerFairedAlert) {
        [timerFairedAlert dismissWithClickedButtonIndex:0 animated:NO];
        [timerFairedAlert release];
    }
    if (self.sendResponseTimer) {
        [self.sendResponseTimer invalidate];
        self.sendResponseTimer = nil;
    }
    if (savedTextAfterMemoryWarning) {
        [savedTextAfterMemoryWarning release];
        savedTextAfterMemoryWarning = nil;
    }
	while (_indicatorCount) 
		[self releaseActivityIndicator];
	[_twitter closeAllConnections];
	[_twitter removeDelegate];
	[_twitter release];
	[_indicator release];
	[defaultTintColor release];
	[segmentBarItem release];
	[photoURLPlaceholderMask release];
	[videoURLPlaceholderMask release];
	self.location = nil;
	self.currentMediaYFrogURL = nil;
	self.connectionDelegate = nil;
	self._message = nil;
	self.pickedPhoto = nil;
	self.pickedVideo = nil;
	self.previewImage = nil;
	self.pickedPhotoData = nil;
	[self dismissProgressSheetIfExist];
	
	[image release];
	image = nil;
    [pickImage release];
	pickImage = nil;
    [cancelButton release];
	cancelButton = nil;	
	[navItem release];
	navItem = nil;
	[messageText release];
	messageText = nil;
	[charsCount release];
	charsCount = nil;
    [progress release];
	progress = nil;
	[progressStatus release];
	progressStatus = nil;
	[postImageSegmentedControl release];
	postImageSegmentedControl = nil;
	[imagesSegmentedControl release];
	imagesSegmentedControl = nil;
	[locationSegmentedControl release];
	locationSegmentedControl = nil;
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    LogEndOfSelector();
    [super dealloc];
}

- (void)setQueueTitle
{
    LogBeginOfSelector();
	int count = [[TweetQueue sharedQueue] count];
	NSString *title = nil;
	if(count)
		title = [NSString stringWithFormat:NSLocalizedString(@"QueueButtonTitleFormat", @""), count];
	else
		title = NSLocalizedString(@"EmptyQueueButtonTitleFormat", @"");
	if(![[postImageSegmentedControl titleForSegmentAtIndex:0] isEqualToString:title])
		[postImageSegmentedControl setTitle:title forSegmentAtIndex:0];
    LogEndOfSelector();
}

- (void)setImageImage:(UIImage*)newImage
{
    LogBeginOfSelector();
	image.image = newImage;
	[self setURLPlaceholder];
	[self setNavigatorButtons];
    LogEndOfSelector();
}

- (void)setImage:(UIImage*)img movie:(NSURL*)url
{
    LogBeginOfSelector();
	self.pickedPhoto = img;
	self.pickedVideo = url;
	
	if (!img)
	{
		self.previewImage = nil;
		self.pickedPhotoData = nil;		
	}
	
	if(url)
	{
		self.previewImage = [UIImage imageNamed:@"MovieIcon.tif"];
	}
	
	if (self.previewImage)
	{
		[self setImageImage:self.previewImage];
	}
    LogEndOfSelector();
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    LogBeginOfSelector();
	messageTextWillIgnoreNextViewAppearing = YES;
	[[picker parentViewController] dismissModalViewControllerAnimated:YES];
	[messageText becomeFirstResponder];
	[self setNavigatorButtons];
    LogEndOfSelector();
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishWithPickingPhoto:(UIImage *)img pickingMovie:(NSURL*)url
{    
    LogBeginOfSelector();
    [self progressClear];
    
	[[picker parentViewController] dismissModalViewControllerAnimated:YES];
	twitWasChangedManually = YES;
	messageTextWillIgnoreNextViewAppearing = YES;

	BOOL startNewUpload = NO;
	
	if(pickedPhoto != img || pickedVideo != url)
	{
		startNewUpload = YES;
		
		if(img)
		{
			BOOL needToResize = NO;
			BOOL needToRotate = NO;
			isImageNeedToConvert(img, &needToResize, &needToRotate);
			if (img.size.width > 500 || img.size.height > 500)
			{
				needToResize = YES;
			}
			
			if(needToResize || needToRotate)
			{
				self.progressSheet = ShowActionSheet(NSLocalizedString(@"Processing image...", @""), self, nil, self.view);
				self.progressSheet.tag = PROCESSING_PHOTO_SHEET_TAG;
			}
			
			[self setImage:img movie:nil];
			[self performSelector:@selector(updatePickedPhotoDataAndStartUpload) withObject:nil afterDelay:0.25];
		}
		else
		{
			[self setImage:nil movie:url];
			[self performSelectorOnMainThread:@selector(startUploadingOfPickedMediaIfNeed) withObject:nil waitUntilDone:NO];
		}
	}
	
	[self setNavigatorButtons];

	if(startNewUpload)
	{
		if(self.connectionDelegate)
			[self.connectionDelegate cancel];
		self.connectionDelegate = nil;
		self.currentMediaYFrogURL = nil;
	}

	[messageText becomeFirstResponder];
    LogEndOfSelector();
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    LogBeginOfSelector();
#if DEBUG_VIDEO_UPLOAD
    NSString *debugVideoFilePath = [[NSBundle mainBundle] pathForResource:DEBUG_VIDEO_FILE_NAME ofType:DEBUG_VIDEO_FILE_EXT];
    NSURL *theMovieURL = [NSURL fileURLWithPath:debugVideoFilePath];
    [self imagePickerController:picker didFinishWithPickingPhoto:nil pickingMovie:theMovieURL];
#elif DEBUG_IMAGE_UPLOAD
    NSString *debugImageFilePath = [[NSBundle mainBundle] pathForResource:DEBUG_IMAGE_FILE_NAME ofType:DEBUG_IMAGE_FILE_EXT];
    UIImage *theImage = [UIImage imageWithContentsOfFile:debugImageFilePath];
    [self imagePickerController:picker didFinishWithPickingPhoto:theImage pickingMovie:nil];
#else
	if([[info objectForKey:@"UIImagePickerControllerMediaType"] isEqualToString:K_UI_TYPE_IMAGE])
		[self imagePickerController:picker didFinishWithPickingPhoto:[info objectForKey:@"UIImagePickerControllerOriginalImage"] pickingMovie:nil];
	else if([[info objectForKey:@"UIImagePickerControllerMediaType"] isEqualToString:K_UI_TYPE_MOVIE])
		[self imagePickerController:picker didFinishWithPickingPhoto:nil pickingMovie:[info objectForKey:@"UIImagePickerControllerMediaURL"]];
#endif	
    LogEndOfSelector();
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)img editingInfo:(NSDictionary *)editInfo 
{
    LogBeginOfSelector();
	[self imagePickerController:picker didFinishWithPickingPhoto:img pickingMovie:nil];
    LogEndOfSelector();
}

- (void)movieFinishedCallback:(NSNotification*)aNotification
{
    LogBeginOfSelector();
    MPMoviePlayerController* theMovie = [aNotification object];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:theMovie];
    
    // Release the movie instance created in playMovieAtURL:
    [theMovie release];
    LogEndOfSelector();
}

- (void)imageViewTouched:(NSNotification*)notification
{
    LogBeginOfSelector();
	if(pickedPhoto)
	{
		UIViewController *imgViewCtrl = [[ImageViewController alloc] initWithImage:pickedPhoto];
		[self.navigationController pushViewController:imgViewCtrl animated:YES];
		[imgViewCtrl release];
	}
	else if(pickedVideo)
	{
		MPMoviePlayerController* theMovie = [[TweetPlayer alloc] initWithContentURL:pickedVideo];
		theMovie.scalingMode = MPMovieScalingModeAspectFill;
		theMovie.movieControlMode = MPMovieControlModeDefault;
 
		// Register for the playback finished notification.
		[[NSNotificationCenter defaultCenter] addObserver:self
                selector:@selector(movieFinishedCallback:)
                name:MPMoviePlayerPlaybackDidFinishNotification
                object:theMovie];
 
		// Movie playback is asynchronous, so this method returns immediately.
		[theMovie play];
	}
    LogEndOfSelector();
}

- (void)appWillTerminate:(NSNotification*)notification
{
    LogBeginOfSelector();
	if(![self mediaIsPicked] && ![[messageText.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length]) {
        LogEndOfSelector();
        return;
    }

	NSString *messageBody = messageText.text;
	if([self mediaIsPicked] && currentMediaYFrogURL)
	{
		messageBody = [messageBody stringByReplacingOccurrencesOfString:photoURLPlaceholderMask withString:currentMediaYFrogURL];
		messageBody = [messageBody stringByReplacingOccurrencesOfString:videoURLPlaceholderMask withString:currentMediaYFrogURL];
	}
    
    NSString *username = nil;
    if ([self isDirectMessage])
        if ([self respondsToSelector:@selector(username)])
            username = [self performSelector:@selector(username)];
    
	if(_queueIndex >= 0)
	{
		[[TweetQueue sharedQueue] replaceMessage: messageBody 
                                   withImageData: (pickedPhoto && !currentMediaYFrogURL) ? pickedPhotoData : nil  
                                       withMovie: (pickedVideo && !currentMediaYFrogURL) ? pickedVideo : nil
                                       inReplyTo: _queuedReplyId
                                         forUser: username
                                         atIndex: _queueIndex];
	}
	else
	{
		[[TweetQueue sharedQueue] addMessage: messageBody 
                               withImageData: (pickedPhoto && !currentMediaYFrogURL) ? pickedPhotoData : nil  
                                   withMovie: (pickedVideo && !currentMediaYFrogURL) ? pickedVideo : nil
                                   inReplyTo: _message ? [[_message objectForKey:@"id"] intValue] : 0
                                     forUser: username];
	}
    LogEndOfSelector();
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)loadView
{
    LogBeginOfSelector();
    [super loadView];
	UIBarButtonItem *temporaryBarButtonItem = [[UIBarButtonItem alloc] init];
	temporaryBarButtonItem.title = NSLocalizedString(@"Back", @"");
	self.navigationItem.backBarButtonItem = temporaryBarButtonItem;
	[temporaryBarButtonItem release];
	
	self.navigationItem.title = NSLocalizedString(@"New Tweet", @"");
	messageText.delegate = self;
	
	postImageSegmentedControl.frame = CGRectMake(0, 0, SEND_SEGMENT_CNTRL_WIDTH, 30);
	segmentBarItem = [[UIBarButtonItem alloc] initWithCustomView:postImageSegmentedControl];
	[postImageSegmentedControl setWidth:FIRST_SEND_SEGMENT_WIDTH forSegmentAtIndex:0];
	defaultTintColor = [postImageSegmentedControl.tintColor retain];	// keep track of this for later
	
	[self setURLPlaceholder];
	
	BOOL cameraEnabled = [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
	BOOL libraryEnabled = [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary];
	if(!cameraEnabled && !libraryEnabled)
		[pickImage setHidden:YES];

    if (savedTextAfterMemoryWarning)
    {
        [self setMessageTextText:savedTextAfterMemoryWarning];
        [savedTextAfterMemoryWarning release];
        savedTextAfterMemoryWarning = nil;
    }
	[messageText becomeFirstResponder];
	inTextEditingMode = YES;
	
	_indicatorCount = 0;
	_indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
	CGRect frame = image.frame;
	CGRect indFrame = _indicator.frame;
	frame.origin.x = (int)((image.frame.size.width - indFrame.size.width) * 0.5f) + 1;
	frame.origin.y = (int)((image.frame.size.height - indFrame.size.height) * 0.5f) + 1;
	frame.size = indFrame.size;
	_indicator.frame = frame;
		
	[self setQueueTitle];
	[self setNavigatorButtons];
	
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter addObserver:self selector:@selector(imageViewTouched:) name:@"ImageViewTouched" object:image];
	[notificationCenter addObserver:self selector:@selector(appWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
    LogEndOfSelector();
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    LogBeginOfSelector();
	NSRange urlPlaceHolderRange = [self urlPlaceHolderRange];
	if(urlPlaceHolderRange.location == NSNotFound && [self mediaIsPicked]) {
        LogEndOfSelector();
		return NO;
    }
	
	if((urlPlaceHolderRange.location < range.location) && (urlPlaceHolderRange.location + urlPlaceHolderRange.length > range.location)){
        LogEndOfSelector();
		return NO;
    }
	
	if(NSIntersectionRange(urlPlaceHolderRange, range).length > 0){
        LogEndOfSelector();
		return NO;
    }
	
	NSRange locationRange = [self locationRange];
	if ((locationRange.location < range.location) && (locationRange.location + locationRange.length > range.location)){
        LogEndOfSelector();
		return NO;
    }
	LogEndOfSelector();
	return YES;
}

- (void)textViewDidChange:(UITextView *)textView
{
    LogBeginOfSelector();
	twitWasChangedManually = YES;
	[self setCharsCount];
	[self setNavigatorButtons];
    LogEndOfSelector();
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    LogBeginOfSelector();
	inTextEditingMode = NO;
	[self setNavigatorButtons];
    LogEndOfSelector();
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    LogBeginOfSelector();
	inTextEditingMode = YES;
	[self setNavigatorButtons];
    LogEndOfSelector();
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{

}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{

}

- (void)didReceiveMemoryWarning 
{
    LogBeginOfSelector();
    if (savedTextAfterMemoryWarning)
        [savedTextAfterMemoryWarning release];
    savedTextAfterMemoryWarning = [messageText.text copy];
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    LogEndOfSelector();
    // Release anything that's not essential, such as cached data
}

- (IBAction)finishEditAction
{
    LogBeginOfSelector();
	[messageText resignFirstResponder];
    LogEndOfSelector();
}

- (NSArray*)availableMediaTypes:(UIImagePickerControllerSourceType) pickerSourceType
{
    LogBeginOfSelector();
	SEL selector = @selector(availableMediaTypesForSourceType:);
	NSMethodSignature *sig = [[UIImagePickerController class] methodSignatureForSelector:selector];
	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sig];
	[invocation setTarget:[UIImagePickerController class]];
	[invocation setSelector:selector];
	[invocation setArgument:&pickerSourceType atIndex:2];
	[invocation invoke];
	NSArray *mediaTypes = nil;
	[invocation getReturnValue:&mediaTypes];
    LogEndOfSelector();
	return mediaTypes;
}

- (void)grabImage 
{
    LogBeginOfSelector();
	BOOL imageAlreadyExists = [self mediaIsPicked];
	BOOL photoCameraEnabled = NO;
	BOOL photoLibraryEnabled = NO;
	BOOL movieCameraEnabled = NO;
	BOOL movieLibraryEnabled = NO;
    
	NSArray *mediaTypes = nil;

	if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
	{
		photoLibraryEnabled = YES;
		if ([[UIImagePickerController class] respondsToSelector:@selector(availableMediaTypesForSourceType:)]) 
		{
			mediaTypes = [self availableMediaTypes:UIImagePickerControllerSourceTypePhotoLibrary];
			movieLibraryEnabled = [mediaTypes indexOfObject:K_UI_TYPE_MOVIE] != NSNotFound;
			photoLibraryEnabled = [mediaTypes indexOfObject:K_UI_TYPE_IMAGE] != NSNotFound;
		}

	}
	if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
	{
		photoCameraEnabled = YES;


		if ([[UIImagePickerController class] respondsToSelector:@selector(availableMediaTypesForSourceType:)]) 
		{
			mediaTypes = [self availableMediaTypes:UIImagePickerControllerSourceTypeCamera];
			movieCameraEnabled = [mediaTypes indexOfObject:K_UI_TYPE_MOVIE] != NSNotFound;
			photoCameraEnabled = [mediaTypes indexOfObject:K_UI_TYPE_IMAGE] != NSNotFound;
		}
	}

	NSString *buttons[5] = {0};
	int i = 0;
	
	if(photoCameraEnabled)
		buttons[i++] = NSLocalizedString(@"Use photo camera", @"");
	if(movieCameraEnabled)
		buttons[i++] = NSLocalizedString(@"Use video camera", @"");
	if(photoLibraryEnabled)
		buttons[i++] = NSLocalizedString(@"Use library", @"");
	if(imageAlreadyExists)
		buttons[i++] = NSLocalizedString(@"RemoveImageTitle" , @"");
	
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
															 delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"") destructiveButtonTitle:nil
													otherButtonTitles:buttons[0], buttons[1], buttons[2], buttons[3], buttons[4], nil];
	actionSheet.actionSheetStyle = UIActionSheetStyleAutomatic;
	actionSheet.tag = PHOTO_Q_SHEET_TAG;
	[actionSheet showInView:self.view];
	[actionSheet release];
    LogEndOfSelector();
	
}

- (void)progressClear
{
    LogBeginOfSelector();
    _dataSize = 0;
    [progressStatus setText:@""];
    [progress setProgress:0];
    LogEndOfSelector();
}

- (void)progressUpdate:(NSInteger)bytesWritten
{
    float delta = (float)bytesWritten / (float)_dataSize;
    
    [progress setProgress:delta];
    
    NSString *sizeText;
    NSString *suffix = @"bytes";
    
    float denominator = 1.0f;
    if (_dataSize / 1024 > 0)
    {
        denominator = 1024;
        if ((_dataSize % 1024) / 1024 > 0)
        {
            denominator += 1024;
            suffix = @"Mb";
        }
        else
            suffix = @"Kb";
    }
    sizeText = [NSString stringWithFormat:NSLocalizedString(@"%.1f of %.1f %@", @""), bytesWritten / denominator, _dataSize / denominator, suffix];
    [progressStatus setText:sizeText];
}

- (IBAction)attachImagesActions:(id)sender
{
    LogBeginOfSelector();
	[self grabImage];
    LogEndOfSelector();
}

- (void)startUpload
{
    LogBeginOfSelector();
#ifdef TRACE
	YFLog(@"YFrog_DEBUG: Executing startUpload of TwitEditController method...");
#endif	
	
	if (self.connectionDelegate)
	{
		self.connectionDelegate = nil;
	}
	
	if(![self mediaIsPicked]) {
        LogEndOfSelector();
        return;
    }

    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
	
#ifdef TRACE
	YFLog(@"	YFrog_DEBUG: Media is picked");
#endif
    
	// Image uploader will be released after finishing upload process by setting
	// self.connectionDelegate property to nil on uploadedImage: sender method
	ImageUploader *uploader = [[ImageUploader alloc] init];
	self.connectionDelegate = uploader;
	[self retainActivityIndicator];
	if(pickedPhoto && pickedPhotoData)
	{
		[uploader setImageDimension:imageDimension];
		[uploader postData:self.pickedPhotoData delegate:self userData:pickedPhoto];
	}
	else
    {
#ifdef TRACE
		YFLog(@"	YFrog_DEBUG: Picked video URL description: %@", [pickedVideo description]);
		YFLog(@"	YFrog_DEBUG: Picked video is file URL %d", (int)[pickedVideo isFileURL]);
#endif
		
        NSString *path;
        if ([pickedVideo isFileURL]) {
            path = [pickedVideo path];
        } else {
            path = [pickedVideo absoluteString];
        }
		
#ifdef TRACE
		YFLog(@"	YFrog_DEBUG: Path of the video file %@", path);
#endif		
		
        [uploader postMP4DataWithPath:path delegate:self userData:pickedVideo];
    }
	
	[uploader release];
    LogEndOfSelector();
}

- (void)convertPickedImageAndStartUpload
{	
    LogBeginOfSelector();
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
	BOOL needToResize = NO;
	BOOL needToRotate = NO;
	int newDimension = isImageNeedToConvert(self.pickedPhoto, &needToResize, &needToRotate);
	if(needToResize || needToRotate)
	{
		UIImage *modifiedImage = imageScaledToSize(self.pickedPhoto, newDimension);
		if (nil != modifiedImage)
		{
			self.pickedPhoto = modifiedImage;
		}
	}
	
	[pool release];
	[self performSelector:@selector(updatePickedPhotoDataAndStartUpload) withObject:nil afterDelay:0.5];
    LogEndOfSelector();
}

- (void)updatePickedPhotoDataAndStartUpload
{
    LogBeginOfSelector();
	BOOL isNeedToResize = NO;
	BOOL isNeedToRotate = NO;
	int newDimension = isImageNeedToConvert(self.pickedPhoto, &isNeedToResize, &isNeedToRotate);
	imageDimension = 0;
	if(isNeedToResize)
	{
		imageDimension = newDimension;
	}
	
	imageRotationAngle = 0;
	UIImageOrientation orient = self.pickedPhoto.imageOrientation;
	switch(orient) 
	{
		case UIImageOrientationUp:
			imageRotationAngle = 90;
			break;
			
		case UIImageOrientationDown:
			imageRotationAngle = 270;
			break;
			
		case UIImageOrientationLeft:
			imageRotationAngle = 180;
			break;
			
		case UIImageOrientationRight:
			imageRotationAngle = 0;
			break;
	}
	
	self.pickedPhotoData = UIImageJPEGRepresentation(self.pickedPhoto, 1.0f);

	[self performSelector:@selector(reducePickedPhotoSizeAndStartUpload) withObject:nil afterDelay:0.1];
    LogEndOfSelector();
}

- (void)reducePickedPhotoSizeAndStartUpload
{
    LogBeginOfSelector();
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	UIImage *modifiedImage = imageScaledToSize(self.pickedPhoto, 480);
	if (nil != modifiedImage)
	{
		self.pickedPhoto = modifiedImage;
	}
	
	UIImage *thePreviewImage = imageScaledToSize(self.pickedPhoto, image.frame.size.width);
	self.previewImage = thePreviewImage;
	[self setImageImage:self.previewImage];	
	
	[pool release];
	
	[self performSelector:@selector(startUploadingOfPickedMediaIfNeed) withObject:nil afterDelay:0.1];
    LogEndOfSelector();
}

- (void)startUploadingOfPickedMediaIfNeed
{
    LogBeginOfSelector();
	if(!self.currentMediaYFrogURL && [self mediaIsPicked] && !connectionDelegate)
		[self startUpload];
	
	if(self.progressSheet && self.progressSheet.tag == PROCESSING_PHOTO_SHEET_TAG)
	{
		[self.progressSheet dismissWithClickedButtonIndex:-1 animated:YES];
		self.progressSheet = nil;
	}		
    LogEndOfSelector();
}

- (void)postImageAction 
{
    LogBeginOfSelector();
	if(![self mediaIsPicked] && ![[messageText.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length]) {
        LogEndOfSelector();
        return;
    }

	if([messageText.text length] > MAX_SYMBOLS_COUNT_IN_TEXT_VIEW)
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"You can not send message", @"") 
														message:NSLocalizedString(@"Cant to send too long message", @"")
													   delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", @""), nil];
		[alert show];
		[alert release];
        LogEndOfSelector();
		return;
	}

	if(!self.currentMediaYFrogURL && [self mediaIsPicked] && !self.progressSheet)
	{
		suspendedOperation = send;
		if(!connectionDelegate)
			[self startUpload];
		self.progressSheet = ShowActionSheet(NSLocalizedString(@"Upload Image to yFrog", @""), self, NSLocalizedString(@"Cancel", @""), self.view);
        LogEndOfSelector();
		return;
	}
	
	suspendedOperation = noTEOperations;
	
	if(![[AccountManager manager] isValidLoggedUser])
	{
        [AccountController showAccountController:self.navigationController];
        LogEndOfSelector();
		return;
	}
	
	NSString *messageBody = messageText.text;
	if([self mediaIsPicked] && currentMediaYFrogURL)
	{
        NSString *formattedMediaUrl = [NSString stringWithFormat:@"%@ ", currentMediaYFrogURL];
		messageBody = [messageBody stringByReplacingOccurrencesOfString:photoURLPlaceholderMask withString:formattedMediaUrl];
		messageBody = [messageBody stringByReplacingOccurrencesOfString:videoURLPlaceholderMask withString:formattedMediaUrl];
	}
	
	[TweetterAppDelegate increaseNetworkActivityIndicator];
    
    //	if(!self.progressSheet)
    //		self.progressSheet = ShowActionSheet(NSLocalizedString(@"Send twit on Twitter", @""), self, NSLocalizedString(@"Cancel", @""), self.view);
    if (self.progressSheet)
        [self.progressSheet dismissWithClickedButtonIndex:0 animated:NO];
    self.progressSheet = ShowActionSheet(NSLocalizedString(@"Send twit on Twitter", @""), self, nil, self.view);

    if (self.sendResponseTimer) {
        [self.sendResponseTimer invalidate];
        self.sendResponseTimer = nil;
    }
    self.sendResponseTimer = [NSTimer scheduledTimerWithTimeInterval:WAIT_RESPONSE_TIME target:self selector:@selector(timerCallback:) userInfo:nil repeats:NO];
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
	postImageSegmentedControl.enabled = NO;
    
    NSString* mgTwitterConnectionID = [self sendMessage:messageBody];
    
	MGConnectionWrap * mgConnectionWrap = [[MGConnectionWrap alloc] initWithTwitter:_twitter connection:mgTwitterConnectionID delegate:self];
	self.connectionDelegate = mgConnectionWrap;
	[mgConnectionWrap release];
	
	if(_queueIndex >= 0)
		[[TweetQueue sharedQueue] deleteMessage:_queueIndex];
    
    if (self.connectionDelegate == nil)
        [self.progressSheet dismissWithClickedButtonIndex:0 animated:YES];
    
    LogEndOfSelector();
}

- (void)timerCallback:(NSTimer*)aTimer
{
    LogBeginOfSelector();
    if (self.progressSheet || self.connectionDelegate) {
        if (self.progressSheet)
            [self.progressSheet dismissWithClickedButtonIndex:0 animated:YES];
        if (timerFairedAlert) {
            [timerFairedAlert dismissWithClickedButtonIndex:0 animated:NO];
            [timerFairedAlert release];
        }
        timerFairedAlert = [[UIAlertView alloc] initWithTitle:nil 
                                                        message:NSLocalizedString(@"Server response was not received.", @"") 
                                                       delegate:self 
                                              cancelButtonTitle:NSLocalizedString(@"Close", @"") 
                                              otherButtonTitles:NSLocalizedString(@"Wait", @""), nil];
        [timerFairedAlert setTag:TIMER_ALERT_TAG];
        [timerFairedAlert show];
    }
LogEndOfSelector();
}

- (NSString *)sendMessage:(NSString *)body
{
    LogBeginOfSelector();
    NSString *conntectionID = nil;
    
	if(_message)
		conntectionID = [_twitter sendUpdate:body inReplyTo:[[_message objectForKey:@"id"] stringValue]];
	else if(_queueIndex >= 0)
    {
        NSNumber *statusID = [NSNumber numberWithInt:_queuedReplyId];
		conntectionID = [_twitter sendUpdate:body inReplyTo:[statusID stringValue]];
	}
    else
		conntectionID = [_twitter sendUpdate:body];
    LogEndOfSelector();
    return conntectionID;
}

- (BOOL)isDirectMessage
{
    LogBeginOfSelector();
    LogEndOfSelector();
    return NO;
}

- (void)postImageLaterAction
{
    LogBeginOfSelector();
	if(![self mediaIsPicked] && ![[messageText.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length]) {
        LogEndOfSelector();
        return;
    }

	if([messageText.text length] > MAX_SYMBOLS_COUNT_IN_TEXT_VIEW)
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"You can not send message", @"") 
														message:NSLocalizedString(@"Cant to send too long message", @"")
													   delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", @""), nil];
		[alert show];
		[alert release];
        LogEndOfSelector();
		return;
	}

	NSString *messageBody = messageText.text;
	if([self mediaIsPicked] && currentMediaYFrogURL)
	{
		messageBody = [messageBody stringByReplacingOccurrencesOfString:photoURLPlaceholderMask withString:currentMediaYFrogURL];
		messageBody = [messageBody stringByReplacingOccurrencesOfString:videoURLPlaceholderMask withString:currentMediaYFrogURL];
	}

    NSString *username = nil;
    if ([self isDirectMessage])
        if ([self respondsToSelector:@selector(username)])
            username = [self performSelector:@selector(username)];
    
	BOOL added;
	if(_queueIndex >= 0)
	{
		added = [[TweetQueue sharedQueue] replaceMessage: messageBody 
                                               withImage: (pickedPhoto && !currentMediaYFrogURL) ? pickedPhoto : nil  
                                               withMovie: (pickedVideo && !currentMediaYFrogURL) ? pickedVideo : nil
                                               inReplyTo: _queuedReplyId
                                                 forUser: username
                                                 atIndex:_queueIndex];
	}
	else
	{
		added = [[TweetQueue sharedQueue] addMessage: messageBody 
                                           withImage: (pickedPhoto && !currentMediaYFrogURL) ? pickedPhoto : nil  
                                           withMovie: (pickedVideo && !currentMediaYFrogURL) ? pickedVideo : nil
                                           inReplyTo: _message ? [[_message objectForKey:@"id"] intValue] : 0
                                             forUser: username];
	}
	if(added)
	{
		if(connectionDelegate)
			[connectionDelegate cancel];
        [self setImageImage:nil];
		[self setImage:nil movie:nil];
		[self setMessageTextText:@""];
		[messageText becomeFirstResponder];
		inTextEditingMode = YES;
		[self setNavigatorButtons];
        [self progressClear];
	}
	else
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Failed!", @"") 
														message:NSLocalizedString(@"Cant to send too long message", @"")
													   delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", @""), nil];
		[alert show];
		[alert release];
	}
    LogEndOfSelector();
}

- (IBAction)insertLocationAction
{	
    LogBeginOfSelector();
	UIImage *theImage = nil;
	
	if (nil == self.location)
	{
		if ([self addLocation])
		{
			theImage = [UIImage imageNamed:@"mapRemove.tiff"];
		}
	}
	else
	{
		NSRange selectedRange = messageText.selectedRange;
		NSString *newLineWithLocation = [NSString stringWithFormat:@"%@%@", @"\n", self.location];
		
		NSRange notFoundRange = {NSNotFound, 0};
		NSRange stringRange = [messageText.text rangeOfString:newLineWithLocation];
		NSString *newText = nil;
		if (!NSEqualRanges(stringRange, notFoundRange))
		{
			newText = [messageText.text stringByReplacingOccurrencesOfString:newLineWithLocation withString:@""];			
		}
		else
		{
			newText = [messageText.text stringByReplacingOccurrencesOfString:self.location withString:@""];
		}
		
		[self setMessageTextText:newText];
		self.location = nil;
		messageText.selectedRange = selectedRange;
		theImage = [UIImage imageNamed:@"map.tiff"];
	}
	
	if (nil != theImage)
	{
		[locationSegmentedControl setImage:theImage forSegmentAtIndex:0];
	}
    LogEndOfSelector();
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    LogBeginOfSelector();
	if(actionSheet.tag == PHOTO_Q_SHEET_TAG)
	{
		if(buttonIndex == actionSheet.cancelButtonIndex) {
            LogEndOfSelector();
            return;
        }
		
		if([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"RemoveImageTitle", @"")])
		{
            // PROGRESS
            [self progressClear];
            
			twitWasChangedManually = YES;
			[self setImage:nil movie:nil];
			if(connectionDelegate)
				[connectionDelegate cancel];
			self.currentMediaYFrogURL = nil;
            LogEndOfSelector();
			return;
		}
		else if([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"Use photo camera", @"")])
		{
			ImagePickerController *imgPicker = [[ImagePickerController alloc] init];
			imgPicker.twitEditor = self;
			imgPicker.delegate = self;	
			imgPicker.sourceType = UIImagePickerControllerSourceTypeCamera;
			if([imgPicker respondsToSelector:@selector(setMediaTypes:)])
				[imgPicker performSelector:@selector(setMediaTypes:) withObject:[NSArray arrayWithObject:K_UI_TYPE_IMAGE]];
			[self presentModalViewController:imgPicker animated:YES];
			[imgPicker release];
            LogEndOfSelector();
			return;
		}
		else if([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"Use video camera", @"")])
		{
			ImagePickerController *imgPicker = [[ImagePickerController alloc] init];
			imgPicker.twitEditor = self;
			imgPicker.delegate = self;			
			imgPicker.sourceType = UIImagePickerControllerSourceTypeCamera;
			if([imgPicker respondsToSelector:@selector(setMediaTypes:)])
				[imgPicker performSelector:@selector(setMediaTypes:) withObject:[NSArray arrayWithObject:K_UI_TYPE_MOVIE]];
			[self presentModalViewController:imgPicker animated:YES];
			[imgPicker release];
            LogEndOfSelector();
			return;
		}
		else if([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"Use library", @"")])
		{
			ImagePickerController *imgPicker = [[ImagePickerController alloc] init];
			imgPicker.twitEditor = self;
			imgPicker.delegate = self;				
			imgPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
			if([imgPicker respondsToSelector:@selector(setMediaTypes:)])
				[imgPicker performSelector:@selector(setMediaTypes:) withObject:[self availableMediaTypes:UIImagePickerControllerSourceTypePhotoLibrary]];
			[self presentModalViewController:imgPicker animated:YES];
			[imgPicker release];
            LogEndOfSelector();
			return;
		}
	}
	else
	{
        [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
		suspendedOperation = noTEOperations;
		[self dismissProgressSheetIfExist];
		if(connectionDelegate)
			[connectionDelegate cancel];
        [cancelButton setEnabled:YES];
        [TweetterAppDelegate decreaseNetworkActivityIndicator];
	}
    LogEndOfSelector();
}

- (void)setRetwit:(NSString*)body whose:(NSString*)username
{
    LogBeginOfSelector();
	if(username)
		[self setMessageTextText:[NSString stringWithFormat:NSLocalizedString(@"ReTwitFormat", @""), username, body]];
	else
		[self setMessageTextText:body];
    LogEndOfSelector();
}

- (void)setReplyToMessage:(NSDictionary*)message
{
    LogBeginOfSelector();
	self._message = message;
	NSString *replyToUser = [[message objectForKey:@"user"] objectForKey:@"screen_name"];
	[self setMessageTextText:[NSString stringWithFormat:@"@%@ ", replyToUser]];
    LogEndOfSelector();
}

- (void)viewWillAppear:(BOOL)animated
{
    LogBeginOfSelector();
	[super viewWillAppear:animated];
	if (self.navigationController.navigationBar.barStyle == UIBarStyleBlackTranslucent || self.navigationController.navigationBar.barStyle == UIBarStyleBlackOpaque) 
		postImageSegmentedControl.tintColor = [UIColor darkGrayColor];
	else
		postImageSegmentedControl.tintColor = defaultTintColor;
	if(!messageTextWillIgnoreNextViewAppearing)
	{
		[messageText becomeFirstResponder];
		inTextEditingMode = YES;
	}
	messageTextWillIgnoreNextViewAppearing = NO;
	[self setCharsCount];
	[self setNavigatorButtons];
    LogEndOfSelector();
}

- (void)viewDidAppear:(BOOL)animated
{
    LogBeginOfSelector();
    [super viewDidAppear:animated];
    if (_canShowCamera)
    {
        _canShowCamera = NO;
        if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
        {
			ImagePickerController *imgPicker = [[ImagePickerController alloc] init];
			imgPicker.twitEditor = self;
			imgPicker.delegate = self;				
            imgPicker.sourceType = UIImagePickerControllerSourceTypeCamera;
            if([imgPicker respondsToSelector:@selector(setMediaTypes:)])
                [imgPicker performSelector:@selector(setMediaTypes:) withObject:[NSArray arrayWithObjects:K_UI_TYPE_MOVIE, K_UI_TYPE_IMAGE, nil]];
            [self presentModalViewController:imgPicker animated:YES];
			[imgPicker release];
        }
    }
    LogEndOfSelector();
}

- (void)popController
{
    LogBeginOfSelector();
	[self setImage:nil movie:nil];
	[self setMessageTextText:@""];
	[self.navigationController popToRootViewControllerAnimated:YES];
    LogEndOfSelector();
}

- (IBAction)imagesSegmentedActions:(id)sender
{
    LogBeginOfSelector();
	switch([sender selectedSegmentIndex])
	{
		case 0:
			[self grabImage];
			break;
		case 1:
			[self setImage:nil movie:nil];
			if(connectionDelegate)
				[connectionDelegate cancel];
			self.currentMediaYFrogURL = nil;
			break;
		default:
			break;
	}
    LogEndOfSelector();
}

- (IBAction)postMessageSegmentedActions:(id)sender
{
    LogBeginOfSelector();
	switch([sender selectedSegmentIndex])
	{
		case 0:
			[self postImageLaterAction];
			break;
		case 1:
			[self postImageAction];
			break;
		default:
			break;
	}
    LogEndOfSelector();
}

- (void)uploadedImage:(NSString*)yFrogURL sender:(ImageUploader*)sender
{
    LogBeginOfSelector();
	[self releaseActivityIndicator];

    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    
	id userData = sender.userData;
	if(([userData isKindOfClass:[UIImage class]] && userData == pickedPhoto)    ||
		([userData isKindOfClass:[NSURL class]] && userData == pickedVideo)	) // don't kill later connection
	{
		self.connectionDelegate = nil;
		self.currentMediaYFrogURL = yFrogURL;
	}
	else if(![self mediaIsPicked])
	{
		self.connectionDelegate = nil;
		self.currentMediaYFrogURL = nil;
		self.pickedPhoto = nil;
		self.pickedVideo = nil;
		self.pickedPhotoData = nil;
		self.previewImage = nil;
	}
	else // another media was picked
    {
        LogEndOfSelector();
        return;
    }
	
	if(suspendedOperation == send)
	{
		suspendedOperation == noTEOperations;
		if(yFrogURL)
			[self postImageAction];
		else
		{
			[self dismissProgressSheetIfExist];
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"Failed!", @"")
                                                            message: NSLocalizedString(@"Error occure during uploading of image", @"")
														   delegate: nil 
                                                  cancelButtonTitle: NSLocalizedString(@"OK", @"") 
                                                  otherButtonTitles: nil];
			[alert show];	
			[alert release];
		}
	}
}

- (void)uploadedDataSize:(NSInteger)size
{
    _dataSize = size;
}

- (void)uploadedProccess:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten
{
    //float delta = (float)(totalBytesWritten) / (float)_dataSize;
    //[progress setProgress:delta];
    [self progressUpdate:totalBytesWritten];
}

- (void)imageUploadDidFailedBySender:(ImageUploader *)sender
{
    LogBeginOfSelector();
	if(pickedPhoto)
	{
		[sender postData:self.pickedPhotoData delegate:self userData:pickedPhoto];
	}
LogEndOfSelector();
}

- (BOOL)shouldChangeImage:(UIImage *)anImage withNewImage:(UIImage *)newImage
{
    LogBeginOfSelector();
	[self setImage:newImage movie:nil];
    LogEndOfSelector();
	return YES;
}

#pragma mark MGTwitterEngineDelegate methods
- (void)requestSucceeded:(NSString *)connectionIdentifier
{
    LogBeginOfSelector();
	[TweetterAppDelegate decreaseNetworkActivityIndicator];
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
	[self dismissProgressSheetIfExist];
	[[NSNotificationCenter defaultCenter] postNotificationName: @"TwittsUpdated" object: nil];
	self.connectionDelegate = nil;
	image.image = nil;
	self.pickedPhoto = nil;
	self.pickedVideo = nil;
	self.pickedPhotoData = nil;
	self.previewImage = nil;
	[self setMessageTextText:@""];
	[messageText becomeFirstResponder];
	inTextEditingMode = YES;
	[self setNavigatorButtons];
	[self.navigationController popViewControllerAnimated:YES];
    LogEndOfSelector();
}

- (void)requestFailed:(NSString *)connectionIdentifier withError:(NSError *)error
{
    LogBeginOfSelector();
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    
	[TweetterAppDelegate decreaseNetworkActivityIndicator];
	[self dismissProgressSheetIfExist];
	self.connectionDelegate = nil;
	postImageSegmentedControl.enabled = YES;
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"Failed!", @"")
                                                    message: [error localizedDescription]
												   delegate: nil 
                                          cancelButtonTitle: NSLocalizedString(@"OK", @"") 
                                          otherButtonTitles: nil];
	[alert show];	
	[alert release];
    LogEndOfSelector();
}

- (void)MGConnectionCanceled:(NSString *)connectionIdentifier
{
    LogBeginOfSelector();
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
	postImageSegmentedControl.enabled = YES;
	self.connectionDelegate = nil;
	[TweetterAppDelegate decreaseNetworkActivityIndicator];
	[self dismissProgressSheetIfExist];
    LogEndOfSelector();
}

- (void)doCancel
{
    LogBeginOfSelector();
	[self.navigationController popViewControllerAnimated:YES];
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
	if(connectionDelegate)
		[connectionDelegate cancel];
	[self setImage:nil movie:nil];
	[self setMessageTextText:@""];
	[messageText resignFirstResponder];
	[self setNavigatorButtons];
    LogEndOfSelector();
}

- (IBAction)cancel
{
    LogBeginOfSelector();
	if(!twitWasChangedManually || ([[messageText.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] == 0 && ![self mediaIsPicked]))
	{
		[self doCancel];
        LogEndOfSelector();
		return;
	}
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"The message is not sent", @"") 
                                                    message:NSLocalizedString(@"Your changes will be lost", @"")
												   delegate:self 
                                          cancelButtonTitle:NSLocalizedString(@"Cancel", @"") 
                                          otherButtonTitles:NSLocalizedString(@"OK", @""), nil];
	alert.tag = PHOTO_DO_CANCEL_ALERT_TAG;
	[alert show];
	[alert release];
    LogEndOfSelector();
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    LogBeginOfSelector();
	if(alertView.tag == PHOTO_DO_CANCEL_ALERT_TAG)
	{
		if(buttonIndex > 0)
			[self doCancel];
	}
    else if (alertView.tag == TIMER_ALERT_TAG)
    {
        if (buttonIndex == alertView.cancelButtonIndex) {
            [self.sendResponseTimer invalidate];
            self.sendResponseTimer = nil;
            [TweetterAppDelegate decreaseNetworkActivityIndicator];
            [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
            postImageSegmentedControl.enabled = YES;
        }
        else {
            self.sendResponseTimer = [NSTimer scheduledTimerWithTimeInterval:WAIT_RESPONSE_TIME target:self selector:@selector(timerCallback:) userInfo:nil repeats:NO];
            self.progressSheet = ShowActionSheet(NSLocalizedString(@"Send twit on Twitter", @""), self, nil, self.view);
        }
    }
	else if(alertView.tag == PHOTO_ENABLE_SERVICES_ALERT_TAG)
	{
		if(buttonIndex > 0)
		{
			[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"UseLocations"];
			[[LocationManager locationManager] startUpdates];
			[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateLocationDefaultsChanged" object: nil];
		}
	}
    LogEndOfSelector();
}

- (void)editUnsentMessage:(int)index
{	
    LogBeginOfSelector();
	NSString* text;
	NSData* imageData;
	NSURL* movieURL;
    NSString* username;
    
	if([[TweetQueue sharedQueue] getMessage:&text andImageData:&imageData movieURL:&movieURL inReplyTo:&_queuedReplyId forUser:&username atIndex:index])
	{
		_queueIndex = index;
		[self setMessageTextText:text];
		if(imageData)
			[self setImage:[UIImage imageWithData:imageData] movie:nil];
		else if(movieURL)
			[self setImage:nil movie:movieURL];
		[postImageSegmentedControl setTitle:NSLocalizedString(@"Save", @"") forSegmentAtIndex:0];
		[postImageSegmentedControl setWidth:postImageSegmentedControl.frame.size.width*0.5f
			forSegmentAtIndex:0];
	}
    LogEndOfSelector();
}

- (void)retainActivityIndicator
{
    LogBeginOfSelector();
	if(++_indicatorCount == 1)
	{
		[image addSubview:_indicator];
		[_indicator startAnimating];
	}
    LogEndOfSelector();
}

- (void)releaseActivityIndicator
{
    LogBeginOfSelector();
	if(_indicatorCount > 0)
	{
		[_indicator stopAnimating];
		[_indicator removeFromSuperview];
		--_indicatorCount;
	}
    LogEndOfSelector();
}

- (BOOL)mediaIsPicked
{
    LogBeginOfSelector();
    LogEndOfSelector();
	return pickedPhoto || pickedVideo;
}

- (BOOL)addLocation
{
    LogBeginOfSelector();
	if(![[LocationManager locationManager] locationServicesEnabled])
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Location service is not available on the device", @"") 
														message:NSLocalizedString(@"You can to enable Location Services on the device", @"")
													   delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", @""), nil];
		[alert show];
		[alert release];
        LogEndOfSelector();
		return NO;
	}
	
	if(![[NSUserDefaults standardUserDefaults] boolForKey:@"UseLocations"])
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Location service was turn off in settings", @"") 
														message:NSLocalizedString(@"You can to enable Location Services in the application settings", @"")
													   delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"") otherButtonTitles:NSLocalizedString(@"OK", @""), nil];
		alert.tag = PHOTO_ENABLE_SERVICES_ALERT_TAG;
		[alert show];
		[alert release];
        LogEndOfSelector();
		return NO;
	}
	
	if([[LocationManager locationManager] locationDenied])
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Locations for this application was denied", @"") 
														message:NSLocalizedString(@"You can to enable Location Services by throw down settings", @"")
													   delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
		[alert show];
		[alert release];
        LogEndOfSelector();
		return NO;
	}
	
	if(![[LocationManager locationManager] locationDefined])
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Location undefined", @"") 
														message:NSLocalizedString(@"Location is still undefined", @"")
													   delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
		[alert show];
		[alert release];
        LogEndOfSelector();
		return NO;
	}
	
	NSString* mapURL = [NSString stringWithFormat:NSLocalizedString(@"LocationLinkFormat", @""), [[LocationManager locationManager] mapURL]];
	NSRange selectedRange = messageText.selectedRange;
	if (nil == self.location)
	{
		[self setMessageTextText:[NSString stringWithFormat:@"%@\n%@", messageText.text, mapURL]];
	}
	else
	{
		NSString *newText = [messageText.text stringByReplacingOccurrencesOfString:self.location withString:mapURL];
		[self setMessageTextText:newText];
	}
	
	self.location = mapURL;
	messageText.selectedRange = selectedRange;
    LogEndOfSelector();
	return YES;
}

@end
