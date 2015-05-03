//
//  NSURLConnection+Xplat.m
//  NetworkInterceptor
//
//  Created by George Taskos on 6/13/14.
//  Copyright (c) 2014 Xplat Solutions. All rights reserved.
//

#import <objc/runtime.h>

#import "NSURLConnection+Xplat.h"
#import "NetworkModel.h"
#import "XplatNSURLConnectionDataDelegateInterceptor.h"
#import "XplatNetworkMonitorClient.h"
#import "InterceptorLog.h"
#import "NSMutableURLRequest+Xplat.h"
#import "XplatURLBlackListManager.h"
#import "XPLLogging.h"

static void* KEY_CONNECTION_INTERCEPTOR;

typedef void (^SendAsynchronousCompletionHandlerBlock)(NSURLResponse*, NSData*, NSError*);

static void (*OriginalNSURLConnectionSendAsynchronousRequestQueueCompletionHandler)(id, SEL, NSURLRequest*, NSOperationQueue*, SendAsynchronousCompletionHandlerBlock);
static NSData* (*OriginalNSURLConnectionSendSynchronousRequestReturningResponseError)(id, SEL, NSURLRequest*, NSURLResponse**, NSError**);
static NSURLConnection* (*OriginalNSURLConnectionConnectionWithRequestDelegate)(id, SEL, NSURLRequest*, id);
static id (*OriginalNSURLConnectionInitWithRequestDelegateStartImmediately)(id, SEL, NSURLRequest*, id, BOOL);
static id (*OriginalNSURLConnectionInitWithRequestDelegate)(id, SEL, NSURLRequest*, id);
static void (*OriginalNSURLConnectionStart)(id, SEL);

static void XplatNSURLConnectionSendAsynchronousRequestQueueCompletionHandler(id self, SEL _cmd, NSURLRequest* request, NSOperationQueue* queue, SendAsynchronousCompletionHandlerBlock completionHandler)
    {
    NSString* logMessage = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];
    INTERCEPTOR_LOG(logMessage);
    
    if (OriginalNSURLConnectionSendAsynchronousRequestQueueCompletionHandler != NULL)
        {
        __block NSURLRequest* theRequest = [request copy];
        __block NetworkModel* networkData = [NetworkModel new];
        [networkData appendStartTime];
    
        return OriginalNSURLConnectionSendAsynchronousRequestQueueCompletionHandler(self, _cmd, request, queue, ^(NSURLResponse* response, NSData* data, NSError* error)
            {
            NSMutableURLRequest* mutableRequest = [theRequest mutableCopy];
            XplatURLBlackListManager* blackListManager = [XplatURLBlackListManager sharedInstance];
            
            if (!mutableRequest.isXplatRequest &&
                ![blackListManager containsURL:mutableRequest.URL])
                {
                INTERCEPTOR_LOG(@"Recording Data in SendAsynchronousRequestQueueCompletionHandler");
                [networkData appendEndTime];
                [networkData appendRequestInfo:theRequest];
        
                if (response)
                    {
                    NSURLResponse* theResponse = [response copy];
                    [networkData appendResponseInfo:theResponse];
                    }
            
                NSData* responseData = [data copy];
                [networkData appendResponseData:responseData];
                NSError* reportingError = [error copy];
                if (responseData == nil)
                    {
                    @try
                        {
                        if (reportingError)
                            {
                            [networkData appendWithError:reportingError];
                            }
                        }
                    @catch (NSException *exception)
                        {
                        XPLLogError(@"Unable to capture networking error async: %@", exception.reason);
                        }
                    }
            
                [[XplatNetworkMonitorClient sharedInstance] notifyObserverWithNetworkData:networkData];
                }
            else
                {
                networkData = nil;
                theRequest = nil;
                }
                
            if (completionHandler)
                {
                completionHandler(response, data, error);
                }
            });
        }
    }

static NSData* XplatNSURLConnectionSendSynchronousRequestReturningResponseError(id self, SEL _cmd, NSURLRequest* request, NSURLResponse** response, NSError** error)
    {
    NSString* logMessage = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];
    INTERCEPTOR_LOG(logMessage);
    
    if (OriginalNSURLConnectionSendSynchronousRequestReturningResponseError != NULL)
        {
        NetworkModel* networkData = [NetworkModel new];
        [networkData appendStartTime];
        
        NSData* responseData;
        NSError* reportingError;
        
        if (error)
            {
            responseData = OriginalNSURLConnectionSendSynchronousRequestReturningResponseError(self, _cmd, request, response, error);
            }
        else
            {
            responseData = OriginalNSURLConnectionSendSynchronousRequestReturningResponseError(self, _cmd, request, response, &reportingError);
            }
            
        NSMutableURLRequest* mutableRequest = [request mutableCopy];
        XplatURLBlackListManager* blackListManager = [XplatURLBlackListManager sharedInstance];
        
        if (!mutableRequest.isXplatRequest &&
            ![blackListManager containsURL:mutableRequest.URL])
            {
            INTERCEPTOR_LOG(@"Recording Data in SendSynchronousRequestReturningResponseError");
            [networkData appendEndTime];
            [networkData appendRequestInfo:request];
        
            if (response && *response)
                {
                NSURLResponse* theResponse = *response;
                [networkData appendResponseInfo:theResponse];
                }
            [networkData appendResponseData:responseData];
        
            if (responseData == nil)
                {
                @try
                    {
                    if (error && *error)
                        {
                        NSError* theError = *error;
                        [networkData appendWithError:theError];
                        }
                    else if (reportingError != nil)
                        {
                        [networkData appendWithError:reportingError];
                        }
                    }
                @catch (NSException *exception)
                    {
                    XPLLogError(@"Unable to capture networking error: %@", exception.reason);
                    }
                }
            [[XplatNetworkMonitorClient sharedInstance] notifyObserverWithNetworkData:networkData];
            }
        else
            {
            networkData = nil;
            }
        return responseData;
        }
    else
        {
        return nil;
        }
    }

static XplatNSURLConnectionDataDelegateInterceptor* GetConnectionInterceptor(NSURLConnection* connection)
    {
    return (XplatNSURLConnectionDataDelegateInterceptor*)
        objc_getAssociatedObject(connection, &KEY_CONNECTION_INTERCEPTOR);
    }

static void AttachConnectionInterceptor(NSURLConnection* connection, XplatNSURLConnectionDataDelegateInterceptor* interceptor)
    {
    objc_setAssociatedObject(connection,
                             &KEY_CONNECTION_INTERCEPTOR,
                             interceptor,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

static NSURLConnection* XplatNSURLConnectionConnectionWithRequestDelegate(id self, SEL _cmd, NSURLRequest* request, id delegate)
    {
    NSString* logMessage = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];
    INTERCEPTOR_LOG(logMessage);
    
    if (OriginalNSURLConnectionConnectionWithRequestDelegate != NULL)
        {
        NSMutableURLRequest* mutableRequest = [request mutableCopy];
        XplatURLBlackListManager* blackListManager = [XplatURLBlackListManager sharedInstance];
        
        if (!mutableRequest.isXplatRequest &&
            ![blackListManager containsURL:mutableRequest.URL])
            {
            INTERCEPTOR_LOG(@"Recording Data in ConnectionWithRequestDelegate");
            XplatNSURLConnectionDataDelegateInterceptor *interceptor = [[XplatNSURLConnectionDataDelegateInterceptor alloc] initAndInterceptFor:delegate withRequest:request];
        
            NSURLConnection* connection = (NSURLConnection*) self;
            AttachConnectionInterceptor(connection, interceptor);
        
            return OriginalNSURLConnectionConnectionWithRequestDelegate(self, _cmd, request, interceptor);
            }
        else
            {
            return OriginalNSURLConnectionConnectionWithRequestDelegate(self, _cmd, request, delegate);
            }
        }
    else
        {
        return nil;
        }
    }

static id XplatNSURLConnectionInitWithRequestDelegateStartImmediately(id self, SEL _cmd, NSURLRequest* request, id delegate, BOOL startImmediately)
    {
    NSString* logMessage = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];
    INTERCEPTOR_LOG(logMessage);
    
    if (OriginalNSURLConnectionInitWithRequestDelegateStartImmediately != NULL)
        {
        NSMutableURLRequest* mutableRequest = [request mutableCopy];
        XplatURLBlackListManager* blackListManager = [XplatURLBlackListManager sharedInstance];
        
        if (!mutableRequest.isXplatRequest &&
            ![blackListManager containsURL:mutableRequest.URL])
            {
            INTERCEPTOR_LOG(@"Recording Data in InitWithRequestDelegateStartImmediately");
            XplatNSURLConnectionDataDelegateInterceptor* interceptor = [[XplatNSURLConnectionDataDelegateInterceptor alloc] initAndInterceptFor:delegate withRequest:mutableRequest];
            
            NSURLConnection* theConnection = (NSURLConnection*) self;
            AttachConnectionInterceptor(theConnection, interceptor);
            
            return OriginalNSURLConnectionInitWithRequestDelegateStartImmediately(self, _cmd, mutableRequest, interceptor, startImmediately);
            }
        else
            {
            return OriginalNSURLConnectionInitWithRequestDelegateStartImmediately(self, _cmd, request, delegate, startImmediately);
            }
        }
    else
        {
        return nil;
        }
    }

static id XplatNSURLConnectionInitWithRequestDelegate(id self, SEL _cmd, NSURLRequest* request, id delegate)
    {
    NSString* logMessage = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];
    INTERCEPTOR_LOG(logMessage);
    
    if (OriginalNSURLConnectionInitWithRequestDelegate != NULL)
        {
//        id connection;
        NSMutableURLRequest* mutableRequest = [request mutableCopy];
        XplatURLBlackListManager* blackListManager = [XplatURLBlackListManager sharedInstance];
        
        if (!mutableRequest.isXplatRequest &&
            ![blackListManager containsURL:request.URL])
            {
            INTERCEPTOR_LOG(@"Recording Data in InitWithRequestDelegate");
            XplatNSURLConnectionDataDelegateInterceptor* interceptor = [[XplatNSURLConnectionDataDelegateInterceptor alloc] initAndInterceptFor:delegate withRequest:request];
            
            NSURLConnection* connection = (NSURLConnection*) self;
            AttachConnectionInterceptor(connection, interceptor);
            
            return OriginalNSURLConnectionInitWithRequestDelegate(self, _cmd, mutableRequest, interceptor);
            }
        else
            {
            return OriginalNSURLConnectionInitWithRequestDelegate(self, _cmd, request, delegate);
            }
        }
    else
        {
        return nil;
        }
    }

static void XplatNSURLConnectionStart(id self, SEL _cmd)
    {
    NSString* logMessage = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];
    INTERCEPTOR_LOG(logMessage);
    
    NSURLConnection* connection = (NSURLConnection*)self;
    XplatNSURLConnectionDataDelegateInterceptor* interceptor = GetConnectionInterceptor(connection);
    if (interceptor)
        {
        [interceptor recordStartTime];
        }
        
    if (OriginalNSURLConnectionStart != NULL)
        {
        OriginalNSURLConnectionStart(self, _cmd);
        }
    }

@implementation NSURLConnection (Xplat)

+ (void) startInjection
    {
    // Create onceToken
    static dispatch_once_t onceToken;
    // Use dispatch_once to make sure this runs only once in the lifecycle
    dispatch_once(&onceToken,
        ^{
        INTERCEPTOR_LOG(@"Injecting code to NSURLConnection");
        [self injectImplementationToNSURLConnectionSendAsynchronousRequestQueueCompletionHandler];
        [self injectImplementationToNSURLConnectionSendSynchronousRequestReturningResponseError];
        [self injectImplementationToNSURLConnectionConnectionWithRequestDelegate];
        [self injectImplementationToNSURLConnectionInitWithRequestDelegateStartImmediately];
        [self injectImplementationToNSURLConnectionInitWithRequestDelegate];
        [self injectImplementationToNSURLConnectionStart];
        });
    }

+ (void) injectImplementationToNSURLConnectionSendAsynchronousRequestQueueCompletionHandler
    {
    // NSURLConnection  + (void)sendAsynchronousRequest:queue:completionHandler:
    Class c = [NSURLConnection class];
    SEL selMethod = @selector(sendAsynchronousRequest:queue:completionHandler:);
    IMP impOverrideMethod = (IMP) XplatNSURLConnectionSendAsynchronousRequestQueueCompletionHandler;
    Method origMethod = class_getClassMethod(c,selMethod);
    OriginalNSURLConnectionSendAsynchronousRequestQueueCompletionHandler = (void *)method_getImplementation(origMethod);

    if( OriginalNSURLConnectionSendAsynchronousRequestQueueCompletionHandler != NULL )
        {
        method_setImplementation(origMethod, impOverrideMethod);
        }
    else
        {
        XPLLogError(@"error: unable to swizzle + (void)sendAsynchronousRequest:queue:completionHandler:");
        }
    }

+ (void) injectImplementationToNSURLConnectionSendSynchronousRequestReturningResponseError
    {
    // NSURLConnection  + (NSData*) sendSynchronousRequest:returningResponse:error:
    Class c = [NSURLConnection class];
    SEL selMethod = @selector(sendSynchronousRequest:returningResponse:error:);
    IMP impOverrideMethod = (IMP) XplatNSURLConnectionSendSynchronousRequestReturningResponseError;
    Method origMethod = class_getClassMethod(c, selMethod);
    OriginalNSURLConnectionSendSynchronousRequestReturningResponseError = (void *)method_getImplementation(origMethod);

    if( OriginalNSURLConnectionSendSynchronousRequestReturningResponseError != NULL )
        {
        method_setImplementation(origMethod, impOverrideMethod);
        }
    else
        {
        XPLLogError(@"error: unable to swizzle + sendSynchronousRequest:returningResponse:error:");
        }
    }

+ (void) injectImplementationToNSURLConnectionConnectionWithRequestDelegate
    {
    // Replace the method on the same class that's used
    // in the calling code
    Class class =  [NSURLConnection class];
    
    // The Original +connectionWithRequest:delegate: selector
    SEL originalSelector = @selector(connectionWithRequest:delegate:);
    
    // The Replacement method implementation
    IMP replacement = (IMP)XplatNSURLConnectionConnectionWithRequestDelegate;
    
    // This will eventually hold the original connectionWithRequest:delegate:
    IMP* store = (IMP*)&OriginalNSURLConnectionConnectionWithRequestDelegate;
    
    IMP originalImp = NULL;
    Method method = class_getClassMethod(class, originalSelector);
    if (method)
        {
        const char* type = method_getTypeEncoding(method);
        // Replace the original method with the XplatNSURLConnectionConnectionWithRequestDelegate
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

+ (void) injectImplementationToNSURLConnectionInitWithRequestDelegateStartImmediately
    {
    // Replace the method on the same class that's used
    // in the calling code
    Class class =  [NSURLConnection class];
    
    // The Original -initWithRequest:delegate:startImmediately:
    SEL originalSelector = @selector(initWithRequest:delegate:startImmediately:);
    
    // The Replacement method implementation
    IMP replacement = (IMP)XplatNSURLConnectionInitWithRequestDelegateStartImmediately;
    
    // This will eventually hold the original initWithRequest:delegate:startImmediately:
    IMP* store = (IMP*)&OriginalNSURLConnectionInitWithRequestDelegateStartImmediately;
    
    IMP originalImp = NULL;
    Method method = class_getInstanceMethod(class, originalSelector);
    if (method)
        {
        const char* type = method_getTypeEncoding(method);
        // Replace the original method with the XplatNSURLConnectionInitWithRequestDelegateStartImmediately
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

+ (void) injectImplementationToNSURLConnectionInitWithRequestDelegate
    {
    // Replace the method on the same class that's used
    // in the calling code
    Class class =  [NSURLConnection class];
    
    // The Original -initWithRequest:delegate:
    SEL originalSelector = @selector(initWithRequest:delegate:);
    
    // The Replacement method implementation
    IMP replacement = (IMP)XplatNSURLConnectionInitWithRequestDelegate;
    
    // This will eventually hold the original initWithRequest:delegate:
    IMP* store = (IMP*)&OriginalNSURLConnectionInitWithRequestDelegate;
    
    IMP originalImp = NULL;
    Method method = class_getInstanceMethod(class, originalSelector);
    if (method)
        {
        const char* type = method_getTypeEncoding(method);
        // Replace the original method with the XplatNSURLConnectionInitWithRequestDelegate
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

+ (void) injectImplementationToNSURLConnectionStart
    {
    // Replace the method on the same class that's used
    // in the calling code
    Class class =  [NSURLConnection class];
    
    // The Original -start
    SEL originalSelector = @selector(start);
    
    // The Replacement start method implementation
    IMP replacement = (IMP)XplatNSURLConnectionStart;
    
    // This will eventually hold the original start
    IMP* store = (IMP*)&OriginalNSURLConnectionStart;
    
    IMP originalImp = NULL;
    Method method = class_getInstanceMethod(class, originalSelector);
    if (method)
        {
        const char* type = method_getTypeEncoding(method);
        // Replace the original method with the XplatNSURLConnectionStart
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