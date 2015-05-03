//
//  XplatNSURLSessionDataDelegateInterceptor.m
//  NetworkInterceptor
//
//  Created by George Taskos on 6/18/14.
//  Copyright (c) 2014 Xplat Solutions. All rights reserved.
//

#import "XplatNSURLSessionDataDelegateInterceptor.h"
#import "InterceptorLog.h"
#import "XplatNetworkMonitorClient.h"
#import "XplatNSURLSessionDataTaskManager.h"
#import "NetworkModel.h"

@interface XplatNSURLSessionDataDelegateInterceptor ()

@property (strong) id target;
@property (strong) NSURL* url;
@property (strong) NSURLRequest* request;

@end

@implementation XplatNSURLSessionDataDelegateInterceptor

- (id) initAndInterceptFor: (id)theTarget
    {
    if (self = [super init])
        {
        self.target = theTarget;
        }
    return self;
    }

#pragma mark -
#pragma mark NSURLSessionDelegate methods

- (void) URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error
    {
    NSString* logMessage = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];
    INTERCEPTOR_LOG(logMessage);
    
    if (self.target && [self.target respondsToSelector:@selector(URLSession:didBecomeInvalidWithError:)])
        {
        [self.target URLSession:session didBecomeInvalidWithError:error];
        }
    }

- (void) URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler
    {
    NSString* logMessage = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];
    INTERCEPTOR_LOG(logMessage);
    
    if (self.target && [self.target respondsToSelector:@selector(URLSession:didReceiveChallenge:completionHandler:)])
        {
        [self.target URLSession:session didReceiveChallenge:challenge completionHandler:completionHandler];
        }
    else
        {
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, NULL);
        }
    }

- (void) URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session
    {
    NSString* logMessage = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];
    INTERCEPTOR_LOG(logMessage);
    
    if (self.target && [self.target respondsToSelector:@selector(URLSessionDidFinishEventsForBackgroundURLSession:)])
        {
        [self.target URLSessionDidFinishEventsForBackgroundURLSession:session];
        }
    }

#pragma mark -
#pragma mark NSURLSessionDataDelegate Methods

- (void) URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
    {
    NSString* logMessage = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];
    INTERCEPTOR_LOG(logMessage);
    
    if (response != nil)
        {
        XplatNSURLSessionDataTaskManager* dataTaskManager = [XplatNSURLSessionDataTaskManager sharedInstance];
        XplatNSURLSessionDataTaskInfo* sessionDataTaskInfo = [dataTaskManager dataTaskInfoForTask:dataTask];
        if (sessionDataTaskInfo)
            {
            [sessionDataTaskInfo.networkData appendResponseInfo:response];
            }
        }
    
    if (self.target && [self.target respondsToSelector:@selector(URLSession:dataTask:didReceiveResponse:completionHandler:)])
        {
        [self.target URLSession:session dataTask:dataTask didReceiveResponse:response completionHandler:completionHandler];
        }
    else
        {
        completionHandler(NSURLSessionResponseAllow);
        }
    }

- (void) URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didBecomeDownloadTask:(NSURLSessionDownloadTask *)downloadTask
    {
    NSString* logMessage = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];
    INTERCEPTOR_LOG(logMessage);
    
    XplatNSURLSessionDataTaskManager* dataTaskManager = [XplatNSURLSessionDataTaskManager sharedInstance];
    [dataTaskManager removeDataTaskInfoForTask:dataTask];
    
    if (self.target && [self.target respondsToSelector:@selector(URLSession:dataTask:didBecomeDownloadTask:)])
        {
        [self.target URLSession:session dataTask:dataTask didBecomeDownloadTask:downloadTask];
        }
    }

- (void) URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
    {
    NSString* logMessage = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];
    INTERCEPTOR_LOG(logMessage);
    
    if (data && (data.length > 0))
        {
        XplatNSURLSessionDataTaskManager* dataTaskManager = [XplatNSURLSessionDataTaskManager sharedInstance];
        XplatNSURLSessionDataTaskInfo* sessionDataTaskInfo = [dataTaskManager dataTaskInfoForTask:dataTask];
        
        if (sessionDataTaskInfo)
            {
            sessionDataTaskInfo.dataSize += data.length;
            }
        }
    
    if (self.target && [self.target respondsToSelector:@selector(URLSession:dataTask:didReceiveData:)])
        {
        [self.target URLSession:session dataTask:dataTask didReceiveData:data];
        }
    }

- (void) URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask willCacheResponse:(NSCachedURLResponse *)proposedResponse completionHandler:(void (^)(NSCachedURLResponse *))completionHandler
    {
    NSString* logMessage = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];
    INTERCEPTOR_LOG(logMessage);
    
    if (self.target && [self.target respondsToSelector:@selector(URLSession:dataTask:willCacheResponse:completionHandler:)])
        {
        [self.target URLSession:session dataTask:dataTask willCacheResponse:proposedResponse completionHandler:completionHandler];
        }
    else
        {
        completionHandler(proposedResponse);
        }
    }

#pragma mark -
#pragma mark NSURLSessionTaskDelegate

- (void) URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
    {
    NSString* logMessage = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];
    INTERCEPTOR_LOG(logMessage);
    
    XplatNSURLSessionDataTaskManager* dataTaskManager = [XplatNSURLSessionDataTaskManager sharedInstance];
    XplatNSURLSessionDataTaskInfo* sessionDataTaskInfo = [dataTaskManager dataTaskInfoForTask:task];
    
    if (sessionDataTaskInfo)
        {
        [sessionDataTaskInfo.networkData appendEndTime];
        [sessionDataTaskInfo.networkData appendResponseDataSize:sessionDataTaskInfo.dataSize];
        [sessionDataTaskInfo.networkData appendWithError:error];
        
        XplatNetworkMonitorClient* monitoringClient = [XplatNetworkMonitorClient sharedInstance];
        [monitoringClient notifyObserverWithNetworkData:sessionDataTaskInfo.networkData];
        
        [dataTaskManager removeDataTaskInfoForTask:task];
        }
        
    if (self.target && [self.target respondsToSelector:@selector(URLSession:task:didCompleteWithError:)])
        {
        [self.target URLSession:session task:task didCompleteWithError:error];
        }
    }

- (void) URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler
    {
    NSString* logMessage = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];
    INTERCEPTOR_LOG(logMessage);
    
    if (self.target && [self.target respondsToSelector:@selector(URLSession:task:didReceiveChallenge:completionHandler:)])
        {
        [self.target URLSession:session task:task didReceiveChallenge:challenge completionHandler:completionHandler];
        }
    else
        {
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, NULL);
        }
    }

- (void) URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend
    {
    NSString* logMessage = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];
    INTERCEPTOR_LOG(logMessage);
    
    if (self.target && [self.target respondsToSelector:@selector(URLSession:task:didSendBodyData:totalBytesSent:totalBytesExpectedToSend:)])
        {
        [self.target URLSession:session task:task didSendBodyData:bytesSent totalBytesSent:totalBytesSent totalBytesExpectedToSend:totalBytesExpectedToSend];
        }
    }

- (void) URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task needNewBodyStream:(void (^)(NSInputStream *))completionHandler
    {
    NSString* logMessage = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];
    INTERCEPTOR_LOG(logMessage);
    
    if (self.target && [self.target respondsToSelector:@selector(URLSession:task:needNewBodyStream:)])
        {
        [self.target URLSession:session task:task needNewBodyStream:completionHandler];
        }
    else
        {
        NSInputStream* inputStream;
        
        if (task.originalRequest.HTTPBodyStream && [task.originalRequest.HTTPBodyStream conformsToProtocol:@protocol(NSCopying)])
            {
            inputStream = [task.originalRequest.HTTPBodyStream copy];
            }
        
        completionHandler(inputStream);
        }
    }

- (void) URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest *))completionHandler
    {
    NSString* logMessage = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];
    INTERCEPTOR_LOG(logMessage);
    
    if (self.target && [self.target respondsToSelector:@selector(URLSession:task:willPerformHTTPRedirection:newRequest:completionHandler:)])
        {
        [self.target URLSession:session task:task willPerformHTTPRedirection:response newRequest:request completionHandler:completionHandler];
        }
    else
        {
        completionHandler(request);
        }
    }

#pragma mark -
#pragma mark NSURLSessionDownloadDelegate

- (void) URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
    {
    NSString* logMessage = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];
    INTERCEPTOR_LOG(logMessage);
    
    if (self.target && [self.target respondsToSelector:@selector(URLSession:downloadTask:didFinishDownloadingToURL:)])
        {
        [self.target URLSession:session downloadTask:downloadTask didFinishDownloadingToURL:location];
        }
    }

- (void) URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes
    {
    NSString* logMessage = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];
    INTERCEPTOR_LOG(logMessage);
    
    if (self.target && [self.target respondsToSelector:@selector(URLSession:downloadTask:didResumeAtOffset:expectedTotalBytes:)])
        {
        [self.target URLSession:session downloadTask:downloadTask didResumeAtOffset:fileOffset expectedTotalBytes:expectedTotalBytes];
        }
    }

- (void) URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
    {
    NSString* logMessage = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];
    INTERCEPTOR_LOG(logMessage);
    
    if (self.target && [self.target respondsToSelector:@selector(URLSession:downloadTask:didWriteData:totalBytesWritten:totalBytesExpectedToWrite:)])
        {
        [self.target URLSession:session downloadTask:downloadTask didWriteData:bytesWritten totalBytesWritten:totalBytesWritten totalBytesExpectedToWrite:totalBytesExpectedToWrite];
        }
    }


#pragma mark -
#pragma mark Private Methods



@end
