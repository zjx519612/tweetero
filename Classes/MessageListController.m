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

#import "MessageListController.h"
#import "LoginController.h"
#import "MGTwitterEngine.h"
#import "ImageLoader.h"
#import "TweetterAppDelegate.h"
#import "CustomImageView.h"
#import "MGTwitterEngineFactory.h"
#import "util.h"
#import "TweetViewController.h"
#import "AccountManager.h"
#import "TwitterMessageObject.h"
#import "TwMessageCell.h"

#define NAME_TAG            1
#define TIME_TAG            2
#define IMAGE_TAG           3
#define TEXT_TAG            4
#define YFROG_IMAGE_TAG     5
#define FAVICON_TAG         6
#define ROW_HEIGHT          70

@interface MessageListController(Private)
- (void)updateYFrogImages;
@end

@interface MessageListController(TwitterMessageObjectManagament)
- (void)initTwitterMessageObjectCache;
- (void)releaseTwitterMessageObjectCache;
- (TwitterMessageObject*)mapTwitterMessageObject:(NSDictionary*)message;
- (TwitterMessageObject*)cacheMessageObjectAsDictionary:(NSDictionary*)message;
- (TwitterMessageObject*)cacheMessageObject:(TwitterMessageObject*)message;
- (TwitterMessageObject*)lookupTwitterMessageObject:(NSDictionary*)message;
- (TwitterMessageObject*)lookupTwitterMessageObjectById:(NSString*)messageId;
- (TwitterMessageObject*)twitterMessageObjectByDictionary:(NSDictionary*)message;
@end

@interface MessageListController(ThumbnailLoader)
- (void)loadThumbnailsForMessageObject:(TwitterMessageObject*)message;
//- (void)loadThumbnailsThread:(TwitterMessageObject*)message;
- (void)loadThumbnailsThread:(NSDictionary*)data;
@end

@implementation MessageListController

- (void)dealloc
{
    ISLog(@"Destroy object");
    
    [self releaseTwitterMessageObjectCache];
	while (_indicatorCount) 
	{
		[self releaseActivityIndicator];
	}
	
	[_indicator release];
	
	int connectionsCount = [_twitter numberOfConnections];
	[_twitter closeAllConnections];
	[_twitter removeDelegate];
	[_twitter release];
	while(connectionsCount-- > 0)
		[TweetterAppDelegate decreaseNetworkActivityIndicator];

	[_messages release];
	
    if (_yFrogImages)
        [_yFrogImages release];
	
	if(_errorDesc)
		[_errorDesc release];
	
	[super dealloc];
}

- (void)viewDidLoad 
{
    [super viewDidLoad];
	
    [self initTwitterMessageObjectCache];
	_errorDesc = nil;
	_lastMessage = NO;
	_loading = [[AccountManager manager] isValidLoggedUser];
	_indicatorCount = 0;
	_indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
	
    _indicator.autoresizingMask = UIViewAutoresizingNone;
    
	CGRect frame = self.tableView.frame;

	CGRect indFrame = _indicator.frame;
	frame.origin.x += (frame.size.width - indFrame.size.width) * 0.5f;
	frame.origin.y += (frame.size.height - indFrame.size.height) * 0.3f;
	frame.size.width = indFrame.size.width;
    frame.size.height = indFrame.size.height;
	_indicator.frame = frame;
	
    _twitter = [[MGTwitterEngineFactory createTwitterEngineForCurrentUser:self] retain];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accountChanged:) name:@"AccountChanged" object:nil];

	[self performSelector:@selector(reloadAll) withObject:nil afterDelay:0.5f];
}

- (void)viewWillAppear:(BOOL)animated 
{
    [super viewWillAppear:animated];
	
	if(!_messages)
		[self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
    if (_processIndicator)
        [_processIndicator hide];
    [super viewWillDisappear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (_loading && _processIndicator) {
        [_processIndicator show];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (void)didReceiveMemoryWarning 
{
    ISLog(@"MEMORY WARNING");
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

#pragma mark Table view methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
    return 1;
}

- (BOOL)noMessages
{
	return !_messages || [_messages count] == 0;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
    return [self noMessages] ? 1:
		_lastMessage? [_messages count]: [_messages count] + 1;
}

/*
#define IMAGE_SIDE              48
#define BORDER_WIDTH            5

#define TEXT_OFFSET_X           (BORDER_WIDTH * 2 + IMAGE_SIDE)
#define TEXT_OFFSET_Y           (BORDER_WIDTH * 2 + LABEL_HEIGHT)
#define TEXT_WIDTH              (320 - TEXT_OFFSET_X - BORDER_WIDTH) - YFROG_IMAGE_WIDTH - BORDER_WIDTH
#define TEXT_HEIGHT             (ROW_HEIGHT - TEXT_OFFSET_Y - BORDER_WIDTH)

#define LABEL_HEIGHT            20
#define LABEL_WIDTH             130

//#define YFROG_IMAGE_X           TEXT_OFFSET_X + TEXT_WIDTH + BORDER_WIDTH
//#define YFROG_IMAGE_Y           TEXT_OFFSET_Y
#define YFROG_IMAGE_WIDTH       48

#define YFROG_IMAGE_X           TEXT_OFFSET_X
#define YFROG_IMAGE_Y           TEXT_OFFSET_Y + TEXT_HEIGHT
*/
- (UITableViewCell *)tableviewCellWithReuseIdentifier:(NSString *)identifier 
{
	if([identifier isEqualToString:@"UICell"])
	{
		UITableViewCell *uiCell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:identifier] autorelease];
        UILabel *label = [uiCell textLabel];
        
		label.textAlignment = UITextAlignmentCenter;
		label.font = [UIFont systemFontOfSize:16];
		return uiCell;
	}
    
	if([identifier isEqualToString:@"TwittListCell"])
	{
		CGRect rect;
        
		rect = CGRectMake(0.0, 0.0, 320.0, ROW_HEIGHT);
        UITableViewCell *cell = [[[TwMessageCell alloc] initWithFrame:rect reuseIdentifier:identifier] autorelease];

        /*
		
		UITableViewCell *cell = [[[UITableViewCell alloc] initWithFrame:rect reuseIdentifier:identifier] autorelease];
		
		//Userpic view
		rect = CGRectMake(BORDER_WIDTH, (ROW_HEIGHT - IMAGE_SIDE) / 2.0, IMAGE_SIDE, IMAGE_SIDE);
        CustomImageView *imageView = [[CustomImageView alloc] initWithFrame:rect];
		imageView.tag = IMAGE_TAG;
		[cell.contentView addSubview:imageView];
		[imageView release];
		
		
		UILabel *label;
		
		//Username
		rect = CGRectMake(TEXT_OFFSET_X, BORDER_WIDTH, LABEL_WIDTH, LABEL_HEIGHT);
		label = [[UILabel alloc] initWithFrame:rect];
		label.tag = NAME_TAG;
		label.font = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]];
		label.highlightedTextColor = [UIColor whiteColor];
		[cell.contentView addSubview:label];
		label.opaque = NO;
		label.backgroundColor = [UIColor clearColor];
		
		[label release];
		
		//Message creation time
		rect = CGRectMake(TEXT_OFFSET_X + LABEL_WIDTH, BORDER_WIDTH, LABEL_WIDTH, LABEL_HEIGHT);
		label = [[UILabel alloc] initWithFrame:rect];
		label.tag = TIME_TAG;
		label.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
		label.textAlignment = UITextAlignmentRight;
		label.highlightedTextColor = [UIColor whiteColor];
		label.textColor = [UIColor lightGrayColor];
		[cell.contentView addSubview:label];
		label.opaque = NO;
		label.backgroundColor = [UIColor clearColor];
		
		[label release];

		//Message body
		rect = CGRectMake(TEXT_OFFSET_X, TEXT_OFFSET_Y, TEXT_WIDTH, TEXT_HEIGHT);
		label = [[UILabel alloc] initWithFrame:rect];
		label.tag = TEXT_TAG;
		label.lineBreakMode = UILineBreakModeWordWrap;
		label.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
		label.highlightedTextColor = [UIColor whiteColor];
		label.numberOfLines = 0;
		[cell.contentView addSubview:label];
		label.opaque = NO;
		label.backgroundColor = [UIColor clearColor];
		
		[label release];
		
        rect = CGRectMake(300, TEXT_OFFSET_Y, 16, 16);
        UIImageView *favImageView = [[UIImageView alloc] initWithFrame:rect];
        favImageView.tag = FAVICON_TAG;
        [cell.contentView addSubview:favImageView];
        [favImageView release];
        
        //CustomImageView *yFrogImage = [[CustomImageView alloc] initWithFrame:CGRectMake(YFROG_IMAGE_X, YFROG_IMAGE_Y, YFROG_IMAGE_WIDTH, YFROG_IMAGE_WIDTH)];
        ActiveImageView *yFrogImage = [[ActiveImageView alloc] initWithFrame:CGRectMake(YFROG_IMAGE_X, YFROG_IMAGE_Y, YFROG_IMAGE_WIDTH, YFROG_IMAGE_WIDTH)];
        yFrogImage.frameType = CIDefaultFrameType;
        yFrogImage.tag = YFROG_IMAGE_TAG;
        yFrogImage.backgroundColor = [UIColor clearColor];
        [cell.contentView addSubview:yFrogImage];
        [yFrogImage release];
        */
		return cell;
	}
	
	return nil;
}

- (NSString*)noMessagesString
{
	return @"";
}

- (NSString*)loadingMessagesString
{
	return @"";
}

- (void)configureCell:(UITableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath 
{
    UILabel *cellLabel = [cell textLabel];
    
	if([self noMessages])
	{
		if(_errorDesc)
			cellLabel.text = _errorDesc;
		else
            cellLabel.text = _loading ? @"" : [self noMessagesString];
		return;
	}

	if(indexPath.row < [_messages count])
	{
        NSDictionary *messageData = [_messages objectAtIndex:indexPath.row];

        TwitterMessageObject *object = [self twitterMessageObjectByDictionary:messageData];
        [((TwMessageCell*)cell) setTwitterMessageObject:object];
        
        /*
        if (object)
        {
            CGRect cellFrame = [cell frame];
            
            //Set message text
            UILabel *label;
            
            label = (UILabel *)[cell viewWithTag:TEXT_TAG];
            label.text = object.message;
            [label setFrame:CGRectMake(TEXT_OFFSET_X, TEXT_OFFSET_Y, TEXT_WIDTH + YFROG_IMAGE_WIDTH, TEXT_HEIGHT)];
            [label sizeToFit];
            
            // Load yFrog thumbnail
            //CustomImageView *yFrogImage = (CustomImageView*)[cell viewWithTag:YFROG_IMAGE_TAG];
            ActiveImageView *yFrogImage = (ActiveImageView*)[cell viewWithTag:YFROG_IMAGE_TAG];
            
            float row_max_y = 0;
            
            id image = (_yFrogImages) ? [_yFrogImages objectForKey:object.messageId] : nil;
            if (image && (image != [NSNull null]))
            {
                CGRect image_frame = yFrogImage.frame;
                
                image_frame.origin.y = label.frame.origin.y + label.frame.size.height + BORDER_WIDTH;
                yFrogImage.frame = image_frame;
                yFrogImage.image = (UIImage*)image;
                
                row_max_y = image_frame.origin.y + image_frame.size.height + BORDER_WIDTH;
            }
            else
            {
                row_max_y = label.frame.origin.y + label.frame.size.height + BORDER_WIDTH;
                yFrogImage.image = nil;
            }
            
            cellFrame.size.height = max(row_max_y, ROW_HEIGHT);
            [cell setFrame:cellFrame];
            
            label = (UILabel *)[cell viewWithTag:TIME_TAG];
            label.text = object.creationFormattedDate;
            
            //Set userpic
            CustomImageView *imageView = (CustomImageView *)[cell viewWithTag:IMAGE_TAG];
            imageView.image = object.avatar;
            
            //Set user name
            label = (UILabel *)[cell viewWithTag:NAME_TAG];
            label.text = object.screenname;
            
            UIImageView *favView = (UIImageView*)[cell viewWithTag:FAVICON_TAG];
            if (object.isFavorite)
                favView.image = [UIImage imageNamed:@"statusfav.png"];
            else
                favView.image = nil;            
        }
         */
    }
	else
	{
        cellLabel.text = NSLocalizedString(@"Load More...", @"");
	}
    
    /*
	if(indexPath.row < [_messages count])
	{
		NSDictionary *messageData = [_messages objectAtIndex:indexPath.row];
		NSDictionary *userData = [messageData objectForKey:@"user"];
		if(!userData)
			userData = [messageData objectForKey:@"sender"];
		
		CGRect cellFrame = [cell frame];
		
        //Set message text
		UILabel *label;
		label = (UILabel *)[cell viewWithTag:TEXT_TAG];
		label.text = DecodeEntities([messageData objectForKey:@"text"]);
        [label setFrame:CGRectMake(TEXT_OFFSET_X, TEXT_OFFSET_Y, TEXT_WIDTH + YFROG_IMAGE_WIDTH, TEXT_HEIGHT)];
		[label sizeToFit];
        
        // Load yFrog thumbnail
        //CustomImageView *yFrogImage = (CustomImageView*)[cell viewWithTag:YFROG_IMAGE_TAG];
        ActiveImageView *yFrogImage = (ActiveImageView*)[cell viewWithTag:YFROG_IMAGE_TAG];
        
        float row_max_y = 0;
        
        id image = (_yFrogImages) ? [_yFrogImages objectForKey:[messageData objectForKey:@"id"]] : nil;
        if (image && (image != [NSNull null]))
        {
            CGRect image_frame = yFrogImage.frame;
            
            image_frame.origin.y = label.frame.origin.y + label.frame.size.height + BORDER_WIDTH;
            yFrogImage.frame = image_frame;
            yFrogImage.image = (UIImage*)image;
            
            row_max_y = image_frame.origin.y + image_frame.size.height + BORDER_WIDTH;
        }
        else
        {
            row_max_y = label.frame.origin.y + label.frame.size.height + BORDER_WIDTH;
            yFrogImage.image = nil;
        }
        
        cellFrame.size.height = max(row_max_y, ROW_HEIGHT);
		[cell setFrame:cellFrame];
        
		NSDate *createdAt = [messageData objectForKey:@"created_at"];
		label = (UILabel *)[cell viewWithTag:TIME_TAG];
        label.text = FormatNSDate(createdAt);
        
		//Set userpic
		CustomImageView *imageView = (CustomImageView *)[cell viewWithTag:IMAGE_TAG];
        CGSize avatarViewSize = CGSizeMake(48, 48);
        
        imageView.image = loadAndScaleImage([userData objectForKey:@"profile_image_url"], avatarViewSize);
        
		//Set user name
		label = (UILabel *)[cell viewWithTag:NAME_TAG];
		label.text = [userData objectForKey:@"screen_name"];
        
        UIImageView *favView = (UIImageView*)[cell viewWithTag:FAVICON_TAG];
        
        id fav = [messageData objectForKey:@"favorited"];
        if (fav && [fav boolValue])
            favView.image = [UIImage imageNamed:@"statusfav.png"];
        else
            favView.image = nil;
	} 
	else
	{
        cellLabel.text = NSLocalizedString(@"Load More...", @"");
	}
    */
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
    NSString *CellIdentifier = ![self noMessages] && indexPath.row < [_messages count]? @"TwittListCell": @"UICell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) 
	{
        cell = [self tableviewCellWithReuseIdentifier:CellIdentifier];
    }
    
    [self configureCell:cell forIndexPath:indexPath];
	
	cell.contentView.backgroundColor = indexPath.row % 2 ? [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1]: [UIColor whiteColor];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(indexPath.row >= [_messages count]) return 50;
	
	UITableViewCell *cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];
    NSLog(@"cell height = %f", cell.frame.size.height);
	return cell.frame.size.height;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{	
	if([self noMessages])
		return;
		
	if(indexPath.row < [_messages count])
	{
		NSMutableDictionary *messageData = [NSMutableDictionary dictionaryWithDictionary:[_messages objectAtIndex:indexPath.row]];
		id userInfo = [messageData objectForKey:@"sender"];
		if(userInfo && [messageData objectForKey:@"user"] == nil)
		{
			[messageData setObject:userInfo forKey:@"user"];
			[messageData setObject:[NSNumber numberWithBool:YES] forKey:@"DirectMessage"];
		}
        
        TweetViewController *tweetView = [[TweetViewController alloc] initWithStore:self messageIndex:indexPath.row];
        [tweetView setDataSourceClass:[self class]];
        [self.navigationController pushViewController:tweetView animated:YES];
        [tweetView release];
	}
	else
	{
		[self loadMessagesStaringAtPage:++_pagenum count:MESSAGES_PER_PAGE];
	}
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark TweetViewDelegate
- (int)messageCount
{
    return [_messages count];
}

- (NSDictionary *)messageData:(int)index
{
    NSMutableDictionary *messageData = [NSMutableDictionary dictionaryWithDictionary:[_messages objectAtIndex:index]];
    
    id userInfo = [messageData objectForKey:@"sender"];
    if(userInfo && [messageData objectForKey:@"user"] == nil)
    {
        [messageData setObject:userInfo forKey:@"user"];
        [messageData setObject:[NSNumber numberWithBool:YES] forKey:@"DirectMessage"];
    }
    
    return messageData;
}

- (void)accountChanged:(NSNotification*)notification
{
	[self reloadAll];
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
}

#pragma mark MGTwitterEngineDelegate methods
- (void)requestSucceeded:(NSString *)connectionIdentifier
{
    ISLog(@"Success");
	[TweetterAppDelegate decreaseNetworkActivityIndicator];
	_loading = NO;
}

- (void)requestFailed:(NSString *)connectionIdentifier withError:(NSError *)error
{
    ISLog(@"Failed");
    
	if(self.navigationItem.leftBarButtonItem)
			self.navigationItem.leftBarButtonItem.enabled = YES;
	[TweetterAppDelegate decreaseNetworkActivityIndicator];
	_loading = NO;
	_errorDesc = [[[error localizedDescription] capitalizedString] retain];
	
	[self releaseActivityIndicator];
	
    if ([error code] == 401)
        [AccountController showAccountController:self.navigationController];
		
	if(_messages)
	{
		[_messages release];
		_messages = nil;
	}
	
	[self.tableView reloadData];
}

- (void)statusesReceived:(NSArray *)statuses forRequest:(NSString *)connectionIdentifier
{
    ISLog(@"Receive status");
    
    /*
	if([statuses count] < MESSAGES_PER_PAGE)
	{
		_lastMessage = YES;
		if(_messages)
			[self.tableView deleteRowsAtIndexPaths:
					[NSArray arrayWithObject: [NSIndexPath indexPathForRow:[_messages count] inSection:0]]
				withRowAnimation:UITableViewRowAnimationTop];
	}
	*/
    
	if(!_messages)
	{
		if([statuses count] > 0)
            _messages = [statuses retain];
        
		[self.tableView reloadData];
	}
	else
	{
		NSArray *messages = _messages;
        
		_messages = [[messages arrayByAddingObjectsFromArray:statuses] retain];
        
		NSMutableArray *indices = [NSMutableArray arrayWithCapacity:[statuses count]];
		for(int i = [messages count]; i < [_messages count]; ++i)
			[indices addObject:[NSIndexPath indexPathForRow:i inSection:0]];
			
		@try
		{
			[self.tableView insertRowsAtIndexPaths:indices withRowAnimation:UITableViewRowAnimationTop];
		}
		@catch (NSException * e) 
		{
			NSLog(@"Tweet List Error!!!\nNumber of rows: %d\n_messages: %@\nstatuses: %@\nIndices: %@\n",
				[self tableView:self.tableView numberOfRowsInSection:0],
				_messages, statuses, indices);
		}
		
		[messages release];
	}
    
    [self updateYFrogImages];
	[self releaseActivityIndicator];
	
	if(self.navigationItem.leftBarButtonItem)
		self.navigationItem.leftBarButtonItem.enabled = YES;
}

NSInteger dateReverseSort(id num1, id num2, void *context)
{
	NSDate *d1 = [num1 objectForKey:@"created_at"];
	NSDate *d2 = [num2 objectForKey:@"created_at"];
	return [d2 compare:d1];
}

- (void)directMessagesReceived:(NSArray *)statuses forRequest:(NSString *)connectionIdentifier;
{
    ISLog(@"Receive Direct message");
    /*
	if([statuses count] < MESSAGES_PER_PAGE)
	{
		_lastMessage = YES;
		if(_messages && [_messages count] > 0 && [self.tableView numberOfRowsInSection:0] > [_messages count])
			[self.tableView deleteRowsAtIndexPaths:
					[NSArray arrayWithObject: [NSIndexPath indexPathForRow:[_messages count] inSection:0]]
				withRowAnimation:UITableViewRowAnimationTop];
	}
	*/
	if(!_messages)
	{
		if([statuses count] > 0)
			_messages = [statuses retain];
		[self.tableView reloadData];
	}
	else
	{
		NSArray *messages = _messages;
		
		[statuses setValue:[NSNumber numberWithBool:YES] forKey:@"NewItem"];
		_messages = [[[messages arrayByAddingObjectsFromArray:statuses] sortedArrayUsingFunction:dateReverseSort context:nil] retain];
		NSMutableArray *indices = [NSMutableArray arrayWithCapacity:[statuses count]];
		for(int i = 0; i < [_messages count]; ++i)
		{
			if([[_messages objectAtIndex:i] valueForKey:@"NewItem"])
			{
				[indices addObject:[NSIndexPath indexPathForRow:i inSection:0]];
			}
		}
		
		@try 
		{
			[self.tableView insertRowsAtIndexPaths:indices withRowAnimation:UITableViewRowAnimationTop];
		}
		@catch (NSException * e) 
		{
			NSLog(@"Direct Messages Error!!!\nNumber of rows: %d\n_messages: %@\nstatuses: %@\nIndices: %@\n",
				[self tableView:self.tableView numberOfRowsInSection:0],
				_messages, statuses, indices);
		}
		@finally 
		{
			[_messages setValue:nil forKey:@"NewItem"];
		}
		
		[messages release];
	}
    
	[self updateYFrogImages];
	[self releaseActivityIndicator];
	
	if(self.navigationItem.leftBarButtonItem)
		self.navigationItem.leftBarButtonItem.enabled = YES;
}

#pragma mark ===
- (void)loadMessagesStaringAtPage:(int)numPage count:(int)count
{
    ISLog(@"Start load message");

    if ([[AccountManager manager] isValidLoggedUser])
	{
		if(_errorDesc)
		{
			[_errorDesc release];
			_errorDesc = nil;
		}
		_loading = YES;
		[self retainActivityIndicator];
		if(self.navigationItem.leftBarButtonItem)
			self.navigationItem.leftBarButtonItem.enabled = NO;
		if([self noMessages])
			[self.tableView reloadData];
	}
}

- (void)reloadAll
{
    ISLog(@"Reload data");
    
	_lastMessage = NO;
	_pagenum = 1;
    
	if(_messages)
	{
		[_messages release];
		_messages = nil;
	}
	
	[self loadMessagesStaringAtPage:_pagenum count:MESSAGES_PER_PAGE];
}

- (void)retainActivityIndicator
{
    _indicatorCount++;
    
    if (_processIndicator == nil)
        _processIndicator = [[TwActivityIndicator alloc] init];
    
    [_processIndicator.messageLabel setText:[self loadingMessagesString]];
    if (self.navigationController.topViewController == self.parentViewController)
    {
        if (_indicatorCount == 1)
        {
            [_processIndicator show];
        }
    }
    else
    {
        [_processIndicator hide];
    }
}

- (void)releaseActivityIndicator
{
	if(_indicatorCount > 0)
	{
		if(--_indicatorCount == 0)
		{
            if (_processIndicator)
                [_processIndicator hide];
		}
	}
}

@end

@implementation MessageListController(Private)

- (void)loadThumbnailsFromYFrog {
    if (_messages)
    {
        NSDictionary *copyOfMessage = [_messages copy];
        
        if (!_yFrogImages)
            _yFrogImages = [[NSMutableDictionary alloc] init];
        
        NSDictionary *message;
        NSEnumerator *en = [copyOfMessage objectEnumerator];
        while ((message = (NSDictionary *)[en nextObject]))
        {
            id key = [message objectForKey:@"id"];
            if ([_yFrogImages objectForKey:key] == nil)
            {
                NSString *yFrogLink = yFrogLinkFromText([message objectForKey:@"text"]);
                if (yFrogLink)
                {
                    //CGSize size = CGSizeMake(YFROG_IMAGE_WIDTH, YFROG_IMAGE_WIDTH);
                    CGSize size = CGSizeMake(48, 48);
                    
                    id image = loadAndScaleImage(yFrogLink, size);
                    if (!image)
                        image = [NSNull null];
                    
                    [_yFrogImages setObject:image forKey:key];
                }
            }
        }
        
        [copyOfMessage release];
    }
    else if (_yFrogImages)
    {
        [_yFrogImages release];
        _yFrogImages = nil;
    }
    [self.tableView reloadData];
}

- (void)updateYFrogImages
{
    ISLog(@"Update Images");
    
    //[self performSelectorInBackground:@selector(loadThumbnailsFromYFrog) withObject:nil];
    //[self loadThumbnailsFromYFrog];
}

@end

@implementation MessageListController(TwitterMessageObjectManagament)

- (void)initTwitterMessageObjectCache
{
    if (_messageObjects == nil)
        _messageObjects = [[NSMutableDictionary alloc] init];
}

- (void)releaseTwitterMessageObjectCache
{
    [_messageObjects release];
}

- (TwitterMessageObject*)mapTwitterMessageObject:(NSDictionary*)message
{
    NSDictionary *userData = [message objectForKey:@"user"];
    if (!userData)
        userData = [message objectForKey:@"sender"];

    CGSize avatarViewSize = CGSizeMake(48, 48);
    TwitterMessageObject *messageObject = [[TwitterMessageObject alloc] init];
    
    NSString *text = [message objectForKey:@"text"];
    
    messageObject.messageId             = [message objectForKey:@"id"];
    messageObject.screenname            = [userData objectForKey:@"screen_name"];
    messageObject.message               = DecodeEntities(text);
    messageObject.creationDate          = [message objectForKey:@"created_at"];
    messageObject.creationFormattedDate = FormatNSDate(messageObject.creationDate);
    messageObject.avatarUrl             = [userData objectForKey:@"profile_image_url"];
    messageObject.avatar                = loadAndScaleImage(messageObject.avatarUrl, avatarViewSize);
    messageObject.yfrogLinks            = yFrogLinksArrayFromText(text);
    
    BOOL isFavorite = NO;
    
    id fav = [message objectForKey:@"favorited"];
    if (fav && fav != (id)[NSNull null])
        isFavorite = [fav boolValue];
    
    messageObject.isFavorite = isFavorite;
    
    [self loadThumbnailsForMessageObject:messageObject];
    
    return [messageObject autorelease];
}

- (TwitterMessageObject*)cacheMessageObjectAsDictionary:(NSDictionary*)message
{
    if (_messageObjects == nil)
        return nil;
    
    TwitterMessageObject *object = [self lookupTwitterMessageObject:message];
    if (object == nil)
    {
        object = [self mapTwitterMessageObject:message];
        if (object)
            [_messageObjects setObject:object forKey:object.messageId];
    }
    return object;
}

- (TwitterMessageObject*)cacheMessageObject:(TwitterMessageObject*)message
{
    if (_messageObjects == nil)
        return nil;
    if ([self lookupTwitterMessageObjectById:message.messageId] == nil)
    {
        [_messageObjects setObject:message forKey:message.messageId];
    }
    return message;
}

- (TwitterMessageObject*)lookupTwitterMessageObject:(NSDictionary*)message
{
    if (message == nil)
        return nil;
    return [self lookupTwitterMessageObjectById:[message objectForKey:@"id"]];
}

- (TwitterMessageObject*)lookupTwitterMessageObjectById:(NSString*)messageId
{
    if (_messageObjects == nil || messageId == nil)
        return nil;
    return [_messageObjects objectForKey:messageId];
}

- (TwitterMessageObject*)twitterMessageObjectByDictionary:(NSDictionary*)message
{
    TwitterMessageObject *object = [self lookupTwitterMessageObject:message];
    if (object == nil)
        object = [self cacheMessageObjectAsDictionary:message];
    
    BOOL isFavorite = NO;
    
    id fav = [message objectForKey:@"favorited"];
    if (fav && fav != (id)[NSNull null])
        isFavorite = [fav boolValue];
    
    object.isFavorite = isFavorite;
    
    return object;
}

@end

@implementation MessageListController(ThumbnailLoader)
- (void)loadThumbnailsForMessageObject:(TwitterMessageObject*)message
{
    if (message.yfrogLinks)
    {
        NSMutableDictionary *data = [NSMutableDictionary dictionary];
        
        [data setObject:message.messageId forKey:@"id"];
        [data setObject:message.yfrogLinks forKey:@"links"];
        
         [self performSelectorInBackground:@selector(loadThumbnailsThread:) withObject:data];
    }
}

- (void)loadThumbnailsThread:(NSDictionary*)data
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSString *messageId = [data objectForKey:@"id"];
    NSArray *links = [data objectForKey:@"links"];
    
    CGSize thumbSize = CGSizeMake(48., 48.);
    
    NSMutableArray *images = [[NSMutableArray alloc] init];

    for (NSString *link in links)
    {
        if (link)
        {
            @try 
            {
                //UIImage *image = loadAndScaleImage(link, thumbSize);
                
                //TEST
                
                NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:link]];
                if (!imageData)
                    continue;
                
                UIImage *image = [UIImage imageWithData:imageData];
                //END_TEST
                
                
                if (image)
                    [images addObject:image];
            }
            @catch (...) {
            }
        }
    }
    
    NSMutableDictionary *resultData = [[NSMutableDictionary alloc] initWithCapacity:2];
    
    [resultData setObject:messageId forKey:@"id"];
    [resultData setObject:images forKey:@"images"];
    
    [self performSelectorOnMainThread:@selector(thumbnailWasLoaded:) withObject:resultData waitUntilDone:NO];
    
    [pool release];
}

- (void)thumbnailWasLoaded:(NSDictionary*)result
{
    if (result)
    {
        NSArray *images = [result objectForKey:@"images"];
        NSString *messageId = [result objectForKey:@"id"];
        
        if (messageId && images)
        {
            TwitterMessageObject *object = [self lookupTwitterMessageObjectById:messageId];
            if (object)
                object.yfrogThumbnails = images;
            
            [images release];
        }
        [result release];
        
        [self.tableView reloadData];
    }
}

@end
