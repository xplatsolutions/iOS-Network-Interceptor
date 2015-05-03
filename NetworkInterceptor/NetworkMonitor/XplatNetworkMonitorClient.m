//
//  XplatNetworkMonitorClient.m
//  NetworkInterceptor
//
//  Created by George Taskos on 6/13/14.
//  Copyright (c) 2014 Xplat Solutions. All rights reserved.
//

#import "XplatNetworkMonitorClient.h"
#import "NSURLConnection+Xplat.h"
#import "NSURLSession+Xplat.h"
#import "InterceptorLog.h"
#import "XPLLogging.h"

@interface XplatNetworkMonitorClient ()

@end

@implementation XplatNetworkMonitorClient

NSString* const kXPLNetworkMonitorNotification = @"com.xplatsolutions.NetworkMonitorClient";
NSString* const kXPLNetworkMonitorDataKey = @"com.xplatsolutions.kXPLNetworkMonitorDataKey";

#pragma mark - 
#pragma mark Singleton

+ (instancetype) sharedInstance
    {
    static id _sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken,
        ^{
        _sharedInstance = [[self alloc] init];
        });
    return _sharedInstance;
    }

#pragma mark -
#pragma mark Static Methods

- (void) startMonitoring
    {
    @synchronized (self)
        {
        [NSURLConnection startInjection];
        [NSURLSession startInjection];
        }
    }

#pragma mark -
#pragma mark Public Methods

- (void) notifyObserverWithNetworkData:(NetworkModel*)networkData
    {
    NSString* logMessage = [NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__];
    INTERCEPTOR_LOG(logMessage);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kXPLNetworkMonitorNotification object:self userInfo:
        @{
            kXPLNetworkMonitorDataKey: networkData
        }];
    }

@end
