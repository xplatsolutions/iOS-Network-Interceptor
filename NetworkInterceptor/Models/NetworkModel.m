//
//  NetworkModel.m
//  NetworkInterceptor
//
//  Created by G.Tas on 3/6/14.
//  Copyright (c) 2014 Xplat Solutions. All rights reserved.
//

#import "NetworkModel.h"
#import "NSDate+Xplat.h"
#import "InterceptorLog.h"
#import "XplatNetworkMonitorClient.h"

@import QuartzCore;

static const NSUInteger kMaxUrlLength = 200;

static NSDate* startupTimeDate;
static CFTimeInterval startupTimeSeconds;

@interface NetworkModel ()

@end

@implementation NetworkModel

#pragma mark -
#pragma mark Static Methods

+ (void) load
    {
    startupTimeDate = [NSDate date];
    startupTimeSeconds = CACurrentMediaTime();
    }

#pragma mark -
#pragma mark Initializers

- (id) init
    {
    if (self = [super init])
        {
        self.statusCode = @(0);
        self.requestLength = @(0);
        self.responseLength = @(0);
        self.exception = @"NA";
        self.latency = @(0);
        self.url = @"NA";
        self.protocol = @"NA";
        }
    return self;
    }

#pragma mark - 
#pragma mark Private Methods


- (void) populateStartTime:(CFTimeInterval)started ended:(CFTimeInterval)ended
    {
    NSDate* start = [NetworkModel secondsTimeToDate:started];
    NSDate* end = [NetworkModel secondsTimeToDate:ended];
    [self appendStartTimeStamp:start endTimeStamp:end];
    }

+ (NSDate*)secondsTimeToDate:(CFTimeInterval)secondsValue
    {
    CFTimeInterval secondsSinceAppStart = secondsValue - startupTimeSeconds;
    return [startupTimeDate dateByAddingTimeInterval:secondsSinceAppStart];
    }

+ (CFTimeInterval)dateToSecondsTime:(NSDate*)date
    {
    NSTimeInterval timeIntervalSecondsSinceStartup =
        [date timeIntervalSinceDate:startupTimeDate];
    return timeIntervalSecondsSinceStartup;
    }

- (void) appendStartTimeStamp:(NSDate*)started endTimeStamp:(NSDate*)ended
    {
    if (started && ended)
        {
        BOOL datesPassSanityCheck = NO;
        
        NSDate* earlier = [started earlierDate:ended];
        if (earlier != started)
            {
            if (NSOrderedSame == [started compare:ended])
                {
                datesPassSanityCheck = YES;
                }
            else
                {
                XPLLogDebug(@"NET_MONITOR end time=%@ precedes start time=%@", ended, started);
                }
            }
        else
            {
            datesPassSanityCheck = YES;
            }
        
        if (datesPassSanityCheck)
            {
            NSString* startedTimestampMillis =
                [NSDate stringFromMilliseconds:[started dateAsMilliseconds]];
            self.startTime = startedTimestampMillis;
            NSNumberFormatter* formatter = [[NSNumberFormatter alloc] init];
            [formatter setNumberStyle:NSNumberFormatterNoStyle];
            self.endTime = [formatter numberFromString:[NSDate stringFromMilliseconds:[ended dateAsMilliseconds]]];
    
            const NSTimeInterval latencySeconds = [ended timeIntervalSinceDate:started];
            const long latencyMillis = latencySeconds * 1000;
            self.latency = @(latencyMillis);
            }
        }
    }

- (void) appendResponseDataSize:(NSUInteger)dataSize
    {
    _contentLength = [NSNumber numberWithInteger:dataSize];
    }

- (void) appendWithURL:(NSURL*)theURL
    {
    _protocol = [theURL.scheme caseInsensitiveCompare:@"http"] ? @"HTTP" : @"HTTPS";
    
    NSString* trimedURL = [theURL.resourceSpecifier substringFromIndex:2];
    NSString* urlString = trimedURL ? trimedURL : theURL.absoluteString;
    [self appendWithURLString:urlString];
    }

- (void) appendWithURLString:(NSString*)urlString
    {
    if ([urlString length] > kMaxUrlLength)
        {
        _url = [urlString substringToIndex:kMaxUrlLength];
        }
    else
        {
        _url = [urlString copy];
        }
    }

#pragma mark - Public Methods

- (void) appendWithStatusCode: (NSNumber*)statusCode
    {
    switch (statusCode.intValue)
        {
        case 200:
        case 201:
        case 202:
        case 203:
        case 204:
        case 205:
        case 206:
            self.failed = NO;
            break;
        default:
            self.failed = YES;
            self.exception = [NSHTTPURLResponse localizedStringForStatusCode:statusCode.integerValue];
            break;
        }
    }

- (void) appendStartTime
    {
    _startNetTime = [NSDate date];
    }

- (void) appendEndTime
    {
    _endNetTime = [NSDate date];
    [self appendStartTimeStamp:self.startNetTime endTimeStamp:self.endNetTime];
    }

- (void) appendRequestInfo:(NSURLRequest*)request
    {
    [self appendWithURL:request.URL];
    _requestLength = [request HTTPBody] ? @([request HTTPBody].length) : @(0);
    }

- (void) appendResponseInfo:(NSURLResponse*)response
    {
    if ([response isKindOfClass:[NSHTTPURLResponse class]])
        {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*) response;
        NSNumberFormatter* formatter = [[NSNumberFormatter alloc] init];
        [formatter setNumberStyle:NSNumberFormatterNoStyle];
        self.statusCode = @(httpResponse.statusCode);
        [self appendWithStatusCode:self.statusCode];

        self.responseLength = [response expectedContentLength] == NSURLResponseUnknownLength ? @(0) : @([httpResponse expectedContentLength]);
        }
    }

- (void) appendResponseData:(NSData*)data
    {
    [self appendResponseDataSize:[data length]];
    }

- (void) appendWithError:(NSError*)error
    {
    if (error)
        {
        @try
            {
            self.exception = [error localizedDescription];
            }
        @catch (NSException *exception)
            {
            XPLLogError(@"MONITOR_CLIENT unable to capture networking error: %@",
                          [exception reason]);
            }
        }
    }

- (void) debugPrint
    {
    INTERCEPTOR_LOG(self.description);
    }

#pragma mark - Overrides

- (NSString*) description
    {
    NSString* theDescription = [NSString stringWithFormat:@"========= Start NetworkModel ========\nurl= '%@'\nstartTime= '%@'\nendTime= '%@'\nlatency= '%@'\nexception= '%@'\nhttpStatusCode= '%@'\nresponseDataSize= '%@'\n========= End NetworkModel ========",
        self.url, self.startTime, self.endTime, self.latency, self.exception, self.statusCode, self.contentLength];
    return theDescription;
    }

@end
