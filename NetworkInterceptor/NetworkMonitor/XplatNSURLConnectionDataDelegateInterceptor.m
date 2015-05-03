//
//  XplatNSURLConnectionDataDelegateInterceptor.m
//  NetworkInterceptor
//
//  Created by George Taskos on 6/17/14.
//  Copyright (c) 2014 Xplat Solutions. All rights reserved.
//

#import "XplatNSURLConnectionDataDelegateInterceptor.h"
#import "NetworkModel.h"
#import "XplatNetworkMonitorClient.h"
#import "InterceptorLog.h"
#import "XPLLogging.h"

@interface XplatNSURLConnectionDataDelegateInterceptor () <NSURLConnectionDelegate, NSURLConnectionDataDelegate, NSURLConnectionDownloadDelegate>

@property (strong) id target;
@property (strong) NetworkModel* networkData;
@property (nonatomic, assign) NSUInteger dataSize;

@end

@implementation XplatNSURLConnectionDataDelegateInterceptor

- (id) initAndInterceptFor:(id)target withRequest:(NSURLRequest *)request
    {
    NSString* logMessage = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];
    INTERCEPTOR_LOG(logMessage);
    
    if (self = [super init])
        {
        self.target = target;
        self.dataSize = 0;
        _isConnectionAlive = YES;
        
        NetworkModel* networkData = [NetworkModel new];
        [networkData appendStartTime];
        [networkData appendRequestInfo:request];
        self.networkData = networkData;
        }
        
    return self;
    }

- (BOOL) respondsToSelector:(SEL)aSelector
    {
    NSString* selectorAsString = NSStringFromSelector(aSelector);
    BOOL weRespond = NO;
    BOOL targetResponds = NO;
    BOOL answerResponds = NO;
 
    if( [selectorAsString isEqualToString:@"connection:didFailWithError:"] ||
        [selectorAsString isEqualToString:@"connectionDidFinishLoading:"] ||
        [selectorAsString isEqualToString:@"connection:didReceiveResponse:"])
        {
        answerResponds = YES;
        }
    else if([selectorAsString hasPrefix:@"connection"])
        {
        if(self.target)
            {
            // since we're the delegate from the NSURLConnection's perspective,
            // both us (the interceptor) and the real delegate must be able
            // to respond to the message for us to say that we respond to the
            // message
            weRespond = [[self class] instancesRespondToSelector:aSelector];
            targetResponds = [self.target respondsToSelector:aSelector];
            answerResponds = weRespond && targetResponds;
            
            if(!weRespond && targetResponds)
                {
                XPLLogError( @"+++++ HOLE: real delegate responds but we don't: '%@'", selectorAsString);
                }
            }
        }
    else
        {
        answerResponds = [[self class] instancesRespondToSelector:aSelector];
        }

    return answerResponds;
    }

#pragma mark - NSURLConnectionDelegate

- (void) connection:(NSURLConnection*)connection didFailWithError:(NSError*)error
    {
    NSString* logMessage = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];
    INTERCEPTOR_LOG(logMessage);
    
    _isConnectionAlive = NO;
    XplatNetworkMonitorClient* monitoringClient = [XplatNetworkMonitorClient sharedInstance];
    
    [self.networkData appendStartTime];

    if (self.target && [self.target respondsToSelector:@selector(connection:didFailWithError:)])
        {
        [self.target connection:connection didFailWithError:error];
        }
    
    [self.networkData appendWithError:error];
    [monitoringClient notifyObserverWithNetworkData:self.networkData];
    
    self.networkData = nil;
    }

- (BOOL) connectionShouldUseCredentialStorage:(NSURLConnection*)connection
    {
    NSString* logMessage = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];
    INTERCEPTOR_LOG(logMessage);
    
    if (self.target && [self.target respondsToSelector:@selector(connectionShouldUseCredentialStorage:)])
        {
        return [self.target connectionShouldUseCredentialStorage:connection];
        }
        
    return NO;
    }

- (void) connection:(NSURLConnection*) connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge*) challenge
    {
    NSString* logMessage = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];
    INTERCEPTOR_LOG(logMessage);
    
    if (self.target && [self.target respondsToSelector:@selector(connection:willSendRequestForAuthenticationChallenge:)])
        {
        [self.target connection:connection willSendRequestForAuthenticationChallenge:challenge];
        }
    }

// Deprecated authentication delegates - should these be supported?
- (BOOL) connection:(NSURLConnection*)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace*)protectionSpace
    {
    NSString* logMessage = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];
    INTERCEPTOR_LOG(logMessage);

    if (self.target && [self.target respondsToSelector:@selector(connection:canAuthenticateAgainstProtectionSpace:)])
        {
        return [self.target connection:connection canAuthenticateAgainstProtectionSpace:protectionSpace];
        }
    
    return NO;
    }

- (void) connection:(NSURLConnection*)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge*)challenge
    {
    NSString* logMessage = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];
    INTERCEPTOR_LOG(logMessage);

    if (self.target && [self.target respondsToSelector:@selector(connection:didReceiveAuthenticationChallenge:)])
        {
        [self.target connection:connection didReceiveAuthenticationChallenge:challenge];
        }
    }

- (void) connection:(NSURLConnection*)connection didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge*)challenge
    {
    NSString* logMessage = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];
    INTERCEPTOR_LOG(logMessage);

    if (self.target && [self.target respondsToSelector:@selector(connection:didCancelAuthenticationChallenge:)])
        {
        [self.target connection:connection didCancelAuthenticationChallenge:challenge];
        }
    }

#pragma mark - NSURLConnectionDataDelegate

- (NSURLRequest *) connection:(NSURLConnection*)connection willSendRequest:(NSURLRequest*)request redirectResponse:(NSURLResponse*)response
    {
    NSString* logMessage = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];
    INTERCEPTOR_LOG(logMessage);

    if (self.target && [self.target respondsToSelector:@selector(connection:willSendRequest:redirectResponse:)])
        {
        return [self.target connection:connection willSendRequest:request redirectResponse:response];
        }
    else
        {
        return request;
        }
    }

- (void) connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse*)response
    {
    NSString* logMessage = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];
    INTERCEPTOR_LOG(logMessage);

    [self.networkData appendResponseInfo:response];

    if (self.target && [self.target respondsToSelector:@selector(connection:didReceiveResponse:)])
        {
        [self.target connection:connection didReceiveResponse:response];
        }
    }

- (void) connection:(NSURLConnection*)connection didReceiveData:(NSData*)data
    {
    NSString* logMessage = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];
    INTERCEPTOR_LOG(logMessage);
    
    if ([data length] > 0)
        {
        self.dataSize += [data length];
        }

    if (self.target && [self.target respondsToSelector:@selector(connection:didReceiveData:)])
        {
        [self.target connection:connection didReceiveData:data];
        }
    }

- (void) connection:(NSURLConnection*)connection didReceiveData:(NSData*)data lengthReceived:(long long)lengthReceived
    {
    NSString* logMessage = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];
    INTERCEPTOR_LOG(logMessage);
    
    if (self.target && [self.target respondsToSelector:@selector(connection:didReceiveData:lengthReceived:)])
        {
        [self.target connection:connection didReceiveData:data lengthReceived:lengthReceived];
        }
    }

- (void)connection:(NSURLConnection*)connection didReceiveDataArray:(NSArray*)dataArray
    {
    NSString* logMessage = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];
    INTERCEPTOR_LOG(logMessage);

    if (self.target && [self.target respondsToSelector:@selector(connection:didReceiveDataArray:)])
        {
        [self.target connection:connection didReceiveDataArray:dataArray];
        }
    }

- (NSInputStream*) connection:(NSURLConnection*)connection needNewBodyStream:(NSURLRequest*)request
    {
    NSString* logMessage = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];
    INTERCEPTOR_LOG(logMessage);

    if (self.target && [self.target respondsToSelector:@selector(connection:needNewBodyStream:)])
        {
        return [self.target connection:connection needNewBodyStream:request];
        }
    
    return nil;
    }

- (void) connection:(NSURLConnection *) connection didSendBodyData:(NSInteger)bytesWritten
                                                totalBytesWritten:(NSInteger)totalBytesWritten
                                        totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
    {
    NSString* logMessage = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];
    INTERCEPTOR_LOG(logMessage);

    if (self.target && [self.target respondsToSelector:@selector(connection:didSendBodyData:totalBytesWritten:totalBytesExpectedToWrite:)])
        {
        [self.target connection:connection
                didSendBodyData:bytesWritten
              totalBytesWritten:totalBytesWritten
      totalBytesExpectedToWrite:totalBytesExpectedToWrite];
        }
    }

- (NSCachedURLResponse*) connection:(NSURLConnection*)connection willCacheResponse:(NSCachedURLResponse*)cachedResponse
    {
    NSString* logMessage = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];
    INTERCEPTOR_LOG(logMessage);

    if (self.target && [self.target respondsToSelector:@selector(connection:willCacheResponse:)])
        {
        return [self.target connection:connection willCacheResponse:cachedResponse];
        }
    
    return cachedResponse;
    }

- (void) connectionDidFinishLoading:(NSURLConnection*)connection
    {
    NSString* logMessage = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];
    INTERCEPTOR_LOG(logMessage);

    _isConnectionAlive = NO;

    [self.networkData appendEndTime];
    
    if (self.target && [self.target respondsToSelector:@selector(connectionDidFinishLoading:)])
        {
        [self.target connectionDidFinishLoading:connection];
        }
    
    [self.networkData appendResponseDataSize:self.dataSize];
    [[XplatNetworkMonitorClient sharedInstance] notifyObserverWithNetworkData:self.networkData];
    self.networkData = nil;
    }

- (void) connection:(NSURLConnection*)connection
       didWriteData:(long long)bytesWritten
  totalBytesWritten:(long long)totalBytesWritten
 expectedTotalBytes:(long long)expectedTotalBytes
    {
    NSString* logMessage = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];
    INTERCEPTOR_LOG(logMessage);

    if (self.target && [self.target respondsToSelector:@selector(connection:didWriteData:totalBytesWritten:expectedTotalBytes:)])
        {
        [self.target connection:connection
                     didWriteData:bytesWritten
                totalBytesWritten:totalBytesWritten
               expectedTotalBytes:expectedTotalBytes];
        }
    }

- (void) connectionDidResumeDownloading:(NSURLConnection*)connection
                      totalBytesWritten:(long long)totalBytesWritten
                     expectedTotalBytes:(long long)expectedTotalBytes
    {
    NSString* logMessage = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];
    INTERCEPTOR_LOG(logMessage);

    if (self.target && [self.target respondsToSelector:@selector(connectionDidResumeDownloading:totalBytesWritten:expectedTotalBytes:)])
        {
        [self.target connectionDidResumeDownloading:connection totalBytesWritten:totalBytesWritten expectedTotalBytes:expectedTotalBytes];
        }
    }

- (void) connectionDidFinishDownloading:(NSURLConnection*)connection destinationURL:(NSURL*)destinationURL
    {
    NSString* logMessage = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];
    INTERCEPTOR_LOG(logMessage);

    if (self.target && [self.target respondsToSelector:@selector(connectionDidFinishDownloading:destinationURL:)])
        {
        [self.target connectionDidFinishDownloading:connection destinationURL:destinationURL];
        }
    }

- (void)recordStartTime
    {
    NSString* logMessage = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];
    INTERCEPTOR_LOG(logMessage);
    
    [self.networkData appendStartTime];
    }

@end
