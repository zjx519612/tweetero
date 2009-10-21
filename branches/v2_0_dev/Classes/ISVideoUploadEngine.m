//
//  ISUploadEngine.m
//  Tweetero
//
//  Created by Sergey Shkrabak on 9/30/09.
//  Copyright 2009 Codeminders. All rights reserved.
//

#import "ISVideoUploadEngine.h"
#import "LocationManager.h"
#include "util.h"

#define IsValidStatusCode(s)        (((s) == 200) || ((s) == 201) || ((s) == 202))

#define IMAGESHACK_API_START        @"http://render.imageshack.us/renderapi/start"
#define kTweeteroDevKey             @""

#define ImageInfoRootName           @"imginfo"
#define UploadInfoRootName          @"uploadInfo"
#define UploadInfoLinkName          @"link"
#define UploadInfoPutName           @"putURL"
#define UploadInfoGetLengthName     @"getlengthURL"
#define ErrorRootName               @"error"
#define ErrorCodeName               @"code"

@interface ISVideoUploadEngine (Private)

- (void)doPhase:(int)phaseCode;
- (void)sendInitData;
- (void)uploadNextChunk;
- (void)resumeUpload;
- (void)clearResult;
- (BOOL)openConnection:(NSURLRequest *)request;
- (NSString *)errorMessage;

@end

@implementation ISVideoUploadEngine

@synthesize username;
@synthesize password;
@synthesize uploadData;
@synthesize linkUrl;
@synthesize putUrl;
@synthesize getLengthUrl;

- (id)initWithData:(NSData *)theData delegate:(id<ISVideoUploadEngineDelegate>) dlgt
{
    NSAssert([kTweeteroDevKey length] == 0, @"Dev key is empty");
    
    if ((self = [super init]))
    {
        uploadData = [theData retain];
        boundary = [NSString stringWithFormat:@"------%ld__%ld__%ld", random(), random(), random()];
        connection = nil;
        result = [[NSMutableData alloc] init];
        phase = ISUploadPhaseNone;
        delegate = dlgt;
    }
    return self;
}

- (void)dealloc
{
    self.linkUrl = nil;
    self.putUrl = nil;
    self.getLengthUrl = nil;
    
    if (connection)
        [connection release];
    [result release];
    [uploadData release];
    [super dealloc];
}

- (BOOL)upload
{
    BOOL success = NO;
    if (phase == ISUploadPhaseNone)
    {
        [self doPhase:ISUploadPhaseStart];
        success = YES;
    }
    return success;
}

// Cancel uploading process
- (void)cancel
{
    phase = ISUploadPhaseNone;
    currentDataLocation = 0;
    if (connection)
        [connection release];
    [self release];
}

#pragma mark NSURLConnection connection callbacks
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [delegate didStopUploading:self];
    
    // Resume upload
    [self doPhase:ISUploadPhaseResumeUpload];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (IsValidStatusCode(statusCode))
    {
        if (!(statusCode == 202 && phase == ISUploadPhaseUploadData))
        {
            NSXMLParser *parser = [[NSXMLParser alloc] initWithData:result];

            [parser setDelegate:self];
            [parser setShouldProcessNamespaces:NO];
            [parser setShouldReportNamespacePrefixes:NO];
            [parser setShouldResolveExternalEntities:NO];
            [parser parse];
            [parser release];
            
            [self clearResult];
        }
    }
    else
    {
        [self doPhase:ISUploadPhaseProcessError];
    }
}

#pragma mark NSURLConnection data receive
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    if ([response isKindOfClass:[NSHTTPURLResponse self]])
    {
        NSHTTPURLResponse *httpResp = (NSHTTPURLResponse*)response;
        statusCode = [httpResp statusCode];
        
        if (phase == ISUploadPhaseResumeUpload)
        {
        }
        else if (phase == ISUploadPhaseUploadData && statusCode == 202)
        {
            [delegate didFinishUploadingChunck:self uploadedSize:currentDataLocation totalSize:[uploadData length]];
            [self uploadNextChunk];
        }
    }
    [self clearResult];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if (phase == ISUploadPhaseResumeUpload)
    {
        char *ptr = (char *)malloc([data length] + 1);
        memcpy(ptr, [data bytes], [data length]);
        *(ptr + [data length]) = 0;
        
        NSString *str = [NSString stringWithCString:ptr];
        currentDataLocation = [str intValue];
        //currentDataLocation = 0;
        [delegate didResumeUploading:self];
        [self doPhase:ISUploadPhaseUploadData];
    }
    else
    {
        [result appendData:data];
    }
}

#pragma mark Parser functions
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    if ([elementName compare:UploadInfoRootName] == NSOrderedSame)
    {
        self.linkUrl = [attributeDict objectForKey:UploadInfoLinkName];
        self.putUrl = [attributeDict objectForKey:UploadInfoPutName];
        self.getLengthUrl = [attributeDict objectForKey:UploadInfoGetLengthName];
    }
    else if ([elementName compare:ErrorRootName] == NSOrderedSame)
    {
        id code = [attributeDict objectForKey:ErrorCodeName];
        if (code)
            statusCode = [code intValue];
    }
    else if ([elementName compare:ImageInfoRootName] == NSOrderedSame)
    {
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    if ([elementName compare:UploadInfoRootName] == NSOrderedSame)
    {
        [self doPhase:ISUploadPhaseUploadData];
    }
    else if ([elementName compare:ErrorRootName] == NSOrderedSame)
    {
        [self doPhase:ISUploadPhaseProcessError];
    }
    else if ([elementName compare:ImageInfoRootName] == NSOrderedSame)
    {
        [self doPhase:ISUploadPhaseFinish];
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
}

@end

@implementation ISVideoUploadEngine (Private)

- (void)doPhase:(int)phaseCode;
{
    phase = phaseCode;
    switch (phase)
    {
        case ISUploadPhaseStart:
            [self retain];
            [self sendInitData];
            break;
        case ISUploadPhaseUploadData:
            [delegate didStartUploading:self totalSize:[uploadData length]];
            [self uploadNextChunk];
            break;
        case ISUploadPhaseResumeUpload:
            [self resumeUpload];
            break;
        case ISUploadPhaseProcessError:
            [delegate didFailWithErrorMessage:self errorMessage:[self errorMessage]];
            currentDataLocation = 0;
            phase = ISUploadPhaseNone;
            [self release];
            break;
        case ISUploadPhaseFinish:
            [delegate didFinishUploadingChunck:self uploadedSize:currentDataLocation totalSize:[uploadData length]];
            [delegate didFinishUploading:self videoUrl:self.linkUrl];
            currentDataLocation = 0;
            phase = ISUploadPhaseNone;
            [self release];
    }
}

- (void)sendInitData
{
    NSMutableData *body = [NSMutableData data];
    
	[body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[@"Content-Disposition: form-data; name=\"filename\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[@"iPhoneMedia" dataUsingEncoding:NSUTF8StringEncoding]];
    
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Disposition: form-data; name=\"key\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[kTweeteroDevKey dataUsingEncoding:NSUTF8StringEncoding]];
    
	[body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[@"Content-Disposition: form-data; name=\"username\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[self.username dataUsingEncoding:NSUTF8StringEncoding]];
	
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[@"Content-Disposition: form-data; name=\"password\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[self.password dataUsingEncoding:NSUTF8StringEncoding]];

	if([[LocationManager locationManager] locationDefined])
	{
		[body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
		[body appendData:[@"Content-Disposition: form-data; name=\"tags\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
		[body appendData:[[NSString stringWithFormat:@"geotagged, geo:lat=%+.6f, geo:lon=%+.6f", 
                           [[LocationManager locationManager] latitude], [[LocationManager locationManager] longitude]] 
                          dataUsingEncoding:NSUTF8StringEncoding]];
	}

	[body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSURL *apiUrl = [NSURL URLWithString:IMAGESHACK_API_START];
    NSMutableURLRequest *request = tweeteroMutableURLRequest(apiUrl);
	NSString *multipartContentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
    
    [request setHTTPMethod:@"POST"];
	[request setTimeoutInterval:HTTPUploadTimeout];
    [request setValue:multipartContentType forHTTPHeaderField:@"Content-type"];
    [request setHTTPBody:body];
    
    [self clearResult];
    currentDataLocation = 0;
    
    BOOL validConnection = [self openConnection:request];
    if (!validConnection)
        [self doPhase:ISUploadPhaseProcessError];
}

- (void)uploadNextChunk
{
    NSRange range = {0, 1024};

    range.location = currentDataLocation;
    if ([uploadData length] <= range.location)
        return;
    
    if (([uploadData length] - range.location) < range.length)
        range.length = [uploadData length] - range.location;
    
    NSData *dataChunck = [uploadData subdataWithRange:range];
    
    NSString *contentLength = [NSString stringWithFormat:@"%d", [uploadData length]];
    NSString *contentRange = [NSString stringWithFormat:@"bytes %d-%d/%d", range.location, range.location + range.length-1, [uploadData length]];
    
    NSMutableURLRequest *request = tweeteroMutableURLRequest([NSURL URLWithString:self.putUrl]);
    [request setHTTPMethod:@"PUT"];
    [request setHTTPBody:dataChunck];
    [request setValue:contentLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:contentRange forHTTPHeaderField:@"Content-Range"];
    
    BOOL validConnection = [self openConnection:request];
    if (!validConnection)
        [self doPhase:ISUploadPhaseProcessError];
    
    currentDataLocation += range.length;
}

- (void)resumeUpload
{
    NSMutableURLRequest *request = tweeteroMutableURLRequest([NSURL URLWithString:self.getLengthUrl]);
    
    BOOL validConnection = [self openConnection:request];
    if (!validConnection)
        [self doPhase:ISUploadPhaseProcessError];
}

- (void)clearResult
{
    [result setLength:0];
}

- (BOOL)openConnection:(NSURLRequest *)request
{
    if (connection)
        [connection release];
    connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
    return (connection != nil);
}

- (NSString *)errorMessage
{
    switch (statusCode)
    {
        case 0: 
            return NSLocalizedString(@"Not Error", @"");
        case 404: 
            return NSLocalizedString(@"URL you are requesting is not found or command is not recognized", @"");
        case 405: 
            return NSLocalizedString(@"Method you are calling is not supported", @"");
        case 400: 
            return NSLocalizedString(@"Your request is bad formed, for example: missing or wrong UUID, invalid content-length.", @"");
        case 403: 
            return NSLocalizedString(@"Wrong developer key", @"");
        default:
            return NSLocalizedString(@"Unknown error", @"");
    }
}

@end
