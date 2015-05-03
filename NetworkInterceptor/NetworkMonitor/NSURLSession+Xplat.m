//
//  NSURLSession+Xplat.m
//  NetworkInterceptor
//
//  Created by George Taskos on 6/13/14.
//  Copyright (c) 2014 Xplat Solutions. All rights reserved.
//

#import <objc/runtime.h>

#import "NSURLSession+Xplat.h"
#import "XplatNSURLSessionDataDelegateInterceptor.h"
#import "InterceptorLog.h"
#import "XplatNSURLSessionDataTaskManager.h"
#import "NetworkModel.h"
#import "XplatNetworkMonitorClient.h"
#import "XPLLogging.h"
#import "XplatNSURLSessionDownloadTaskInfo.h"
#import "XplatNSURLSessionDownloadTaskManager.h"
#import "XplatURLBlackListManager.h"
#import "NSMutableURLRequest+Xplat.h"

// Original function pointers of NSURLSession

typedef void (^DataTaskCompletionBlock)(NSData*, NSURLResponse*, NSError*);
typedef void (^DownloadTaskCompletionBlock)(NSURL*, NSURLResponse*, NSError*);

static NSURLSession* (*OriginalNSURLSessionWithConfigurationDelegateAndQueue)(id, SEL, NSURLSessionConfiguration*, id, NSOperationQueue*);
static void (*OriginalNSURLSessionTaskResume)(id, SEL);
static void (*OriginalNSCFLocalDataTaskResume)(id, SEL);
static NSURLSessionDataTask* (*OriginalNSCFURLSessionDataTaskWithRequestCompletionHandler)(id, SEL, NSURLRequest*, DataTaskCompletionBlock);
static NSURLSessionDownloadTask* (*OriginalNSCFURLSessionDownloadTaskWithRequestCompletionHandler)(id, SEL, NSURLRequest*, DownloadTaskCompletionBlock);
static NSURLSessionUploadTask* (*OriginalNSCFURLSessionUploadTaskWithRequestFromDataCompletionHandler)(id, SEL, NSURLRequest*, NSData*, DataTaskCompletionBlock);

static NSURLSession* XplatNSURLSessionWithConfigurationDelegateAndQueue(id self, SEL _cmd, NSURLSessionConfiguration* configuration, id delegate, NSOperationQueue* queue)
    {
    NSString* logMessage = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];
    INTERCEPTOR_LOG(logMessage);
    
    if (delegate != nil)
        {
        XplatNSURLSessionDataDelegateInterceptor* interceptor = [[XplatNSURLSessionDataDelegateInterceptor alloc] initAndInterceptFor:delegate];
        return OriginalNSURLSessionWithConfigurationDelegateAndQueue(self, _cmd, configuration, interceptor, queue);
        }
    else
        {
        return OriginalNSURLSessionWithConfigurationDelegateAndQueue(self, _cmd, configuration, delegate, queue);
        }
    }

static NSURLSessionDataTask* XplatNSCFURLSessionDataTaskWithRequestCompletionHandler(id self, SEL _cmd, NSURLRequest* request, DataTaskCompletionBlock completionHandler)
    {
    NSString* logMessage = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];
    INTERCEPTOR_LOG(logMessage);
    
    NSMutableURLRequest* mutableRequest = [request mutableCopy];
    XplatURLBlackListManager* urlBlackListManager = [XplatURLBlackListManager sharedInstance];
    NSURLSessionDataTask* sessionDataTask;
    if (!mutableRequest.isXplatRequest &&
        ![urlBlackListManager containsURL:request.URL])
        {
        XplatNSURLSessionDataTaskManager* dataTaskManager = [XplatNSURLSessionDataTaskManager sharedInstance];
        id dataTaskIdentifier = [dataTaskManager generateIdentifierForDataTask];
    
        if (completionHandler)
            {
            sessionDataTask = OriginalNSCFURLSessionDataTaskWithRequestCompletionHandler(self, _cmd, request, ^(NSData* data, NSURLResponse* response, NSError* error)
                {
                XplatNSURLSessionDataTaskInfo* dataTaskInfo = [dataTaskManager dataTaskInfoForIdentifier:dataTaskIdentifier];
                [dataTaskInfo.networkData appendEndTime];
                [dataTaskInfo.networkData appendResponseData:data];
                [dataTaskInfo.networkData appendResponseInfo:response];
                [dataTaskInfo.networkData appendWithError:error];

                XplatNetworkMonitorClient* monitoringClient = [XplatNetworkMonitorClient sharedInstance];
                [monitoringClient notifyObserverWithNetworkData:dataTaskInfo.networkData];
            
                if (dataTaskInfo.completionHandler)
                    {
                    dataTaskInfo.completionHandler(data, response, error);
                    }
                
                [dataTaskManager removeDataTaskInfoForIdentifier:dataTaskIdentifier];
                });
            }
        else
            {
            sessionDataTask = OriginalNSCFURLSessionDataTaskWithRequestCompletionHandler(self, _cmd, request, completionHandler);
            }
    
        XplatNSURLSessionDataTaskInfo* dataTaskInfo = [XplatNSURLSessionDataTaskInfo new];
        NetworkModel* networkData = [NetworkModel new];
        [networkData appendRequestInfo:request];
        dataTaskInfo.networkData = networkData;
        dataTaskInfo.sessionDataTask = sessionDataTask;
        dataTaskInfo.completionHandler = completionHandler;
        dataTaskInfo.key = dataTaskIdentifier;
        [dataTaskManager registerDataTaskInfo:dataTaskInfo withIdentifier:dataTaskIdentifier];
        }
    else
        {
        sessionDataTask = OriginalNSCFURLSessionDataTaskWithRequestCompletionHandler(self, _cmd, request, completionHandler);
        }
    
    return sessionDataTask;
    }

static NSURLSessionUploadTask* XplatNSCFURLSessionUploadTaskWithRequestFromDataCompletionHandler(id self, SEL _cmd, NSURLRequest* request, NSData* data, DataTaskCompletionBlock completionHandler)
    {
    NSString* logMessage = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];
    INTERCEPTOR_LOG(logMessage);
    
    NSMutableURLRequest* mutableRequest = [request mutableCopy];
    XplatURLBlackListManager* urlBlackListManager = [XplatURLBlackListManager sharedInstance];
    NSURLSessionUploadTask* sessionUploadTask;
    if (!mutableRequest.isXplatRequest &&
        ![urlBlackListManager containsURL:request.URL])
        {
        XplatNSURLSessionDataTaskManager* dataTaskManager = [XplatNSURLSessionDataTaskManager sharedInstance];
        id dataTaskIdentifier = [dataTaskManager generateIdentifierForDataTask];
    
        if (completionHandler)
            {
            sessionUploadTask = OriginalNSCFURLSessionUploadTaskWithRequestFromDataCompletionHandler(self, _cmd, request, data, ^(NSData* data, NSURLResponse* response, NSError* error)
                {
                XplatNSURLSessionDataTaskInfo* dataTaskInfo = [dataTaskManager dataTaskInfoForIdentifier:dataTaskIdentifier];
                [dataTaskInfo.networkData appendEndTime];
                [dataTaskInfo.networkData appendResponseData:data];
                [dataTaskInfo.networkData appendResponseInfo:response];
                [dataTaskInfo.networkData appendWithError:error];

                XplatNetworkMonitorClient* monitoringClient = [XplatNetworkMonitorClient sharedInstance];
                [monitoringClient notifyObserverWithNetworkData:dataTaskInfo.networkData];
            
                if (dataTaskInfo.completionHandler)
                    {
                    dataTaskInfo.completionHandler(data, response, error);
                    }
                
                [dataTaskManager removeDataTaskInfoForIdentifier:dataTaskIdentifier];
                });
            }
        else
            {
            sessionUploadTask = OriginalNSCFURLSessionUploadTaskWithRequestFromDataCompletionHandler(self, _cmd, request, data, completionHandler);
            }
    
        XplatNSURLSessionDataTaskInfo* dataTaskInfo = [XplatNSURLSessionDataTaskInfo new];
        NetworkModel* networkData = [NetworkModel new];
        [networkData appendRequestInfo:request];
        dataTaskInfo.networkData = networkData;
        dataTaskInfo.sessionDataTask = sessionUploadTask;
        dataTaskInfo.completionHandler = completionHandler;
        dataTaskInfo.key = dataTaskIdentifier;
        [dataTaskManager registerDataTaskInfo:dataTaskInfo withIdentifier:dataTaskIdentifier];
        }
    else
        {
        sessionUploadTask = OriginalNSCFURLSessionUploadTaskWithRequestFromDataCompletionHandler(self, _cmd, request, data, completionHandler);
        }
        
    return sessionUploadTask;
    }

static NSURLSessionDownloadTask* XplatNSCFURLSessionDownloadTaskWithRequestCompletionHandler(id self, SEL _cmd, NSURLRequest* request, DownloadTaskCompletionBlock completionHandler)
    {
    NSString* logMessage = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];
    INTERCEPTOR_LOG(logMessage);
    
    NSURLSessionDownloadTask* sessionDownloadTask;
    NSMutableURLRequest* mutableRequest = [request mutableCopy];
    XplatURLBlackListManager* urlBlackListManager = [XplatURLBlackListManager sharedInstance];
    if (!mutableRequest.isXplatRequest &&
        ![urlBlackListManager containsURL:request.URL])
        {
    XplatNSURLSessionDownloadTaskManager* downloadTaskManager = [XplatNSURLSessionDownloadTaskManager sharedInstance];
    id downloadTaskIdentifier = [downloadTaskManager generateIdentifierForDownloadTask];
    
    if (completionHandler)
        {
        sessionDownloadTask = OriginalNSCFURLSessionDownloadTaskWithRequestCompletionHandler(self, _cmd, request, ^(NSURL* url, NSURLResponse* response, NSError* error)
            {
            XplatNSURLSessionDownloadTaskInfo* downloadTaskInfo = [downloadTaskManager downloadTaskInfoForIdentifier:downloadTaskIdentifier];
            [downloadTaskInfo.networkData appendEndTime];
            [downloadTaskInfo.networkData appendResponseInfo:response];
            [downloadTaskInfo.networkData appendWithError:error];

            XplatNetworkMonitorClient* monitoringClient = [XplatNetworkMonitorClient sharedInstance];
            [monitoringClient notifyObserverWithNetworkData:downloadTaskInfo.networkData];
            
            if (downloadTaskInfo.completionHandler)
                {
                downloadTaskInfo.completionHandler(url, response, error);
                }
                
            [downloadTaskManager removeDownloadTaskInfoForIdentifier:downloadTaskIdentifier];
            });
        }
    else
        {
        sessionDownloadTask = OriginalNSCFURLSessionDownloadTaskWithRequestCompletionHandler(self, _cmd, request, completionHandler);
        }
        
    XplatNSURLSessionDownloadTaskInfo* downloadTaskInfo = [XplatNSURLSessionDownloadTaskInfo new];
    NetworkModel* networkData = [NetworkModel new];
    [networkData appendRequestInfo:request];
    downloadTaskInfo.networkData = networkData;
    downloadTaskInfo.sessionDownloadTask = sessionDownloadTask;
    downloadTaskInfo.completionHandler = completionHandler;
    downloadTaskInfo.key = downloadTaskIdentifier;
    [downloadTaskManager registerDownloadTaskInfo:downloadTaskInfo withIdentifier:downloadTaskIdentifier];
    }
    else
        {
        sessionDownloadTask = OriginalNSCFURLSessionDownloadTaskWithRequestCompletionHandler(self, _cmd, request, completionHandler);
        }
    return sessionDownloadTask;
    }

static void XplatNSCFLocalDataTaskResume(id self, SEL _cmd)
    {
    NSString* logMessage = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];
    INTERCEPTOR_LOG(logMessage);
    
    XplatNSURLSessionDataTaskManager* dataTaskManager = [XplatNSURLSessionDataTaskManager sharedInstance];
    [dataTaskManager recordStartTimeForSessionDataTask:self];
    XplatNSURLSessionDownloadTaskManager* downloadTaskManager = [XplatNSURLSessionDownloadTaskManager sharedInstance];
    [downloadTaskManager recordStartTimeForSessionDownloadTask:self];
    
    OriginalNSCFLocalDataTaskResume(self, _cmd);
    }

static void XplatNSURLSessionTaskResume(id self, SEL _cmd)
    {
    NSString* logMessage = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];
    INTERCEPTOR_LOG(logMessage);
    
    XplatNSURLSessionDataTaskManager* dataTaskManager = [XplatNSURLSessionDataTaskManager sharedInstance];
    [dataTaskManager recordStartTimeForSessionDataTask:self];
    XplatNSURLSessionDownloadTaskManager* downloadTaskManager = [XplatNSURLSessionDownloadTaskManager sharedInstance];
    [downloadTaskManager recordStartTimeForSessionDownloadTask:self];
        
    OriginalNSURLSessionTaskResume(self, _cmd);
    }

@implementation NSURLSession (Xplat)

+ (void) startInjection
    {
    if (NSClassFromString(@"NSURLSession"))
        {
        // Create onceToken
        static dispatch_once_t onceToken;
        // Use dispatch_once to make sure this runs only once in the lifecycle
        dispatch_once(&onceToken,
            ^{
            INTERCEPTOR_LOG(@"Injecting code to NSURLSession");
            [self injectImplementationToNSURLSession];
            [self injectImplementationToNSCFURLSession];
            [self injectImplementationToNSCFLocalDataTask];
            [self injectImplementationToNSCFURLSessionDownloadTask];
            [self injectImplementationToNSCFURLSessionUploadTaskWithRequestFromDataCompletionHandler];
            [self injectImplementationToNSURLSessionTask];
            });
        }
    else
        {
        INTERCEPTOR_LOG(@"NSURLSession is not supported!");
        }
    }

#pragma mark - Injection methods to desired classes

+ (void) injectImplementationToNSURLSession
    {
    // Replace the method on the same class that's used
    // in the calling code
    Class class =  [NSURLSession class];
    
    // The Original NSURLSession selector
    SEL originalSelector = @selector(sessionWithConfiguration:delegate:delegateQueue:);
    
    // The Replacement method implementation
    IMP replacement = (IMP)XplatNSURLSessionWithConfigurationDelegateAndQueue;
    
    // This will eventually hold the original sessionWithConfiguration:delegate:delegateQueue:
    IMP* store = (IMP*)&OriginalNSURLSessionWithConfigurationDelegateAndQueue;
    
    IMP originalImp = NULL;
    Method method = class_getClassMethod(class, originalSelector);
    if (method)
        {
        const char* type = method_getTypeEncoding(method);
        // Replace the original method with the XplatNSURLSessionWithConfigurationDelegateAndQueue
        originalImp = class_replaceMethod(class, originalSelector, replacement, type);
        if (!originalImp)
            {
            originalImp = method_getImplementation(method);
            }
        }
    
    // Put the original method IMP into the pointer
    if (originalImp && store)
        {
        *store = originalImp;
        }
    }

+ (void) injectImplementationToNSCFURLSession
    {
    // Replace the method on the same class that's used
    // in the calling code
    Class class = [NSURLSession sharedSession].class; // It actually is the @"__NSCFURLSession"
    
    // The Original NSURLSession selector
    SEL originalSelector = @selector(dataTaskWithRequest:completionHandler:);
    
    // The Replacement method implementation
    IMP replacement = (IMP)XplatNSCFURLSessionDataTaskWithRequestCompletionHandler;
    
    // This will eventually hold the original resume
    IMP* store = (IMP*)&OriginalNSCFURLSessionDataTaskWithRequestCompletionHandler;
    
    IMP originalImp = NULL;
    Method method = class_getInstanceMethod(class, originalSelector);
    if (method)
        {
        const char* type = method_getTypeEncoding(method);
        // Replace the original method with the XplatNSCFURLSessionDataTaskWithRequestCompletionHandler
        originalImp = class_replaceMethod(class, originalSelector, replacement, type);
        if (!originalImp)
            {
            originalImp = method_getImplementation(method);
            }
        }
    
    // Put the original method IMP into the pointer
    if (originalImp && store)
        {
        *store = originalImp;
        }
    }

+ (void) injectImplementationToNSCFURLSessionDownloadTask
    {
    // Replace the method on the same class that's used
    // in the calling code
    Class class = [NSURLSession sharedSession].class; // It actually is the @"__NSCFURLSession"
    
    // The Original NSURLSession selector
    SEL originalSelector = @selector(downloadTaskWithRequest:completionHandler:);
    
    // The Replacement method implementation
    IMP replacement = (IMP)XplatNSCFURLSessionDownloadTaskWithRequestCompletionHandler;
    
    // This will eventually hold the original resume
    IMP* store = (IMP*)&OriginalNSCFURLSessionDownloadTaskWithRequestCompletionHandler;
    
    IMP originalImp = NULL;
    Method method = class_getInstanceMethod(class, originalSelector);
    if (method)
        {
        const char* type = method_getTypeEncoding(method);
        // Replace the original method with the XplatNSCFURLSessionDownloadTaskWithRequestCompletionHandler
        originalImp = class_replaceMethod(class, originalSelector, replacement, type);
        if (!originalImp)
            {
            originalImp = method_getImplementation(method);
            }
        }
    
    // Put the original method IMP into the pointer
    if (originalImp && store)
        {
        *store = originalImp;
        }
    }

+ (void) injectImplementationToNSCFURLSessionUploadTaskWithRequestFromDataCompletionHandler
    {
    // Replace the method on the same class that's used
    // in the calling code
    Class class = [NSURLSession sharedSession].class;
    
    // The Original NSURLSession selector
    SEL originalSelector = @selector(uploadTaskWithRequest:fromData:completionHandler:);
    
    // The Replacement method implementation
    IMP replacement = (IMP)XplatNSCFURLSessionUploadTaskWithRequestFromDataCompletionHandler;
    
    // This will eventually hold the original resume
    IMP* store = (IMP*)&OriginalNSCFURLSessionUploadTaskWithRequestFromDataCompletionHandler;
    
    IMP originalImp = NULL;
    Method method = class_getInstanceMethod(class, originalSelector);
    if (method)
        {
        const char* type = method_getTypeEncoding(method);
        // Replace the original method with the XplatNSCFURLSessionUploadTaskWithRequestFromDataCompletionHandler
        originalImp = class_replaceMethod(class, originalSelector, replacement, type);
        if (!originalImp)
            {
            originalImp = method_getImplementation(method);
            }
        }
    
    // Put the original method IMP into the pointer
    if (originalImp && store)
        {
        *store = originalImp;
        }
    }

+ (void) injectImplementationToNSCFLocalDataTask
    {
    // Replace the method on the same class that's used
    // in the calling code
    Class class = NSClassFromString(@"__NSCFLocalDataTask");
        
    // The Original NSURLSession selector
    SEL originalSelector = @selector(resume);
    
    // The Replacement method implementation
    IMP replacement = (IMP)XplatNSCFLocalDataTaskResume;
    
    // This will eventually hold the original resume
    IMP* store = (IMP*)&OriginalNSCFLocalDataTaskResume;
    
    IMP originalImp = NULL;
    Method method = class_getInstanceMethod(class, originalSelector);
    if (method)
        {
        const char* type = method_getTypeEncoding(method);
        // Replace the original method with the XplatNSCFLocalDataResume
        originalImp = class_replaceMethod(class, originalSelector, replacement, type);
        if (!originalImp)
            {
            originalImp = method_getImplementation(method);
            }
        }
    
    // Put the original method IMP into the pointer
    if (originalImp && store)
        {
        *store = originalImp;
        }
    }

+ (void) injectImplementationToNSURLSessionTask
    {
    // Replace the method on the same class that's used
    // in the calling code
    Class class = [NSURLSessionTask class];
    
    // The Original NSURLSession selector
    SEL originalSelector = @selector(resume);
    
    // The Replacement method implementation
    IMP replacement = (IMP)XplatNSURLSessionTaskResume;
    
    // This will eventually hold the original resume
    IMP* store = (IMP*)&OriginalNSURLSessionTaskResume;
    
    IMP originalImp = NULL;
    Method method = class_getInstanceMethod(class, originalSelector);
    if (method)
        {
        const char* type = method_getTypeEncoding(method);
        // Replace the original method with the XplatNSURLSessionTaskResume
        originalImp = class_replaceMethod(class, originalSelector, replacement, type);
        if (!originalImp)
            {
            originalImp = method_getImplementation(method);
            }
        }
    
    // Put the original method IMP into the pointer
    if (originalImp && store)
        {
        *store = originalImp;
        }
    }

@end
